import Foundation

// MARK: - Permission Manager

/// Coordinates macOS permission status and requests.
@MainActor
final class PermissionManager: PermissionManagerProtocol {

    private let contactsService: ContactsServiceProtocol
    private let calendarService: CalendarServiceProtocol
    private let notificationService: NotificationServiceProtocol

    private var statuses: [PermissionType: PermissionStatus] = [:]
    private(set) var hasPromptedFullDiskAccess = false

    init(
        contactsService: ContactsServiceProtocol,
        calendarService: CalendarServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.contactsService = contactsService
        self.calendarService = calendarService
        self.notificationService = notificationService
        Task { await refreshAllStatuses() }
    }

    func status(for permission: PermissionType) -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        let status: PermissionStatus = switch permission {
        case .fullDiskAccess:
            await requestFullDiskAccess()
        case .contacts:
            await contactsService.requestAccess()
        case .calendar:
            await calendarService.requestAccess()
        case .notifications:
            await notificationService.requestAccess()
        }

        statuses[permission] = status
        return status
    }

    func openSystemSettings(for permission: PermissionType) {
        if permission == .fullDiskAccess {
            hasPromptedFullDiskAccess = true
        }
        SystemSettingsURLs.open(for: permission)
    }

    func refreshAllStatuses() async {
        statuses[.fullDiskAccess] = FullDiskAccessChecker.isGranted ? .granted : .notDetermined
        statuses[.contacts] = contactsService.authorizationStatus()
        statuses[.calendar] = calendarService.authorizationStatus()
        statuses[.notifications] = await notificationService.refreshAuthorizationStatus()
    }

    // MARK: - Full Disk Access

    /// FDA cannot be requested via API — open System Settings and re-check on return.
    private func requestFullDiskAccess() async -> PermissionStatus {
        hasPromptedFullDiskAccess = true
        SystemSettingsURLs.open(for: .fullDiskAccess)

        // Brief pause so System Settings can open before the user returns.
        try? await Task.sleep(for: .milliseconds(300))
        await refreshAllStatuses()
        return status(for: .fullDiskAccess)
    }
}
