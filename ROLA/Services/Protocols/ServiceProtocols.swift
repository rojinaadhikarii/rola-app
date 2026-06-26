import Foundation

// MARK: - Service Protocols

protocol MessageImportServiceProtocol: Sendable {
    func importConversations(onProgress: (@Sendable (Double) -> Void)?) async throws -> [Conversation]
    func fetchRecentMessages(chatId: Int64, limit: Int) async throws -> [ImportedMessage]
}

protocol StyleEngineProtocol: Sendable {
    func analyzeStyle() async throws
}

protocol AIPipelineProtocol: Sendable {
    func generateSuggestion(for messageID: String) async throws -> String
}

@MainActor
protocol CalendarServiceProtocol: AnyObject {
    func requestAccess() async -> PermissionStatus
    func authorizationStatus() -> PermissionStatus
}

@MainActor
protocol ContactsServiceProtocol: AnyObject {
    func requestAccess() async -> PermissionStatus
    func authorizationStatus() -> PermissionStatus
}

@MainActor
protocol NotificationServiceProtocol: AnyObject {
    func requestAccess() async -> PermissionStatus
    func authorizationStatus() -> PermissionStatus
    func refreshAuthorizationStatus() async -> PermissionStatus
}

@MainActor
protocol PermissionManagerProtocol: AnyObject {
    func status(for permission: PermissionType) -> PermissionStatus
    func request(_ permission: PermissionType) async -> PermissionStatus
    func openSystemSettings(for permission: PermissionType)
    func refreshAllStatuses() async
    var hasPromptedFullDiskAccess: Bool { get }
}

protocol APIKeyStoreProtocol: Sendable {
    func saveOpenAIKey(_ key: String) throws
    func loadOpenAIKey() -> String?
    func deleteOpenAIKey()
    var hasOpenAIKey: Bool { get }
}

// MARK: - Dependency Container Protocol

@MainActor
protocol DependencyContainerProtocol: AnyObject {
    var messageImportService: MessageImportServiceProtocol { get }
    var conversationStore: ConversationStore { get }
    var styleEngine: StyleEngineProtocol { get }
    var aiPipeline: AIPipelineProtocol { get }
    var calendarService: CalendarServiceProtocol { get }
    var contactsService: ContactsServiceProtocol { get }
    var notificationService: NotificationServiceProtocol { get }
    var permissionManager: PermissionManagerProtocol { get }
    var apiKeyStore: APIKeyStoreProtocol { get }
}
