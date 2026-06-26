import Foundation

// MARK: - Dashboard Filter

enum DashboardFilter: String, CaseIterable, Identifiable {
    case needsAttention
    case all
    case yourStyle
    case suggestions
    case followUps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .needsAttention: "Needs Attention"
        case .all: "All"
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

    var selectedFilter: DashboardFilter = .needsAttention

    init(conversationStore: ConversationStore, styleProfileStore: StyleProfileStore) {
        self.conversationStore = conversationStore
        self.styleProfileStore = styleProfileStore
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
        case .yourStyle, .suggestions, .followUps:
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

    func count(for filter: DashboardFilter) -> Int {
        switch filter {
        case .needsAttention:
            conversationStore.needsAttention.count
        case .all:
            conversationStore.conversations.count
        case .yourStyle:
            styleProfileStore.hasProfile ? 1 : 0
        case .suggestions, .followUps:
            0
        }
    }

    func selectFilter(_ filter: DashboardFilter) {
        selectedFilter = filter
        if filter == .yourStyle {
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
    }
}
