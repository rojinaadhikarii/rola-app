import Foundation

// MARK: - Learning Service Protocol

protocol LearningServiceProtocol: Sendable {
    func recordFeedback(
        suggestion: ReplySuggestion,
        action: SuggestionAction,
        finalText: String,
        conversation: Conversation
    ) async
}

// MARK: - Learning Service

/// Records feedback, updates local style profiles, and queues cloud sync.
final class LearningService: LearningServiceProtocol, @unchecked Sendable {
    private let feedbackStore: FeedbackStore
    private let syncService: SyncServiceProtocol
    private let styleProfileStore: StyleProfileStore

    init(
        feedbackStore: FeedbackStore,
        styleProfileStore: StyleProfileStore,
        syncService: SyncServiceProtocol
    ) {
        self.feedbackStore = feedbackStore
        self.styleProfileStore = styleProfileStore
        self.syncService = syncService
    }

    func recordFeedback(
        suggestion: ReplySuggestion,
        action: SuggestionAction,
        finalText: String,
        conversation: Conversation
    ) async {
        let feedback = UserFeedback(
            id: UUID(),
            suggestionId: suggestion.id,
            chatId: suggestion.chatId,
            originalText: suggestion.replyText,
            finalText: finalText,
            action: action,
            createdAt: Date()
        )

        feedbackStore.save(feedback)

        if LearningEngine.shouldLearn(from: action) {
            await MainActor.run {
                styleProfileStore.applyLearning(
                    feedback: feedback,
                    displayName: conversation.displayName,
                    isGroup: conversation.isGroup
                )
            }
        }

        await syncService.syncIfNeeded()
    }
}
