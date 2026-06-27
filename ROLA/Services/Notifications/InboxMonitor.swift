import AppKit
import Foundation

// MARK: - Inbox Monitor

/// Watches the conversation store and schedules notifications for new needs-reply threads.
@MainActor
@Observable
final class InboxMonitor {
    private let scheduler: NotificationScheduler
    private var knownNeedsReplyIDs: Set<Int64> = []
    private var hasInitialized = false

    init(scheduler: NotificationScheduler = NotificationScheduler()) {
        self.scheduler = scheduler
    }

    func evaluate(conversations: [Conversation], isAppActive: Bool) async {
        let currentNeedsReply = Set(conversations.filter(\.needsReply).map(\.id))

        if !hasInitialized {
            knownNeedsReplyIDs = currentNeedsReply
            hasInitialized = true
            return
        }

        let newNeedsReply = currentNeedsReply.subtracting(knownNeedsReplyIDs)
        knownNeedsReplyIDs = currentNeedsReply

        guard !newNeedsReply.isEmpty, !isAppActive else { return }

        let newcomers = conversations.filter { newNeedsReply.contains($0.id) }
        await scheduler.scheduleBatch(newcomers)
    }

    func reset() {
        knownNeedsReplyIDs = []
        hasInitialized = false
    }

    var inboxHealth: InboxHealth {
        let needsReply = knownNeedsReplyIDs.count
        return InboxHealth(needsReplyCount: needsReply, totalCount: max(needsReply, 1))
    }

    func inboxHealth(for conversations: [Conversation]) -> InboxHealth {
        InboxHealth(
            needsReplyCount: conversations.filter(\.needsReply).count,
            totalCount: max(conversations.count, 1)
        )
    }
}
