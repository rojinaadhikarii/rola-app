import Foundation

// MARK: - Notification Preferences

struct NotificationPreferences: Codable, Hashable, Sendable {
    var isEnabled: Bool
    var notifyOnNewNeedsReply: Bool
    var minimumIntervalMinutes: Int

    static let `default` = NotificationPreferences(
        isEnabled: true,
        notifyOnNewNeedsReply: true,
        minimumIntervalMinutes: 30
    )

    static let storageKey = "com.rola.app.notification-preferences"
}

// MARK: - Inbox Health

enum InboxHealth: Sendable {
    case excellent
    case good
    case attention
    case overloaded

    init(needsReplyCount: Int, totalCount: Int) {
        switch needsReplyCount {
        case 0:
            self = .excellent
        case 1...2:
            self = .good
        case 3...5:
            self = .attention
        default:
            self = .overloaded
        }
    }

    var title: String {
        switch self {
        case .excellent: "All caught up"
        case .good: "Looking good"
        case .attention: "Needs attention"
        case .overloaded: "Inbox busy"
        }
    }

    var systemImage: String {
        switch self {
        case .excellent: "checkmark.circle.fill"
        case .good: "hand.thumbsup.fill"
        case .attention: "exclamationmark.circle.fill"
        case .overloaded: "tray.full.fill"
        }
    }

    /// 0 = empty inbox health, 1 = fully healthy.
    var score: Double {
        switch self {
        case .excellent: 1.0
        case .good: 0.75
        case .attention: 0.45
        case .overloaded: 0.15
        }
    }
}

// MARK: - Notification Payload

enum ROLANotification {
    static let categoryIdentifier = "NEEDS_REPLY"
    static let chatIdKey = "chatId"

    struct NeedsReply: Sendable {
        let chatId: Int64
        let displayName: String
        let messagePreview: String
    }
}
