import Foundation

// MARK: - Suggestion Status

enum SuggestionStatus: String, Codable, Hashable, Sendable {
    case pending
    case approved
    case edited
    case dismissed
    case blocked
    case failed
}

// MARK: - Suggestion Action

enum SuggestionAction: String, Codable, Hashable, Sendable {
    case approved
    case edited
    case dismissed
}

// MARK: - Confidence Level

enum ConfidenceLevel: String, Sendable {
    case high
    case medium
    case low

    init(score: Double) {
        switch score {
        case 0.75...: self = .high
        case 0.45..<0.75: self = .medium
        default: self = .low
        }
    }

    var title: String {
        switch self {
        case .high: "High confidence"
        case .medium: "Medium confidence"
        case .low: "Low confidence"
        }
    }

    var systemImage: String {
        switch self {
        case .high: "checkmark.shield"
        case .medium: "exclamationmark.shield"
        case .low: "questionmark.circle"
        }
    }
}

// MARK: - Suggestion Request

struct SuggestionRequest: Sendable {
    let conversation: Conversation
    let messages: [ImportedMessage]
    let globalStyle: StyleProfile?
    let contactStyle: StyleProfile?
    let calendarContext: CalendarContext?
}

// MARK: - Reply Suggestion

struct ReplySuggestion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let chatId: Int64
    let incomingMessageId: Int64?
    let incomingMessageText: String
    let replyText: String
    let confidence: Double
    let reasoning: String?
    var status: SuggestionStatus
    let safetyBlocked: Bool
    let safetyReason: String?
    let createdAt: Date
    var editedText: String?

    var displayText: String {
        editedText ?? replyText
    }

    var confidenceLevel: ConfidenceLevel {
        ConfidenceLevel(score: confidence)
    }

    var isActionable: Bool {
        status == .pending && !safetyBlocked
    }

    static func blocked(
        chatId: Int64,
        messageText: String,
        reason: String,
        messageId: Int64? = nil
    ) -> ReplySuggestion {
        ReplySuggestion(
            id: UUID(),
            chatId: chatId,
            incomingMessageId: messageId,
            incomingMessageText: messageText,
            replyText: "",
            confidence: 0,
            reasoning: nil,
            status: .blocked,
            safetyBlocked: true,
            safetyReason: reason,
            createdAt: Date()
        )
    }

    static func failed(
        chatId: Int64,
        messageText: String,
        error: String,
        messageId: Int64? = nil
    ) -> ReplySuggestion {
        ReplySuggestion(
            id: UUID(),
            chatId: chatId,
            incomingMessageId: messageId,
            incomingMessageText: messageText,
            replyText: "",
            confidence: 0,
            reasoning: error,
            status: .failed,
            safetyBlocked: false,
            safetyReason: nil,
            createdAt: Date()
        )
    }
}

// MARK: - User Feedback

struct UserFeedback: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let suggestionId: UUID
    let chatId: Int64
    let originalText: String
    let finalText: String
    let action: SuggestionAction
    let createdAt: Date
}
