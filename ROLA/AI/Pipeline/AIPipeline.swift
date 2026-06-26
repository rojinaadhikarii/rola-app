import Foundation

// MARK: - AI Pipeline Error

enum AIPipelineError: LocalizedError, Sendable {
    case missingAPIKey
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Add your OpenAI API key in Settings to generate suggestions."
        case .generationFailed(let reason):
            reason
        }
    }
}

// MARK: - AI Pipeline

/// Orchestrates classify → safety → context → generate → safety → present.
final class AIPipeline: AIPipelineProtocol, @unchecked Sendable {
    private let apiKeyStore: APIKeyStoreProtocol
    private let suggestionStore: SuggestionStore
    private let openAIClient: OpenAIClient

    init(
        apiKeyStore: APIKeyStoreProtocol,
        suggestionStore: SuggestionStore,
        openAIClient: OpenAIClient = OpenAIClient()
    ) {
        self.apiKeyStore = apiKeyStore
        self.suggestionStore = suggestionStore
        self.openAIClient = openAIClient
    }

    // MARK: - Full Pipeline

    func generateReplySuggestion(
        conversation: Conversation,
        messages: [ImportedMessage],
        incomingMessage: ImportedMessage,
        globalStyle: StyleProfile?,
        contactStyle: StyleProfile?,
        calendarContext: CalendarContext?
    ) async throws -> ReplySuggestion {
        if let existing = suggestionStore.pendingSuggestion(
            chatId: conversation.id,
            messageId: incomingMessage.id
        ) {
            return existing
        }

        let preCheck = SafetyClassifier.preCheck(
            message: incomingMessage.text,
            conversation: conversation
        )
        if preCheck.isBlocked {
            let blocked = ReplySuggestion.blocked(
                chatId: conversation.id,
                messageText: incomingMessage.text,
                reason: preCheck.reason ?? "This message requires your personal attention.",
                messageId: incomingMessage.id
            )
            suggestionStore.save(blocked)
            return blocked
        }

        guard let apiKey = apiKeyStore.loadOpenAIKey(), !apiKey.isEmpty else {
            throw AIPipelineError.missingAPIKey
        }

        let request = SuggestionRequest(
            conversation: conversation,
            messages: messages,
            globalStyle: globalStyle,
            contactStyle: contactStyle,
            calendarContext: calendarContext
        )

        let systemPrompt = PromptBuilder.systemPrompt()
        let userPrompt = PromptBuilder.userPrompt(for: request)

        let result: OpenAIGenerationResult
        do {
            result = try await openAIClient.generate(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                apiKey: apiKey
            )
        } catch {
            let failed = ReplySuggestion.failed(
                chatId: conversation.id,
                messageText: incomingMessage.text,
                error: error.localizedDescription,
                messageId: incomingMessage.id
            )
            suggestionStore.save(failed)
            throw AIPipelineError.generationFailed(error.localizedDescription)
        }

        let postCheck = SafetyClassifier.postCheck(
            reply: result.reply,
            confidence: result.confidence
        )
        if postCheck.isBlocked {
            let blocked = ReplySuggestion.blocked(
                chatId: conversation.id,
                messageText: incomingMessage.text,
                reason: postCheck.reason ?? "Generated reply did not pass safety review.",
                messageId: incomingMessage.id
            )
            suggestionStore.save(blocked)
            return blocked
        }

        var confidence = result.confidence
        confidence = max(0, confidence - postCheck.confidencePenalty)

        let suggestion = ReplySuggestion(
            id: UUID(),
            chatId: conversation.id,
            incomingMessageId: incomingMessage.id,
            incomingMessageText: incomingMessage.text,
            replyText: result.reply,
            confidence: confidence,
            reasoning: result.reasoning,
            status: .pending,
            safetyBlocked: false,
            safetyReason: postCheck.reason,
            createdAt: Date()
        )

        suggestionStore.save(suggestion)
        return suggestion
    }

    func approveSuggestion(_ suggestion: ReplySuggestion, editedText: String? = nil) {
        var updated = suggestion
        let finalText = editedText ?? suggestion.replyText
        updated.status = editedText != nil ? .edited : .approved
        updated.editedText = editedText
        suggestionStore.save(updated)

        logFeedback(
            suggestion: updated,
            action: editedText != nil ? .edited : .approved,
            finalText: finalText
        )
    }

    func dismissSuggestion(_ suggestion: ReplySuggestion) {
        var updated = suggestion
        updated.status = .dismissed
        suggestionStore.save(updated)

        logFeedback(
            suggestion: updated,
            action: .dismissed,
            finalText: suggestion.replyText
        )
    }

    private func logFeedback(
        suggestion: ReplySuggestion,
        action: SuggestionAction,
        finalText: String
    ) {
        let feedback = UserFeedback(
            id: UUID(),
            suggestionId: suggestion.id,
            chatId: suggestion.chatId,
            originalText: suggestion.replyText,
            finalText: finalText,
            action: action,
            createdAt: Date()
        )

        guard let data = try? JSONEncoder().encode(feedback) else { return }
        let url = feedbackDirectory.appendingPathComponent("\(feedback.id).json")
        try? data.write(to: url, options: .atomic)
    }

    private var feedbackDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport
            .appendingPathComponent("com.rola.app", isDirectory: true)
            .appendingPathComponent("feedback", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
