import Foundation

// MARK: - Full Disk Access Checker

/// Detects whether ROLA can read the iMessage database.
/// Full Disk Access cannot be requested programmatically — the user must enable it in System Settings.
enum FullDiskAccessChecker {

    static let messagesDatabasePath: String = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Messages/chat.db")
            .path
    }()

    /// Returns `true` when the iMessage database is readable (FDA granted).
    static var isGranted: Bool {
        canReadMessagesDatabase(at: messagesDatabasePath)
    }

    /// Testable probe — attempts a real read, not just file-existence checks.
    static func canReadMessagesDatabase(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            return false
        }

        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            _ = try handle.read(upToCount: 16)
            return true
        } catch {
            return false
        }
    }
}
