import Foundation

// MARK: - Service Protocols

protocol MessageImportServiceProtocol: Sendable {
    func importConversations() async throws -> Int
}

protocol StyleEngineProtocol: Sendable {
    func analyzeStyle() async throws
}

protocol AIPipelineProtocol: Sendable {
    func generateSuggestion(for messageID: String) async throws -> String
}

protocol CalendarServiceProtocol: Sendable {
    func requestAccess() async -> PermissionStatus
    func authorizationStatus() -> PermissionStatus
}

protocol ContactsServiceProtocol: Sendable {
    func requestAccess() async -> PermissionStatus
    func authorizationStatus() -> PermissionStatus
}

protocol NotificationServiceProtocol: Sendable {
    func requestAccess() async -> PermissionStatus
    func authorizationStatus() -> PermissionStatus
}

protocol PermissionManagerProtocol: Sendable {
    func status(for permission: PermissionType) -> PermissionStatus
    func request(_ permission: PermissionType) async -> PermissionStatus
    func openSystemSettings(for permission: PermissionType)
    func refreshAllStatuses()
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
    var styleEngine: StyleEngineProtocol { get }
    var aiPipeline: AIPipelineProtocol { get }
    var calendarService: CalendarServiceProtocol { get }
    var contactsService: ContactsServiceProtocol { get }
    var notificationService: NotificationServiceProtocol { get }
    var permissionManager: PermissionManagerProtocol { get }
    var apiKeyStore: APIKeyStoreProtocol { get }
}
