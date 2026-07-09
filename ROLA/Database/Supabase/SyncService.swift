import Foundation

// MARK: - Sync Service Protocol

protocol SyncServiceProtocol: Sendable {
    var isConfigured: Bool { get }
    var isAuthenticated: Bool { get }
    func syncIfNeeded() async
    func pullRemoteProfiles() async throws
}

// MARK: - Sync Service

@MainActor
@Observable
final class SyncService: SyncServiceProtocol {
    private let client: SupabaseClient
    private let authService: SupabaseAuthService
    private let configStore: SupabaseConfigStoreProtocol
    private let sessionStore: SupabaseSessionStoreProtocol
    private let feedbackStore: FeedbackStore
    private let styleProfileStore: StyleProfileStore

    private(set) var status: SyncStatus = .idle
    private(set) var lastSyncedAt: Date?

    init(
        client: SupabaseClient = SupabaseClient(),
        authService: SupabaseAuthService? = nil,
        configStore: SupabaseConfigStoreProtocol = SupabaseConfigStore(),
        sessionStore: SupabaseSessionStoreProtocol = SupabaseSessionStore(),
        feedbackStore: FeedbackStore,
        styleProfileStore: StyleProfileStore
    ) {
        self.client = client
        self.configStore = configStore
        self.sessionStore = sessionStore
        self.feedbackStore = feedbackStore
        self.styleProfileStore = styleProfileStore
        self.authService = authService ?? SupabaseAuthService(
            client: client,
            configStore: configStore,
            sessionStore: sessionStore
        )
    }

    nonisolated var isConfigured: Bool {
        configStore.isConfigured
    }

    nonisolated var isAuthenticated: Bool {
        sessionStore.isAuthenticated
    }

    nonisolated func syncIfNeeded() async {
        await performSync()
    }

    nonisolated func pullRemoteProfiles() async throws {
        try await performPull()
    }

    // MARK: - Auth passthrough

    func signIn(email: String, password: String) async throws {
        try await authService.signIn(email: email, password: password)
        await performSync()
    }

    func signUp(email: String, password: String) async throws {
        try await authService.signUp(email: email, password: password)
        await performSync()
    }

    func signOut() {
        authService.signOut()
        status = .idle
    }

    func saveConfig(_ config: SupabaseConfig) {
        configStore.saveConfig(config)
    }

    func loadConfig() -> SupabaseConfig? {
        configStore.loadConfig()
    }

    var pendingFeedbackCount: Int {
        feedbackStore.pendingSyncCount
    }

    // MARK: - Private

    private func performSync() async {
        guard let config = configStore.loadConfig(), config.isConfigured,
              let session = sessionStore.loadSession() else {
            return
        }

        status = .syncing

        do {
            try await pushLocalProfiles(config: config, session: session)
            try await pushPendingFeedback(config: config, session: session)
            status = .success(Date())
            lastSyncedAt = Date()
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private func performPull() async throws {
        guard let config = configStore.loadConfig(), config.isConfigured,
              let session = sessionStore.loadSession() else {
            throw SupabaseError.notAuthenticated
        }

        let remoteProfiles = try await client.fetchStyleProfiles(
            userId: session.userId,
            config: config,
            session: session
        )
        styleProfileStore.mergeRemoteProfiles(remoteProfiles)
        lastSyncedAt = Date()
        status = .success(Date())
    }

    private func pushLocalProfiles(config: SupabaseConfig, session: SupabaseSession) async throws {
        guard let result = styleProfileStore.analysisResult else { return }

        let global = RemoteStyleProfile(
            id: UUID(),
            userId: session.userId,
            scope: "global",
            contactHash: nil,
            traits: result.globalProfile.traits,
            updatedAt: result.globalProfile.analyzedAt
        )
        try await client.upsertStyleProfile(global, config: config, session: session)

        for profile in result.contactProfiles {
            guard let chatId = profile.chatId else { continue }
            let remote = RemoteStyleProfile(
                id: UUID(),
                userId: session.userId,
                scope: "contact",
                contactHash: ContactHasher.hash(chatId: chatId),
                traits: profile.traits,
                updatedAt: profile.analyzedAt
            )
            try await client.upsertStyleProfile(remote, config: config, session: session)
        }
    }

    private func pushPendingFeedback(config: SupabaseConfig, session: SupabaseSession) async throws {
        for stored in feedbackStore.pendingSync {
            let event = RemoteFeedbackEvent(
                id: stored.feedback.id,
                userId: session.userId,
                suggestionId: stored.feedback.suggestionId,
                contactHash: ContactHasher.hash(chatId: stored.feedback.chatId),
                originalText: stored.feedback.originalText,
                finalText: stored.feedback.finalText,
                action: stored.feedback.action.rawValue,
                createdAt: stored.feedback.createdAt
            )
            try await client.insertFeedbackEvent(event, config: config, session: session)
            feedbackStore.markSynced(stored.feedback.id)
        }
    }
}

// MARK: - Mock Sync Service

struct MockSyncService: SyncServiceProtocol {
    var isConfigured: Bool { false }
    var isAuthenticated: Bool { false }

    func syncIfNeeded() async {}
    func pullRemoteProfiles() async throws {}
}
