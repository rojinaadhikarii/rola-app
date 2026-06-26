import AppKit
import Foundation

// MARK: - Permission Manager

/// Coordinates macOS permission status and requests.
/// Milestone 1: UI-only stubs. Real implementation in Milestone 2.
@MainActor
final class PermissionManager: PermissionManagerProtocol {

    private var statuses: [PermissionType: PermissionStatus] = [:]

    init() {
        refreshAllStatuses()
    }

    func status(for permission: PermissionType) -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        // Milestone 2 will wire real permission requests.
        // For now, simulate granting optional permissions for UI testing.
        switch permission {
        case .fullDiskAccess:
            statuses[permission] = .notDetermined
        case .contacts, .calendar, .notifications:
            statuses[permission] = .granted
        }
        return statuses[permission] ?? .notDetermined
    }

    func openSystemSettings(for permission: PermissionType) {
        let url: URL? = switch permission {
        case .fullDiskAccess:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        case .contacts:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts")
        case .calendar:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        case .notifications:
            URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
        }

        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    func refreshAllStatuses() {
        for permission in PermissionType.allCases {
            statuses[permission] = .notDetermined
        }
    }
}
