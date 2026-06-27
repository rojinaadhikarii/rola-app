import Foundation

// MARK: - Supabase Error

enum SupabaseError: LocalizedError, Sendable {
    case notConfigured
    case notAuthenticated
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Supabase is not configured. Add your project URL and anon key in Settings."
        case .notAuthenticated:
            "Sign in to Supabase to sync your profiles."
        case .invalidResponse:
            "Received an invalid response from Supabase."
        case .apiError(let statusCode, let message):
            "Supabase error (\(statusCode)): \(message)"
        case .decodingFailed:
            "Could not parse the Supabase response."
        }
    }
}

// MARK: - Supabase Client

/// Lightweight PostgREST + Auth client using URLSession (no SDK dependency).
struct SupabaseClient: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Auth

    func signIn(
        email: String,
        password: String,
        config: SupabaseConfig
    ) async throws -> SupabaseSession {
        let url = try authURL(config: config, path: "token?grant_type=password")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await perform(request)
        return try decodeSession(from: data)
    }

    func signUp(
        email: String,
        password: String,
        config: SupabaseConfig
    ) async throws -> SupabaseSession {
        let url = try authURL(config: config, path: "signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await perform(request)
        return try decodeSession(from: data)
    }

    // MARK: - Sync

    func upsertStyleProfile(
        _ profile: RemoteStyleProfile,
        config: SupabaseConfig,
        session: SupabaseSession
    ) async throws {
        var components = URLComponents(
            url: try restURL(config: config, table: "style_profiles"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "on_conflict", value: "user_id,scope,contact_hash"),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        applyHeaders(&request, config: config, session: session)
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(profile)

        _ = try await perform(request)
    }

    func insertFeedbackEvent(
        _ event: RemoteFeedbackEvent,
        config: SupabaseConfig,
        session: SupabaseSession
    ) async throws {
        let url = try restURL(config: config, table: "feedback_events")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request, config: config, session: session)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(event)

        _ = try await perform(request)
    }

    func fetchStyleProfiles(
        userId: UUID,
        config: SupabaseConfig,
        session: SupabaseSession
    ) async throws -> [RemoteStyleProfile] {
        let base = try restURL(config: config, table: "style_profiles")
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "updated_at.desc"),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        applyHeaders(&request, config: config, session: session)

        let data = try await perform(request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([RemoteStyleProfile].self, from: data)
    }

    // MARK: - Private

    private func authURL(config: SupabaseConfig, path: String) throws -> URL {
        guard let base = normalizedProjectURL(config.projectURL) else {
            throw SupabaseError.notConfigured
        }
        return base.appendingPathComponent("auth/v1/\(path)")
    }

    private func restURL(config: SupabaseConfig, table: String) throws -> URL {
        guard let base = normalizedProjectURL(config.projectURL) else {
            throw SupabaseError.notConfigured
        }
        return base.appendingPathComponent("rest/v1/\(table)")
    }

    private func normalizedProjectURL(_ raw: String) -> URL? {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return URL(string: trimmed)
    }

    private func applyHeaders(
        _ request: inout URLRequest,
        config: SupabaseConfig,
        session: SupabaseSession
    ) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.apiError(statusCode: http.statusCode, message: message)
        }
        return data
    }

    private func decodeSession(from data: Data) throws -> SupabaseSession {
        struct AuthResponse: Decodable {
            let accessToken: String
            let refreshToken: String
            let expiresIn: Int
            let user: AuthUser

            struct AuthUser: Decodable {
                let id: UUID
            }

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case expiresIn = "expires_in"
                case user
            }
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(AuthResponse.self, from: data)
        let expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))

        return SupabaseSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userId: response.user.id,
            expiresAt: expiresAt
        )
    }
}
