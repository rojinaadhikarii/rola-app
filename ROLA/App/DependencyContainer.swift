import Foundation

// MARK: - Dependency Container

/// Production dependency wiring. Swap implementations per milestone.
@MainActor
final class DependencyContainer: DependencyContainerProtocol {

    let messageImportService: MessageImportServiceProtocol
    let conversationStore: ConversationStore
    let styleProfileStore: StyleProfileStore
    let calendarContextStore: CalendarContextStore
    let styleEngine: StyleEngineProtocol
    let aiPipeline: AIPipelineProtocol
    let calendarService: CalendarServiceProtocol
    let contactsService: ContactsServiceProtocol
    let notificationService: NotificationServiceProtocol
    let permissionManager: PermissionManagerProtocol
    let apiKeyStore: APIKeyStoreProtocol

    init(
        messageImportService: MessageImportServiceProtocol? = nil,
        styleEngine: StyleEngineProtocol? = nil,
        aiPipeline: AIPipelineProtocol = MockAIPipeline(),
        calendarService: CalendarServiceProtocol? = nil,
        contactsService: ContactsServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        permissionManager: PermissionManagerProtocol? = nil,
        apiKeyStore: APIKeyStoreProtocol = KeychainAPIKeyStore(),
        useMockPermissions: Bool = false,
        useMockImport: Bool = false,
        useMockStyle: Bool = false,
        useMockCalendar: Bool = false
    ) {
        let calendar = calendarService ?? (
            (useMockPermissions || useMockCalendar)
                ? MockCalendarService(grantsAccess: true)
                : CalendarService()
        )
        let contacts = contactsService ?? (useMockPermissions ? MockContactsService() : ContactsService())
        let notifications = notificationService ?? (useMockPermissions ? MockNotificationService() : NotificationService())
        let importService = messageImportService ?? (useMockImport ? MockMessageImportService() : MessageImportService())
        let style = styleEngine ?? (useMockStyle ? MockStyleEngine() : StyleEngine())

        self.calendarService = calendar
        self.contactsService = contacts
        self.notificationService = notifications
        self.messageImportService = importService
        self.styleEngine = style
        self.conversationStore = ConversationStore(importService: importService)
        self.styleProfileStore = StyleProfileStore(styleEngine: style)
        self.calendarContextStore = CalendarContextStore(calendarService: calendar)
        self.aiPipeline = aiPipeline
        self.permissionManager = permissionManager ?? PermissionManager(
            contactsService: contacts,
            calendarService: calendar,
            notificationService: notifications
        )
        self.apiKeyStore = apiKeyStore
    }

    static let live = DependencyContainer()
    static let preview = DependencyContainer(
        useMockPermissions: true,
        useMockImport: true,
        useMockStyle: true,
        useMockCalendar: true
    )
}
