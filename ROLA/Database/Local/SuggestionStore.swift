import Foundation

// MARK: - Suggestion Store

/// Persists reply suggestions locally (pending, approved, dismissed).
final class SuggestionStore: @unchecked Sendable {
    private let fileURL: URL
    private var cache: [ReplySuggestion] = []
    private let lock = NSLock()

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let directory = appSupport.appendingPathComponent("com.rola.app", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("suggestions.json")
        loadFromDisk()
    }

    var suggestions: [ReplySuggestion] {
        lock.lock()
        defer { lock.unlock() }
        return cache
    }

    var pendingSuggestions: [ReplySuggestion] {
        lock.lock()
        defer { lock.unlock() }
        return cache.filter { $0.status == .pending && !$0.safetyBlocked }
    }

    var pendingCount: Int {
        pendingSuggestions.count
    }

    func pendingSuggestion(chatId: Int64, messageId: Int64) -> ReplySuggestion? {
        lock.lock()
        defer { lock.unlock() }
        return cache.first {
            $0.chatId == chatId
                && $0.incomingMessageId == messageId
                && $0.status == .pending
        }
    }

    func latestPending(for chatId: Int64) -> ReplySuggestion? {
        lock.lock()
        defer { lock.unlock() }
        return cache
            .filter { $0.chatId == chatId && $0.status == .pending && !$0.safetyBlocked }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func chatIdsWithPendingSuggestions() -> Set<Int64> {
        Set(pendingSuggestions.map(\.chatId))
    }

    func save(_ suggestion: ReplySuggestion) {
        lock.lock()
        if let index = cache.firstIndex(where: { $0.id == suggestion.id }) {
            cache[index] = suggestion
        } else {
            cache.append(suggestion)
        }
        let snapshot = cache
        lock.unlock()
        persist(snapshot)
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ReplySuggestion].self, from: data) else {
            return
        }
        cache = decoded
    }

    private func persist(_ suggestions: [ReplySuggestion]) {
        guard let data = try? JSONEncoder().encode(suggestions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
