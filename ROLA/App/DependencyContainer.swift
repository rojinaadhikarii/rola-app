import Foundation

// MARK: - Dependency Container

/// Production dependency wiring. Swap implementations per milestone.
@MainActor
final class DependencyContainer: DependencyContainerProtocol {

    let messageImportService: MessageImportServiceProtocol
    let styleEngine: StyleEngineProtocol
    let aiPipeline: AIPipelineProtocol
    let calendarService: CalendarServiceProtocol
    let contactsService: ContactsServiceProtocol
    let notificationService: NotificationServiceProtocol
    let permissionManager: PermissionManagerProtocol
    let apiKeyStore: APIKeyStoreProtocol

    init(
        messageImportService: MessageImportServiceProtocol = MockMessageImportService(),
        styleEngine: StyleEngineProtocol = MockStyleEngine(),
        aiPipeline: AIPipelineProtocol = MockAIPipeline(),
        calendarService: CalendarServiceProtocol = MockCalendarService(),
        contactsService: ContactsServiceProtocol = MockContactsService(),
        notificationService: NotificationServiceProtocol = MockNotificationService(),
        permissionManager: PermissionManagerProtocol? = nil,
        apiKeyStore: APIKeyStoreProtocol = KeychainAPIKeyStore()
    ) {
        self.messageImportService = messageImportService
        self.styleEngine = styleEngine
        self.aiPipeline = aiPipeline
        self.calendarService = calendarService
        self.contactsService = contactsService
        self.notificationService = notificationService
        self.permissionManager = permissionManager ?? PermissionManager()
        self.apiKeyStore = apiKeyStore
    }

    static let live = DependencyContainer()
    static let preview = DependencyContainer()
}
