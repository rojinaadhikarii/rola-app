import Contacts
import EventKit
import XCTest
@testable import ROLA

final class ROLATests: XCTestCase {
    func testOnboardingStepCount() {
        XCTAssertEqual(OnboardingStep.allCases.count, 3)
    }

    func testPermissionTypes() {
        XCTAssertEqual(PermissionType.allCases.count, 4)
        XCTAssertTrue(PermissionType.fullDiskAccess.isRequired)
        XCTAssertFalse(PermissionType.calendar.isRequired)
    }

    func testKeychainRoundTrip() throws {
        let testKey = "sk-test-\(UUID().uuidString)"
        try KeychainHelper.save(testKey, for: .openAIAPIKey)
        XCTAssertEqual(KeychainHelper.load(for: .openAIAPIKey), testKey)
        KeychainHelper.delete(for: .openAIAPIKey)
        XCTAssertNil(KeychainHelper.load(for: .openAIAPIKey))
    }

    func testContactsAuthorizationMapping() {
        XCTAssertEqual(PermissionStatusMapper.from(contacts: .authorized), .granted)
        XCTAssertEqual(PermissionStatusMapper.from(contacts: .denied), .denied)
        XCTAssertEqual(PermissionStatusMapper.from(contacts: .notDetermined), .notDetermined)
    }

    func testCalendarAuthorizationMapping() {
        XCTAssertEqual(PermissionStatusMapper.from(calendar: .fullAccess), .granted)
        XCTAssertEqual(PermissionStatusMapper.from(calendar: .writeOnly), .denied)
        XCTAssertEqual(PermissionStatusMapper.from(calendar: .notDetermined), .notDetermined)
    }

    func testFullDiskAccessCheckerWithMissingFile() {
        let missingPath = "/tmp/rola-nonexistent-chat-\(UUID().uuidString).db"
        XCTAssertFalse(FullDiskAccessChecker.canReadMessagesDatabase(at: missingPath))
    }

    @MainActor
    func testPermissionManagerRefreshUsesServices() async {
        let contacts = MockContactsService()
        let calendar = MockCalendarService()
        let notifications = MockNotificationService()
        let manager = PermissionManager(
            contactsService: contacts,
            calendarService: calendar,
            notificationService: notifications
        )

        await manager.refreshAllStatuses()
        XCTAssertEqual(manager.status(for: .contacts), .notDetermined)
        XCTAssertEqual(manager.status(for: .calendar), .notDetermined)
    }
}
