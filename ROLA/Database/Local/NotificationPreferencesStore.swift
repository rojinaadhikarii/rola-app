import Foundation

// MARK: - Notification Preferences Store

protocol NotificationPreferencesStoreProtocol: Sendable {
    func load() -> NotificationPreferences
    func save(_ preferences: NotificationPreferences)
}

struct NotificationPreferencesStore: NotificationPreferencesStoreProtocol {
    func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: NotificationPreferences.storageKey),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }

    func save(_ preferences: NotificationPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: NotificationPreferences.storageKey)
    }
}
