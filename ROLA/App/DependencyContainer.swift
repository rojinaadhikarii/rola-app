import Foundation
import SwiftUI

// MARK: - Dependency Container

/// Production dependency wiring. Swap implementations per milestone.
@MainActor
final class DependencyContainer: DependencyContainerProtocol {

    let messageImportService: MessageImportServiceProtocol
    let conversationStore: ConversationStore
    let styleProfileStore: StyleProfileStore
    let calendarContextStore: CalendarContextStore
    let suggestionStore: SuggestionStore
    let feedbackStore: FeedbackStore
    let syncService: SyncService
    let learningService: LearningService
    let inboxMonitor: InboxMonitor
    let notificationScheduler: NotificationScheduler
    let notificationPreferencesStore: NotificationPreferencesStoreProtocol
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
        aiPipeline: AIPipelineProtocol? = nil,
        suggestionStore: SuggestionStore? = nil,
        feedbackStore: FeedbackStore? = nil,
        syncService: SyncService? = nil,
        learningService: LearningService? = nil,
        inboxMonitor: InboxMonitor? = nil,
        notificationScheduler: NotificationScheduler? = nil,
        notificationPreferencesStore: NotificationPreferencesStoreProtocol? = nil,
        calendarService: CalendarServiceProtocol? = nil,
        contactsService: ContactsServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        permissionManager: PermissionManagerProtocol? = nil,
        apiKeyStore: APIKeyStoreProtocol = KeychainAPIKeyStore(),
        useMockPermissions: Bool = false,
        useMockImport: Bool = false,
        useMockStyle: Bool = false,
        useMockCalendar: Bool = false,
        useMockAI: Bool = false,
        useMockSync: Bool = false
    ) {
        let calendar = calendarService ?? (
            (useMockPermissions || useMockCalendar)
                ? MockCalendarService(grantsAccess: true)
                : CalendarService()
        )
        let contacts = contactsService ?? (useMockPermissions ? MockContactsService() : ContactsService())
        let importService = messageImportService ?? (useMockImport ? MockMessageImportService() : MessageImportService())
        let style = styleEngine ?? (useMockStyle ? MockStyleEngine() : StyleEngine())
        let keyStore = apiKeyStore
        let suggestions = suggestionStore ?? SuggestionStore()
        let feedback = feedbackStore ?? FeedbackStore()
        let preferencesStore = notificationPreferencesStore ?? NotificationPreferencesStore()
        let scheduler = notificationScheduler ?? NotificationScheduler(preferencesStore: preferencesStore)
        self.notificationPreferencesStore = preferencesStore
        self.notificationScheduler = scheduler

        self.calendarService = calendar
        self.contactsService = contacts
        self.notificationService = notificationService ?? (
            useMockPermissions ? MockNotificationService() : NotificationService(scheduler: scheduler)
        )
        self.messageImportService = importService
        self.styleEngine = style
        self.conversationStore = ConversationStore(importService: importService)
        self.styleProfileStore = StyleProfileStore(styleEngine: style)
        self.calendarContextStore = CalendarContextStore(calendarService: calendar)
        self.suggestionStore = suggestions
        self.feedbackStore = feedback
        self.inboxMonitor = inboxMonitor ?? InboxMonitor(scheduler: scheduler)

        let resolvedSyncService = syncService ?? SyncService(
            feedbackStore: feedback,
            styleProfileStore: self.styleProfileStore
        )
        self.syncService = resolvedSyncService

        let syncBackend: SyncServiceProtocol = useMockSync ? MockSyncService() : resolvedSyncService
        self.learningService = learningService ?? LearningService(
            feedbackStore: feedback,
            styleProfileStore: self.styleProfileStore,
            syncService: syncBackend
        )

        self.aiPipeline = aiPipeline ?? (
            useMockAI
                ? MockAIPipeline(suggestionStore: suggestions)
                : AIPipeline(apiKeyStore: keyStore, suggestionStore: suggestions)
        )
        self.permissionManager = permissionManager ?? PermissionManager(
            contactsService: contacts,
            calendarService: calendar,
            notificationService: self.notificationService
        )
        self.apiKeyStore = keyStore
    }

    static let live = DependencyContainer()
    static let preview = DependencyContainer(
        useMockPermissions: true,
        useMockImport: true,
        useMockStyle: true,
        useMockCalendar: true,
        useMockAI: true,
        useMockSync: true
    )
}
