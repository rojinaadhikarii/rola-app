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
}
