import Foundation

// MARK: - Service Protocols

protocol MessageImportServiceProtocol: Sendable {
    func importConversations(onProgress: (@Sendable (Double) -> Void)?) async throws -> [Conversation]
    func fetchRecentMessages(chatId: Int64, limit: Int) async throws -> [ImportedMessage]
}

protocol StyleEngineProtocol: Sendable {
    func analyzeStyle(onProgress: (@Sendable (Double) -> Void)?) async throws -> StyleAnalysisResult
}

protocol AIPipelineProtocol: Sendable {
    func generateReplySuggestion(
        conversation: Conversation,
        messages: [ImportedMessage],
        incomingMessage: ImportedMessage,
        globalStyle: StyleProfile?,
        contactStyle: StyleProfile?,
        calendarContext: CalendarContext?
    ) async throws -> ReplySuggestion

    func approveSuggestion(_ suggestion: ReplySuggestion, editedText: String?)
    func dismissSuggestion(_ suggestion: ReplySuggestion)
}

@MainActor
protocol CalendarServiceProtocol: AnyObject {
    func requestAccess() async -> PermissionStatus
    func authorizationStatus() -> PermissionStatus
    func fetchContext() async throws -> CalendarContext
    func isAvailable(from start: Date, to end: Date) async -> Bool
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
    func sendTestNotification() async throws
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
    var styleProfileStore: StyleProfileStore { get }
    var styleEngine: StyleEngineProtocol { get }
    var calendarContextStore: CalendarContextStore { get }
    var aiPipeline: AIPipelineProtocol { get }
    var suggestionStore: SuggestionStore { get }
    var feedbackStore: FeedbackStore { get }
    var syncService: SyncService { get }
    var learningService: LearningService { get }
    var inboxMonitor: InboxMonitor { get }
    var notificationScheduler: NotificationScheduler { get }
    var notificationPreferencesStore: NotificationPreferencesStoreProtocol { get }
    var calendarService: CalendarServiceProtocol { get }
    var contactsService: ContactsServiceProtocol { get }
    var notificationService: NotificationServiceProtocol { get }
    var permissionManager: PermissionManagerProtocol { get }
    var apiKeyStore: APIKeyStoreProtocol { get }
}
