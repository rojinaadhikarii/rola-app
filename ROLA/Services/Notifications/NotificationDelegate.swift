import Foundation
import UserNotifications

// MARK: - Notification Delegate

/// Handles notification taps and forwards chat selection to the app.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onSelectChat: ((Int64) -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        let userInfo = response.notification.request.content.userInfo
        if let chatId = userInfo[ROLANotification.chatIdKey] as? Int64 {
            onSelectChat?(chatId)
        } else if let number = userInfo[ROLANotification.chatIdKey] as? NSNumber {
            onSelectChat?(number.int64Value)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
