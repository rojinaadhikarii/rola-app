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
        calendarService: CalendarServiceProtocol? = nil,
        contactsService: ContactsServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        permissionManager: PermissionManagerProtocol? = nil,
        apiKeyStore: APIKeyStoreProtocol = KeychainAPIKeyStore(),
        useMockPermissions: Bool = false
    ) {
        let calendar = calendarService ?? (useMockPermissions ? MockCalendarService() : CalendarService())
        let contacts = contactsService ?? (useMockPermissions ? MockContactsService() : ContactsService())
        let notifications = notificationService ?? (useMockPermissions ? MockNotificationService() : NotificationService())

        self.calendarService = calendar
        self.contactsService = contacts
        self.notificationService = notifications
        self.messageImportService = messageImportService
        self.styleEngine = styleEngine
        self.aiPipeline = aiPipeline
        self.permissionManager = permissionManager ?? PermissionManager(
            contactsService: contacts,
            calendarService: calendar,
            notificationService: notifications
        )
        self.apiKeyStore = apiKeyStore
    }

    static let live = DependencyContainer()
    static let preview = DependencyContainer(useMockPermissions: true)
}
