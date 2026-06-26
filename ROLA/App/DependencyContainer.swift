import Foundation

// MARK: - Dependency Container

/// Production dependency wiring. Swap implementations per milestone.
@MainActor
final class DependencyContainer: DependencyContainerProtocol {

    let messageImportService: MessageImportServiceProtocol
    let conversationStore: ConversationStore
    let styleEngine: StyleEngineProtocol
    let aiPipeline: AIPipelineProtocol
    let calendarService: CalendarServiceProtocol
    let contactsService: ContactsServiceProtocol
    let notificationService: NotificationServiceProtocol
    let permissionManager: PermissionManagerProtocol
    let apiKeyStore: APIKeyStoreProtocol

    init(
        messageImportService: MessageImportServiceProtocol? = nil,
        styleEngine: StyleEngineProtocol = MockStyleEngine(),
        aiPipeline: AIPipelineProtocol = MockAIPipeline(),
        calendarService: CalendarServiceProtocol? = nil,
        contactsService: ContactsServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        permissionManager: PermissionManagerProtocol? = nil,
        apiKeyStore: APIKeyStoreProtocol = KeychainAPIKeyStore(),
        useMockPermissions: Bool = false,
        useMockImport: Bool = false
    ) {
        let calendar = calendarService ?? (useMockPermissions ? MockCalendarService() : CalendarService())
        let contacts = contactsService ?? (useMockPermissions ? MockContactsService() : ContactsService())
        let notifications = notificationService ?? (useMockPermissions ? MockNotificationService() : NotificationService())
        let importService = messageImportService ?? (useMockImport ? MockMessageImportService() : MessageImportService())

        self.calendarService = calendar
        self.contactsService = contacts
        self.notificationService = notifications
        self.messageImportService = importService
        self.conversationStore = ConversationStore(importService: importService)
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
    static let preview = DependencyContainer(useMockPermissions: true, useMockImport: true)
}
