@preconcurrency import AppKit
import Foundation

// MARK: - Permission Refresh Observer

/// Refreshes permission state when the user returns from System Settings.
final class PermissionRefreshObserver {

    private let observer: NSObjectProtocol

    /// Called on the main queue when the app becomes active.
    var onRefresh: (() -> Void)?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onRefresh?()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(observer)
    }
}
