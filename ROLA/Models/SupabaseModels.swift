import Foundation

// MARK: - Supabase Configuration

struct SupabaseConfig: Codable, Hashable, Sendable {
    var projectURL: String
    var anonKey: String

    var isConfigured: Bool {
        !projectURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static let storageKey = "com.rola.app.supabase-config"
}

// MARK: - Supabase Session

struct SupabaseSession: Codable, Hashable, Sendable {
    let accessToken: String
    let refreshToken: String
    let userId: UUID
    let expiresAt: Date

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

// MARK: - Remote Style Profile

struct RemoteStyleProfile: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let scope: String
    let contactHash: String?
    let traits: StyleTraits
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case scope
        case contactHash = "contact_hash"
        case traits
        case updatedAt = "updated_at"
    }
}

// MARK: - Remote Feedback Event

struct RemoteFeedbackEvent: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let suggestionId: UUID
    let contactHash: String
    let originalText: String
    let finalText: String
    let action: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case suggestionId = "suggestion_id"
        case contactHash = "contact_hash"
        case originalText = "original_text"
        case finalText = "final_text"
        case action
        case createdAt = "created_at"
    }
}

// MARK: - Sync Status

enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case success(Date)
    case failed(String)

    var label: String {
        switch self {
        case .idle: "Not synced"
        case .syncing: "Syncing…"
        case .success(let date):
            "Synced \(date.formatted(date: .abbreviated, time: .shortened))"
        case .failed(let message): "Sync failed: \(message)"
        }
    }
}
