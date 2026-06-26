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

    func testAppleDateConverterNanoseconds() {
        let date = AppleDateConverter.date(fromAppleTimestamp: 700_000_000_000_000_000)
        XCTAssertNotNil(date)
        XCTAssertGreaterThan(date!, Date(timeIntervalSinceReferenceDate: 0))
    }

    func testAppleDateConverterSeconds() {
        let date = AppleDateConverter.date(fromAppleTimestamp: 700_000_000)
        XCTAssertNotNil(date)
    }

    func testConversationDisplayNameResolution() {
        let name = Conversation.resolveDisplayName(
            displayName: nil,
            chatIdentifier: "+15551234567",
            handles: ["+15551234567"],
            isGroup: false
        )
        XCTAssertEqual(name, "+15551234567")
    }

    func testConversationNeedsReplyFromRow() {
        let row = RawConversationRow(
            chatId: 1,
            guid: "g1",
            chatIdentifier: "+1",
            displayName: "Alex",
            serviceName: "iMessage",
            style: 0,
            lastMessageId: 10,
            lastMessageText: "Hello?",
            lastAttributedBody: nil,
            lastMessageDate: 700_000_000_000_000_000,
            lastMessageIsFromMe: false,
            lastMessageDateRead: 0,
            participantHandles: ["+15551234567"]
        )
        let conversation = Conversation(row: row)
        XCTAssertTrue(conversation.needsReply)
        XCTAssertEqual(conversation.displayName, "Alex")
    }

    func testChatDBReaderFixture() throws {
        let fixtureURL = Bundle(for: ROLATests.self)
            .url(forResource: "chat_fixture", withExtension: "db", subdirectory: "Fixtures")
        let path = fixtureURL?.path ?? fixturePathInRepo()
        let reader = ChatDBReader(databasePath: path)

        let conversations = try reader.fetchConversations(limit: 10)
        XCTAssertEqual(conversations.count, 2)

        let needsReply = conversations.filter { !$0.lastMessageIsFromMe && ($0.lastMessageDateRead == nil || $0.lastMessageDateRead == 0) }
        XCTAssertFalse(needsReply.isEmpty)

        let messages = try reader.fetchRecentMessages(chatId: 1, limit: 10)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages.last?.text, "Great to hear!")
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

    @MainActor
    func testConversationStoreMockImport() async {
        let store = ConversationStore(importService: MockMessageImportService())
        await store.importConversations()
        XCTAssertEqual(store.conversations.count, 3)
        XCTAssertEqual(store.needsAttention.count, 2)
    }

    func testStyleAnalyzerEmojiDetection() {
        let samples = [
            StyleMessageSample(text: "I'd be down 😂", chatId: 1, displayName: "Alex", isGroup: false),
            StyleMessageSample(text: "sounds good!", chatId: 1, displayName: "Alex", isGroup: false),
            StyleMessageSample(text: "hey what's up", chatId: 1, displayName: "Alex", isGroup: false),
            StyleMessageSample(text: "lol yeah", chatId: 1, displayName: "Alex", isGroup: false),
            StyleMessageSample(text: "see you tomorrow", chatId: 1, displayName: "Alex", isGroup: false),
        ]

        let traits = StyleAnalyzer.analyze(messages: samples)
        XCTAssertGreaterThan(traits.emojiRate, 0)
        XCTAssertGreaterThan(traits.slangRate, 0)
        XCTAssertFalse(traits.topEmojis.isEmpty)
    }

    func testStyleAnalyzerBuildsContactProfiles() {
        var samples: [StyleMessageSample] = []
        for index in 0..<6 {
            samples.append(
                StyleMessageSample(
                    text: "hey mom love you ❤️",
                    chatId: 2,
                    displayName: "Mom",
                    isGroup: false
                )
            )
        }
        for index in 0..<6 {
            samples.append(
                StyleMessageSample(
                    text: "That works for me. Thanks!",
                    chatId: 3,
                    displayName: "Boss",
                    isGroup: false
                )
            )
        }
        for index in 0..<10 {
            samples.append(
                StyleMessageSample(
                    text: "yeah sounds good 😂",
                    chatId: 1,
                    displayName: "Alex",
                    isGroup: false
                )
            )
        }

        let result = StyleAnalyzer.buildProfiles(from: samples)
        XCTAssertGreaterThanOrEqual(result.globalProfile.traits.messageCount, 10)
        XCTAssertEqual(result.contactProfiles.count, 2)
        XCTAssertTrue(result.contactProfiles.contains { $0.relationship == .family })
    }

    func testRelationshipCategoryInference() {
        XCTAssertEqual(RelationshipCategory.infer(displayName: "Mom", isGroup: false), .family)
        XCTAssertEqual(RelationshipCategory.infer(displayName: "Work Team", isGroup: true), .work)
    }

    func testOutgoingMessagesFixture() throws {
        let path = fixturePathInRepo()
        let reader = ChatDBReader(databasePath: path)
        let outgoing = try reader.fetchOutgoingMessages(limit: 50)
        XCTAssertGreaterThanOrEqual(outgoing.count, 10)
    }

    @MainActor
    func testStyleProfileStoreMockAnalysis() async {
        let store = StyleProfileStore(styleEngine: MockStyleEngine())
        await store.analyze()
        XCTAssertTrue(store.hasProfile)
        XCTAssertEqual(store.contactProfiles.count, 3)
    }

    private func fixturePathInRepo() -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/chat_fixture.db")
            .path
    }
}
