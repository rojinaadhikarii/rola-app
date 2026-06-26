import Foundation

// MARK: - Dashboard Filter

enum DashboardFilter: String, CaseIterable, Identifiable {
    case needsAttention
    case all
    case calendar
    case yourStyle
    case suggestions
    case followUps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .needsAttention: "Needs Attention"
        case .all: "All"
        case .calendar: "Calendar"
        case .yourStyle: "Your Style"
        case .suggestions: "Suggestions"
        case .followUps: "Follow-ups"
        }
    }
}

// MARK: - Dashboard View Model

@MainActor
@Observable
final class DashboardViewModel {

    private let conversationStore: ConversationStore
    private let styleProfileStore: StyleProfileStore
    private let calendarContextStore: CalendarContextStore
    private let suggestionStore: SuggestionStore

    var selectedFilter: DashboardFilter = .needsAttention

    init(
        conversationStore: ConversationStore,
        styleProfileStore: StyleProfileStore,
        calendarContextStore: CalendarContextStore,
        suggestionStore: SuggestionStore
    ) {
        self.conversationStore = conversationStore
        self.styleProfileStore = styleProfileStore
        self.calendarContextStore = calendarContextStore
        self.suggestionStore = suggestionStore
    }

    var conversations: [Conversation] {
        conversationStore.conversations
    }

    var filteredConversations: [Conversation] {
        switch selectedFilter {
        case .needsAttention:
            conversationStore.needsAttention
        case .all:
            conversationStore.conversations
        case .suggestions:
            conversationsWithPendingSuggestions
        case .yourStyle, .followUps, .calendar:
            []
        }
    }

    var selectedConversation: Conversation? {
        conversationStore.selectedConversation
    }

    var selectedMessages: [ImportedMessage] {
        conversationStore.selectedMessages
    }

    var isLoadingMessages: Bool {
        conversationStore.isLoadingMessages
    }

    var inboxCount: Int {
        conversationStore.inboxCount
    }

    var lastImportDate: Date? {
        conversationStore.lastImportDate
    }

    var importError: String? {
        conversationStore.importError
    }

    var styleAnalysisResult: StyleAnalysisResult? {
        styleProfileStore.analysisResult
    }

    var isAnalyzingStyle: Bool {
        styleProfileStore.isAnalyzing
    }

    var styleAnalysisError: String? {
        styleProfileStore.analysisError
    }

    var hasStyleProfile: Bool {
        styleProfileStore.hasProfile
    }

    var calendarContext: CalendarContext? {
        calendarContextStore.context
    }

    var isLoadingCalendar: Bool {
        calendarContextStore.isLoading
    }

    var calendarError: String? {
        calendarContextStore.lastError
    }

    var hasCalendarAccess: Bool {
        calendarContextStore.hasAccess
    }

    var todayEventCount: Int {
        calendarContextStore.todayEventCount
    }

    var pendingSuggestionCount: Int {
        suggestionStore.pendingCount
    }

    private var conversationsWithPendingSuggestions: [Conversation] {
        let chatIds = suggestionStore.chatIdsWithPendingSuggestions()
        return conversationStore.conversations.filter { chatIds.contains($0.id) }
    }

    func schedulingHint(for conversation: Conversation) -> String? {
        guard let lastIncoming = selectedMessages.last(where: { !$0.isFromMe }) else {
            if let preview = conversation.lastMessageText, !conversation.lastMessageIsFromMe {
                return calendarContextStore.schedulingHint(for: preview)
            }
            return nil
        }
        return calendarContextStore.schedulingHint(for: lastIncoming.text)
    }

    func count(for filter: DashboardFilter) -> Int {
        switch filter {
        case .needsAttention:
            conversationStore.needsAttention.count
        case .all:
            conversationStore.conversations.count
        case .calendar:
            todayEventCount
        case .yourStyle:
            styleProfileStore.hasProfile ? 1 : 0
        case .suggestions:
            suggestionStore.pendingCount
        case .followUps:
            0
        }
    }

    func selectFilter(_ filter: DashboardFilter) {
        selectedFilter = filter
        if filter == .yourStyle || filter == .calendar {
            Task { await conversationStore.selectConversation(nil) }
        }
    }

    func selectConversation(_ conversation: Conversation) async {
        await conversationStore.selectConversation(conversation)
    }

    func refresh() async {
        await conversationStore.refresh()
        if conversationStore.importError == nil {
            await styleProfileStore.analyze()
        }
        await calendarContextStore.refresh()
    }

    func requestCalendarAccess() async {
        await calendarContextStore.requestAccessAndRefresh()
    }
}
