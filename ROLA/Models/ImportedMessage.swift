import Foundation

// MARK: - Imported Message

/// A single message imported from chat.db.
struct ImportedMessage: Identifiable, Codable, Hashable, Sendable {
    let id: Int64
    let chatId: Int64
    let text: String
    let date: Date
    let isFromMe: Bool
    let handleIdentifier: String?

    var formattedTime: String {
        ImportedMessage.timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
