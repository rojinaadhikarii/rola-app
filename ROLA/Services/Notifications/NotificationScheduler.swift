import Foundation
import UserNotifications

// MARK: - Notification Scheduling Protocol

protocol NotificationSchedulingProtocol: Sendable {
    func scheduleNeedsReply(_ notification: ROLANotification.NeedsReply) async
    func sendTestNotification() async throws
    func clearPendingNotifications() async
}

// MARK: - Notification Scheduler

/// Schedules deduplicated macOS notifications for conversations needing a reply.
final class NotificationScheduler: NotificationSchedulingProtocol, @unchecked Sendable {
    private let preferencesStore: NotificationPreferencesStoreProtocol
    private var lastNotifiedAt: [Int64: Date] = [:]
    private let lock = NSLock()
    private let maxPerBatch = 3

    init(preferencesStore: NotificationPreferencesStoreProtocol = NotificationPreferencesStore()) {
        self.preferencesStore = preferencesStore
    }

    func scheduleNeedsReply(_ notification: ROLANotification.NeedsReply) async {
        let preferences = preferencesStore.load()
        guard preferences.isEnabled, preferences.notifyOnNewNeedsReply else { return }
        guard shouldNotify(chatId: notification.chatId, minimumInterval: preferences.minimumIntervalMinutes) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Reply to \(notification.displayName)"
        content.body = truncated(notification.messagePreview)
        content.sound = .default
        content.categoryIdentifier = ROLANotification.categoryIdentifier
        content.userInfo = [ROLANotification.chatIdKey: notification.chatId]

        let request = UNNotificationRequest(
            identifier: "needs-reply-\(notification.chatId)-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            markNotified(chatId: notification.chatId)
        } catch {
            // Non-fatal — user may have denied permission.
        }
    }

    func scheduleBatch(_ conversations: [Conversation]) async {
        let preferences = preferencesStore.load()
        guard preferences.isEnabled, preferences.notifyOnNewNeedsReply else { return }

        let candidates = conversations
            .filter(\.needsReply)
            .filter { shouldNotify(chatId: $0.id, minimumInterval: preferences.minimumIntervalMinutes) }
            .prefix(maxPerBatch)

        for conversation in candidates {
            let preview = conversation.lastMessageText ?? "New message waiting for your reply"
            await scheduleNeedsReply(
                ROLANotification.NeedsReply(
                    chatId: conversation.id,
                    displayName: conversation.displayName,
                    messagePreview: preview
                )
            )
        }
    }

    func sendTestNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "ROLA is ready"
        content.body = "You'll get notified when messages need your attention."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "rola-test-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    func clearPendingNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .filter { $0.identifier.hasPrefix("needs-reply-") }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    private func shouldNotify(chatId: Int64, minimumInterval: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let last = lastNotifiedAt[chatId] else { return true }
        let interval = TimeInterval(minimumInterval * 60)
        return Date().timeIntervalSince(last) >= interval
    }

    private func markNotified(chatId: Int64) {
        lock.lock()
        lastNotifiedAt[chatId] = Date()
        lock.unlock()
    }

    private func truncated(_ text: String, limit: Int = 120) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit - 1)) + "…"
    }
}
