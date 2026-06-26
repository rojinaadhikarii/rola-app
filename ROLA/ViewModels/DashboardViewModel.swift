import Foundation

// MARK: - Dashboard Filter

enum DashboardFilter: String, CaseIterable, Identifiable {
    case needsAttention
    case all
    case suggestions
    case followUps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .needsAttention: "Needs Attention"
        case .all: "All"
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

    var selectedFilter: DashboardFilter = .needsAttention

    init(conversationStore: ConversationStore) {
        self.conversationStore = conversationStore
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
        case .suggestions, .followUps:
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

    func count(for filter: DashboardFilter) -> Int {
        switch filter {
        case .needsAttention:
            conversationStore.needsAttention.count
        case .all:
            conversationStore.conversations.count
        case .suggestions, .followUps:
            0
        }
    }

    func selectFilter(_ filter: DashboardFilter) {
        selectedFilter = filter
    }

    func selectConversation(_ conversation: Conversation) async {
        await conversationStore.selectConversation(conversation)
    }

    func refresh() async {
        await conversationStore.refresh()
    }
}
