import Foundation
import UserNotifications

// MARK: - Notification Service

@MainActor
final class NotificationService: NotificationServiceProtocol {

    private var cachedStatus: PermissionStatus = .notDetermined

    init() {
        Task { await refreshAuthorizationStatus() }
    }

    func requestAccess() async -> PermissionStatus {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            let status: PermissionStatus = granted ? .granted : .denied
            cachedStatus = status
            return status
        } catch {
            cachedStatus = .denied
            return .denied
        }
    }

    func authorizationStatus() -> PermissionStatus {
        cachedStatus
    }

    func refreshAuthorizationStatus() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status = PermissionStatusMapper.from(notifications: settings.authorizationStatus)
        cachedStatus = status
        return status
    }
}
