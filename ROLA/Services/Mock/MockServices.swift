import Foundation

// MARK: - Mock Services (Milestone 1)

struct MockMessageImportService: MessageImportServiceProtocol {
    func importConversations() async throws -> Int { 0 }
}

struct MockStyleEngine: StyleEngineProtocol {
    func analyzeStyle() async throws {}
}

struct MockAIPipeline: AIPipelineProtocol {
    func generateSuggestion(for messageID: String) async throws -> String {
        "Sounds good!"
    }
}

struct MockCalendarService: CalendarServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
}

struct MockContactsService: ContactsServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
}

struct MockNotificationService: NotificationServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
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
