import SwiftUI

// MARK: - App Route

/// Top-level navigation destinations after onboarding.
enum AppRoute: Equatable {
    case onboarding
    case dashboard
    case settings
}

// MARK: - Onboarding Step

/// Linear onboarding flow steps.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case privacy = 1
    case permissions = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .privacy: "Privacy"
        case .permissions: "Permissions"
        }
    }
}

// MARK: - Permission Type

/// macOS permissions ROLA requires.
enum PermissionType: String, CaseIterable, Identifiable {
    case fullDiskAccess
    case contacts
    case calendar
    case notifications

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullDiskAccess: "Full Disk Access"
        case .contacts: "Contacts"
        case .calendar: "Calendar"
        case .notifications: "Notifications"
        }
    }

    var subtitle: String {
        switch self {
        case .fullDiskAccess:
            "Read your iMessage history locally on this Mac"
        case .contacts:
            "Match messages to people you know"
        case .calendar:
            "Suggest replies based on your availability"
        case .notifications:
            "Alert you when a message needs attention"
        }
    }

    var systemImage: String {
        switch self {
        case .fullDiskAccess: "internaldrive"
        case .contacts: "person.crop.circle"
        case .calendar: "calendar"
        case .notifications: "bell.badge"
        }
    }

    var isRequired: Bool {
        switch self {
        case .fullDiskAccess, .contacts: true
        case .calendar, .notifications: false
        }
    }
}

// MARK: - Permission Status

enum PermissionStatus: Equatable {
    case notDetermined
    case granted
    case denied
    case restricted

    var title: String {
        switch self {
        case .notDetermined: "Not determined"
        case .granted: "Granted"
        case .denied: "Denied"
        case .restricted: "Restricted"
        }
    }
}
