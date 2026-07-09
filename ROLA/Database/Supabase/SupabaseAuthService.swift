import Foundation

// MARK: - Supabase Config Store Protocol

protocol SupabaseConfigStoreProtocol: Sendable {
    func loadConfig() -> SupabaseConfig?
    func saveConfig(_ config: SupabaseConfig)
    func clearConfig()
    var isConfigured: Bool { get }
}

// MARK: - Supabase Session Store Protocol

protocol SupabaseSessionStoreProtocol: Sendable {
    func loadSession() -> SupabaseSession?
    func saveSession(_ session: SupabaseSession) throws
    func clearSession()
    var isAuthenticated: Bool { get }
}

// MARK: - UserDefaults Config Store

struct SupabaseConfigStore: SupabaseConfigStoreProtocol {
    func loadConfig() -> SupabaseConfig? {
        guard let data = UserDefaults.standard.data(forKey: SupabaseConfig.storageKey),
              let config = try? JSONDecoder().decode(SupabaseConfig.self, from: data) else {
            return nil
        }
        return config
    }

    func saveConfig(_ config: SupabaseConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: SupabaseConfig.storageKey)
    }

    func clearConfig() {
        UserDefaults.standard.removeObject(forKey: SupabaseConfig.storageKey)
    }

    var isConfigured: Bool {
        loadConfig()?.isConfigured == true
    }
}

// MARK: - Keychain Session Store

struct SupabaseSessionStore: SupabaseSessionStoreProtocol {
    private static let sessionKey = "com.rola.app.supabase-session"

    func loadSession() -> SupabaseSession? {
        guard let data = KeychainHelper.loadData(for: .supabaseSession),
              let session = try? JSONDecoder().decode(SupabaseSession.self, from: data) else {
            return nil
        }
        return session.isExpired ? nil : session
    }

    func saveSession(_ session: SupabaseSession) throws {
        let data = try JSONEncoder().encode(session)
        try KeychainHelper.saveData(data, for: .supabaseSession)
    }

    func clearSession() {
        KeychainHelper.delete(for: .supabaseSession)
    }

    var isAuthenticated: Bool {
        loadSession() != nil
    }
}

// MARK: - Supabase Auth Service

struct SupabaseAuthService: Sendable {
    let client: SupabaseClient
    let configStore: SupabaseConfigStoreProtocol
    let sessionStore: SupabaseSessionStoreProtocol

    init(
        client: SupabaseClient = SupabaseClient(),
        configStore: SupabaseConfigStoreProtocol = SupabaseConfigStore(),
        sessionStore: SupabaseSessionStoreProtocol = SupabaseSessionStore()
    ) {
        self.client = client
        self.configStore = configStore
        self.sessionStore = sessionStore
    }

    var isConfigured: Bool { configStore.isConfigured }
    var isAuthenticated: Bool { sessionStore.isAuthenticated }

    func signIn(email: String, password: String) async throws {
        guard let config = configStore.loadConfig() else {
            throw SupabaseError.notConfigured
        }
        let session = try await client.signIn(email: email, password: password, config: config)
        try sessionStore.saveSession(session)
    }

    func signUp(email: String, password: String) async throws {
        guard let config = configStore.loadConfig() else {
            throw SupabaseError.notConfigured
        }
        let session = try await client.signUp(email: email, password: password, config: config)
        try sessionStore.saveSession(session)
    }

    func signOut() {
        sessionStore.clearSession()
    }

    func currentSession() -> SupabaseSession? {
        sessionStore.loadSession()
    }
}
