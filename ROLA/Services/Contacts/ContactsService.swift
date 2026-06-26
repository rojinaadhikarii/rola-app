import Contacts
import Foundation

// MARK: - Contacts Service

@MainActor
final class ContactsService: ContactsServiceProtocol {

    private let store = CNContactStore()

    func requestAccess() async -> PermissionStatus {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted ? .granted : .denied
        } catch {
            return .denied
        }
    }

    func authorizationStatus() -> PermissionStatus {
        PermissionStatusMapper.from(contacts: CNContactStore.authorizationStatus(for: .contacts))
    }
}
