import Foundation

// MARK: - Mock Services (Milestone 1)

struct MockMessageImportService: MessageImportServiceProtocol {
    func importConversations(onProgress: (@Sendable (Double) -> Void)?) async throws -> [Conversation] {
        onProgress?(0.5)
        try await Task.sleep(for: .milliseconds(300))
        onProgress?(1.0)
        return MockConversationData.sample
    }

    func fetchRecentMessages(chatId: Int64, limit: Int) async throws -> [ImportedMessage] {
        MockConversationData.messages(for: chatId)
    }
}

enum MockConversationData {
    static let sample: [Conversation] = [
        Conversation(
            id: 1,
            guid: "mock-1",
            displayName: "Alex Kim",
            participantHandles: ["+15551234567"],
            serviceName: "iMessage",
            isGroup: false,
            lastMessageText: "Are you free Thursday?",
            lastMessageDate: Date().addingTimeInterval(-3600),
            lastMessageIsFromMe: false,
            needsReply: true
        ),
        Conversation(
            id: 2,
            guid: "mock-2",
            displayName: "Mom",
            participantHandles: ["+15559876543"],
            serviceName: "iMessage",
            isGroup: false,
            lastMessageText: "Did you make it home?",
            lastMessageDate: Date().addingTimeInterval(-7200),
            lastMessageIsFromMe: false,
            needsReply: true
        ),
        Conversation(
            id: 3,
            guid: "mock-3",
            displayName: "Work Team",
            participantHandles: ["+15551112222", "+15553334444"],
            serviceName: "iMessage",
            isGroup: true,
            lastMessageText: "Sounds good, thanks!",
            lastMessageDate: Date().addingTimeInterval(-86400),
            lastMessageIsFromMe: true,
            needsReply: false
        ),
    ]

    static func messages(for chatId: Int64) -> [ImportedMessage] {
        switch chatId {
        case 1:
            return [
                ImportedMessage(
                    id: 101, chatId: 1, text: "Hey! Long time no see",
                    date: Date().addingTimeInterval(-7200), isFromMe: false, handleIdentifier: "+15551234567"
                ),
                ImportedMessage(
                    id: 102, chatId: 1, text: "I know, it's been crazy!",
                    date: Date().addingTimeInterval(-5400), isFromMe: true, handleIdentifier: nil
                ),
                ImportedMessage(
                    id: 103, chatId: 1, text: "Are you free Thursday?",
                    date: Date().addingTimeInterval(-3600), isFromMe: false, handleIdentifier: "+15551234567"
                ),
            ]
        default:
            return []
        }
    }
}

struct MockStyleEngine: StyleEngineProtocol {
    func analyzeStyle() async throws {}
}

struct MockAIPipeline: AIPipelineProtocol {
    func generateSuggestion(for messageID: String) async throws -> String {
        "Sounds good!"
    }
}

@MainActor
final class MockCalendarService: CalendarServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
}

@MainActor
final class MockContactsService: ContactsServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
}

@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
    func refreshAuthorizationStatus() async -> PermissionStatus { .notDetermined }
}

// MARK: - Keychain API Key Store

struct KeychainAPIKeyStore: APIKeyStoreProtocol {
    func saveOpenAIKey(_ key: String) throws {
        try KeychainHelper.save(key, for: .openAIAPIKey)
    }

    func loadOpenAIKey() -> String? {
        KeychainHelper.load(for: .openAIAPIKey)
    }

    func deleteOpenAIKey() {
        KeychainHelper.delete(for: .openAIAPIKey)
    }

    var hasOpenAIKey: Bool {
        KeychainHelper.hasValue(for: .openAIAPIKey)
    }
}
