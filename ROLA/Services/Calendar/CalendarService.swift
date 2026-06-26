import EventKit
import Foundation

// MARK: - Calendar Service

@MainActor
final class CalendarService: CalendarServiceProtocol {

    private let store = EKEventStore()

    func authorizationStatus() -> PermissionStatus {
        PermissionStatusMapper.from(calendar: EKEventStore.authorizationStatus(for: .event))
    }

    func requestAccess() async -> PermissionStatus {
        do {
            let granted = try await store.requestFullAccessToEvents()
            return granted ? .granted : .denied
        } catch {
            return .denied
        }
    }
}
