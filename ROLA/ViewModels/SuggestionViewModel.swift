import AppKit
import Foundation
import Observation

// MARK: - Suggestion View Model

@Observable
@MainActor
final class SuggestionViewModel {
    private let aiPipeline: AIPipelineProtocol
    private let learningService: LearningServiceProtocol
    private let suggestionStore: SuggestionStore
    private let styleProfileStore: StyleProfileStore
    private let calendarContextStore: CalendarContextStore

    var currentSuggestion: ReplySuggestion?
    var currentConversation: Conversation?
    var isGenerating = false
    var errorMessage: String?

    init(
        aiPipeline: AIPipelineProtocol,
        learningService: LearningServiceProtocol,
        suggestionStore: SuggestionStore,
        styleProfileStore: StyleProfileStore,
        calendarContextStore: CalendarContextStore
    ) {
        self.aiPipeline = aiPipeline
        self.learningService = learningService
        self.suggestionStore = suggestionStore
        self.styleProfileStore = styleProfileStore
        self.calendarContextStore = calendarContextStore
    }

    var pendingCount: Int {
        suggestionStore.pendingCount
    }

    func loadSuggestion(
        for conversation: Conversation,
        messages: [ImportedMessage]
    ) {
        currentConversation = conversation

        guard let incoming = messages.last(where: { !$0.isFromMe }) else {
            reset()
            return
        }

        if let existing = suggestionStore.pendingSuggestion(
            chatId: conversation.id,
            messageId: incoming.id
        ) {
            currentSuggestion = existing
            errorMessage = nil
            return
        }

        if let latest = suggestionStore.latestPending(for: conversation.id) {
            currentSuggestion = latest
            errorMessage = nil
            return
        }

        currentSuggestion = nil
        errorMessage = nil
    }

    func generateSuggestion(
        for conversation: Conversation,
        messages: [ImportedMessage]
    ) async {
        currentConversation = conversation
        guard let incoming = messages.last(where: { !$0.isFromMe }) else { return }

        if let existing = suggestionStore.pendingSuggestion(
            chatId: conversation.id,
            messageId: incoming.id
        ) {
            currentSuggestion = existing
            return
        }

        isGenerating = true
        errorMessage = nil

        do {
            let suggestion = try await aiPipeline.generateReplySuggestion(
                conversation: conversation,
                messages: messages,
                incomingMessage: incoming,
                globalStyle: styleProfileStore.globalProfile,
                contactStyle: styleProfileStore.profile(for: conversation.id),
                calendarContext: calendarContextStore.context
            )
            currentSuggestion = suggestion
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }

    func approveSuggestion() {
        guard let suggestion = currentSuggestion,
              let conversation = currentConversation,
              suggestion.isActionable else { return }

        aiPipeline.approveSuggestion(suggestion, editedText: nil)
        copyToClipboard(suggestion.displayText)
        refreshCurrentSuggestion()

        Task {
            await learningService.recordFeedback(
                suggestion: suggestion,
                action: .approved,
                finalText: suggestion.displayText,
                conversation: conversation
            )
        }
    }

    func editAndApprove(editedText: String) {
        guard let suggestion = currentSuggestion,
              let conversation = currentConversation,
              suggestion.isActionable else { return }

        aiPipeline.approveSuggestion(suggestion, editedText: editedText)
        copyToClipboard(editedText)
        refreshCurrentSuggestion()

        Task {
            await learningService.recordFeedback(
                suggestion: suggestion,
                action: .edited,
                finalText: editedText,
                conversation: conversation
            )
        }
    }

    func dismissSuggestion() {
        guard let suggestion = currentSuggestion,
              let conversation = currentConversation else { return }

        aiPipeline.dismissSuggestion(suggestion)
        refreshCurrentSuggestion()

        Task {
            await learningService.recordFeedback(
                suggestion: suggestion,
                action: .dismissed,
                finalText: suggestion.replyText,
                conversation: conversation
            )
        }
    }

    func reset() {
        currentSuggestion = nil
        currentConversation = nil
        isGenerating = false
        errorMessage = nil
    }

    private func refreshCurrentSuggestion() {
        guard let suggestion = currentSuggestion else { return }
        currentSuggestion = suggestionStore.suggestions.first { $0.id == suggestion.id }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
