import AppKit
import Foundation

// MARK: - Permission Refresh Observer

/// Refreshes permission state when the user returns from System Settings.
@MainActor
final class PermissionRefreshObserver {

    var onRefresh: (@MainActor () -> Void)?

  private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onRefresh?()
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
