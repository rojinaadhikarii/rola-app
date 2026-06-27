import Foundation

// MARK: - Message Import Service

struct MessageImportService: MessageImportServiceProtocol {

    private let reader: ChatDBReader

    init(reader: ChatDBReader = ChatDBReader()) {
        self.reader = reader
    }

    func importConversations(onProgress: (@Sendable (Double) -> Void)?) async throws -> [Conversation] {
        guard FullDiskAccessChecker.isGranted else {
            throw MessageImportError.fullDiskAccessRequired
        }

        return try await Task.detached { [reader] in
            onProgress?(0.1)

            let rows = try reader.fetchConversations(limit: 500)
            onProgress?(0.7)

            let conversations = rows
                .map(Conversation.init(row:))
                .filter { $0.lastMessageText != nil || $0.lastMessageDate != nil }

            onProgress?(1.0)
            return conversations
        }.value
    }

    func fetchRecentMessages(chatId: Int64, limit: Int) async throws -> [ImportedMessage] {
        guard FullDiskAccessChecker.isGranted else {
            throw MessageImportError.fullDiskAccessRequired
        }

        return try await Task.detached { [reader] in
            try reader.fetchRecentMessages(chatId: chatId, limit: limit)
                .map(ImportedMessage.init(row:))
                .filter { !$0.text.isEmpty }
        }.value
    }
}
