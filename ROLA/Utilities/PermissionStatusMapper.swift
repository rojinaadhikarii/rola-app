import Contacts
import EventKit
import Foundation
import UserNotifications

// MARK: - Permission Status Mapper

enum PermissionStatusMapper {

    static func from(contacts status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited:
            .granted
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .notDetermined
        @unknown default:
            .notDetermined
        }
    }

    static func from(calendar status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .fullAccess, .authorized:
            .granted
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .notDetermined
        case .writeOnly:
            // Write-only is insufficient for reading availability.
            .denied
        @unknown default:
            .notDetermined
        }
    }

    static func from(notifications status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .provisional, .ephemeral:
            .granted
        case .denied:
            .denied
        case .notDetermined:
            .notDetermined
        @unknown default:
            .notDetermined
        }
    }
}
