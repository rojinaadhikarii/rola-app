import AppKit
import Foundation

// MARK: - System Settings URLs

/// Deep links into macOS System Settings privacy panes.
enum SystemSettingsURLs {

    static func url(for permission: PermissionType) -> URL? {
        switch permission {
        case .fullDiskAccess:
            // macOS 13+ System Settings, with fallback for older preference panes.
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles")
                ?? URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")

        case .contacts:
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Contacts")
                ?? URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts")

        case .calendar:
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Calendars")
                ?? URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")

        case .notifications:
            URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
                ?? URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
        }
    }

    static func open(for permission: PermissionType) {
        guard let url = url(for: permission) else { return }
        NSWorkspace.shared.open(url)
    }
}
