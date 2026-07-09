import Foundation

// MARK: - Conversation

/// A denormalized iMessage thread for dashboard display.
struct Conversation: Identifiable, Codable, Hashable, Sendable {
    let id: Int64
    let guid: String?
    let displayName: String
    let participantHandles: [String]
    let serviceName: String
    let isGroup: Bool
    let lastMessageText: String?
    let lastMessageDate: Date?
    let lastMessageIsFromMe: Bool
    let needsReply: Bool

    var initials: String {
        let words = displayName.split(separator: " ")
        if words.count >= 2 {
            let first = words[0].prefix(1)
            let second = words[1].prefix(1)
            return "\(first)\(second)".uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    var lastMessagePreview: String {
        guard let text = lastMessageText, !text.isEmpty else {
            return "No messages"
        }
        let prefix = lastMessageIsFromMe ? "You: " : ""
        return prefix + text
    }

    var formattedDate: String {
        guard let lastMessageDate else { return "" }
        return RelativeDateTimeFormatter.rolaFormatter.localizedString(
            for: lastMessageDate,
            relativeTo: Date()
        )
    }
}

// MARK: - Relative Date Formatter

extension RelativeDateTimeFormatter {
    static let rolaFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
