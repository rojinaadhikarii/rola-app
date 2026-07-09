import Foundation

// MARK: - Conversation Cache

private struct ConversationCache: Codable {
    let importedAt: Date
    let conversations: [Conversation]
}

// MARK: - Conversation Store

/// In-memory conversation store with lightweight disk cache.
@MainActor
@Observable
final class ConversationStore {

    private(set) var conversations: [Conversation] = []
    private(set) var selectedConversation: Conversation?
    private(set) var selectedMessages: [ImportedMessage] = []
    private(set) var lastImportDate: Date?
    private(set) var importError: String?

    var isLoadingMessages = false
    var isImporting = false

    private let importService: MessageImportServiceProtocol
    private let cacheURL: URL

    init(importService: MessageImportServiceProtocol) {
        self.importService = importService
        self.cacheURL = Self.makeCacheURL()
        loadFromCache()
    }

    var needsAttention: [Conversation] {
        conversations.filter(\.needsReply)
    }

    var inboxCount: Int {
        needsAttention.count
    }

    func importConversations(onProgress: (@Sendable (Double) -> Void)? = nil) async {
        isImporting = true
        importError = nil
        defer { isImporting = false }

        do {
            let imported = try await importService.importConversations(onProgress: onProgress)
            conversations = imported.sorted { ($0.lastMessageDate ?? .distantPast) > ($1.lastMessageDate ?? .distantPast) }
            lastImportDate = Date()
            saveToCache()

            if let selected = selectedConversation,
               let updated = conversations.first(where: { $0.id == selected.id }) {
                await selectConversation(updated)
            }
        } catch {
            importError = error.localizedDescription
        }
    }

    func selectConversation(_ conversation: Conversation?) async {
        selectedConversation = conversation
        selectedMessages = []

        guard let conversation else { return }

        isLoadingMessages = true
        defer { isLoadingMessages = false }

        do {
            selectedMessages = try await importService.fetchRecentMessages(
                chatId: conversation.id,
                limit: 40
            )
        } catch {
            importError = error.localizedDescription
        }
    }

    func refresh() async {
        await importConversations()
    }

    // MARK: - Cache

    private func loadFromCache() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return }

        do {
            let data = try Data(contentsOf: cacheURL)
            let cache = try JSONDecoder().decode(ConversationCache.self, from: data)
            conversations = cache.conversations
            lastImportDate = cache.importedAt
        } catch {
            importError = "Could not load cached conversations."
        }
    }

    private func saveToCache() {
        let cache = ConversationCache(importedAt: lastImportDate ?? Date(), conversations: conversations)
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            importError = "Could not save conversation cache."
        }
    }

    private static func makeCacheURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let directory = appSupport.appendingPathComponent("com.rola.app", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("conversations.json")
    }
}
