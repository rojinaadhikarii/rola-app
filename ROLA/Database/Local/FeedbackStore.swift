import Foundation

// MARK: - Stored Feedback

struct StoredFeedback: Identifiable, Codable, Hashable, Sendable {
    let feedback: UserFeedback
    var syncedAt: Date?

    var id: UUID { feedback.id }

    var needsSync: Bool { syncedAt == nil }
}

// MARK: - Feedback Store

/// Persists user feedback from suggestion actions; tracks Supabase sync state.
final class FeedbackStore: @unchecked Sendable {
    private let fileURL: URL
    private var cache: [StoredFeedback] = []
    private let lock = NSLock()

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let directory = appSupport.appendingPathComponent("com.rola.app", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("feedback.json")
        loadFromDisk()
        migrateLegacyJSONFilesIfNeeded(in: directory.appendingPathComponent("feedback", isDirectory: true))
    }

    var allFeedback: [StoredFeedback] {
        lock.lock()
        defer { lock.unlock() }
        return cache
    }

    var pendingSync: [StoredFeedback] {
        lock.lock()
        defer { lock.unlock() }
        return cache.filter(\.needsSync)
    }

    var pendingSyncCount: Int {
        pendingSync.count
    }

    func save(_ feedback: UserFeedback) {
        lock.lock()
        let stored = StoredFeedback(feedback: feedback, syncedAt: nil)
        if let index = cache.firstIndex(where: { $0.id == feedback.id }) {
            cache[index] = stored
        } else {
            cache.append(stored)
        }
        let snapshot = cache
        lock.unlock()
        persist(snapshot)
    }

    func markSynced(_ feedbackID: UUID, at date: Date = Date()) {
        lock.lock()
        guard let index = cache.firstIndex(where: { $0.id == feedbackID }) else {
            lock.unlock()
            return
        }
        cache[index].syncedAt = date
        let snapshot = cache
        lock.unlock()
        persist(snapshot)
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([StoredFeedback].self, from: data) else {
            return
        }
        cache = decoded
    }

    private func persist(_ items: [StoredFeedback]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Migrates per-file feedback JSON written by Milestone 6 into the unified store.
    private func migrateLegacyJSONFilesIfNeeded(in legacyDirectory: URL) {
        guard FileManager.default.fileExists(atPath: legacyDirectory.path) else { return }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: legacyDirectory,
            includingPropertiesForKeys: nil
        )) ?? []

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let feedback = try? JSONDecoder().decode(UserFeedback.self, from: data) else {
                continue
            }
            save(feedback)
            try? FileManager.default.removeItem(at: file)
        }
    }
}
