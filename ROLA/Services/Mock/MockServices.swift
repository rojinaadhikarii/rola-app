import Foundation

// MARK: - Mock Services (Milestone 1)

struct MockMessageImportService: MessageImportServiceProtocol {
    func importConversations(onProgress: (@Sendable (Double) -> Void)?) async throws -> [Conversation] {
        onProgress?(0.5)
        try await Task.sleep(for: .milliseconds(300))
        onProgress?(1.0)
        return MockConversationData.sample
    }

    func fetchRecentMessages(chatId: Int64, limit: Int) async throws -> [ImportedMessage] {
        MockConversationData.messages(for: chatId)
    }
}

enum MockConversationData {
    static let sample: [Conversation] = [
        Conversation(
            id: 1,
            guid: "mock-1",
            displayName: "Alex Kim",
            participantHandles: ["+15551234567"],
            serviceName: "iMessage",
            isGroup: false,
            lastMessageText: "Are you free Thursday?",
            lastMessageDate: Date().addingTimeInterval(-3600),
            lastMessageIsFromMe: false,
            needsReply: true
        ),
        Conversation(
            id: 2,
            guid: "mock-2",
            displayName: "Mom",
            participantHandles: ["+15559876543"],
            serviceName: "iMessage",
            isGroup: false,
            lastMessageText: "Did you make it home?",
            lastMessageDate: Date().addingTimeInterval(-7200),
            lastMessageIsFromMe: false,
            needsReply: true
        ),
        Conversation(
            id: 3,
            guid: "mock-3",
            displayName: "Work Team",
            participantHandles: ["+15551112222", "+15553334444"],
            serviceName: "iMessage",
            isGroup: true,
            lastMessageText: "Sounds good, thanks!",
            lastMessageDate: Date().addingTimeInterval(-86400),
            lastMessageIsFromMe: true,
            needsReply: false
        ),
    ]

    static func messages(for chatId: Int64) -> [ImportedMessage] {
        switch chatId {
        case 1:
            return [
                ImportedMessage(
                    id: 101, chatId: 1, text: "Hey! Long time no see",
                    date: Date().addingTimeInterval(-7200), isFromMe: false, handleIdentifier: "+15551234567"
                ),
                ImportedMessage(
                    id: 102, chatId: 1, text: "I know, it's been crazy!",
                    date: Date().addingTimeInterval(-5400), isFromMe: true, handleIdentifier: nil
                ),
                ImportedMessage(
                    id: 103, chatId: 1, text: "Are you free Thursday?",
                    date: Date().addingTimeInterval(-3600), isFromMe: false, handleIdentifier: "+15551234567"
                ),
            ]
        default:
            return []
        }
    }
}

struct MockStyleEngine: StyleEngineProtocol {
    func analyzeStyle(onProgress: (@Sendable (Double) -> Void)?) async throws -> StyleAnalysisResult {
        onProgress?(0.5)
        try await Task.sleep(for: .milliseconds(200))
        onProgress?(1.0)
        return MockStyleData.sampleResult
    }
}

enum MockStyleData {
    static let sampleResult: StyleAnalysisResult = {
        let globalTraits = StyleTraits(
            averageWordCount: 8.2,
            averageCharacterCount: 42,
            emojiRate: 0.35,
            exclamationRate: 0.2,
            questionRate: 0.15,
            lowercaseRate: 0.7,
            slangRate: 0.18,
            topWords: ["yeah", "sounds", "love", "down", "tomorrow"],
            topEmojis: ["😂", "❤️", "👍"],
            commonGreetings: ["hey", "hi"],
            commonSignOffs: ["thanks", "sounds good"],
            messageCount: 248
        )

        let momTraits = StyleTraits(
            averageWordCount: 4.5,
            averageCharacterCount: 22,
            emojiRate: 0.6,
            exclamationRate: 0.1,
            questionRate: 0.05,
            lowercaseRate: 0.5,
            slangRate: 0.05,
            topWords: ["yep", "home", "love"],
            topEmojis: ["❤️", "🏠"],
            commonGreetings: ["hey"],
            commonSignOffs: ["love you"],
            messageCount: 64
        )

        let bossTraits = StyleTraits(
            averageWordCount: 11.0,
            averageCharacterCount: 58,
            emojiRate: 0.02,
            exclamationRate: 0.05,
            questionRate: 0.1,
            lowercaseRate: 0.1,
            slangRate: 0.0,
            topWords: ["works", "thanks", "meeting", "schedule"],
            topEmojis: [],
            commonGreetings: ["hi"],
            commonSignOffs: ["thanks"],
            messageCount: 42
        )

        return StyleAnalysisResult(
            globalProfile: .global(traits: globalTraits),
            contactProfiles: [
                .contact(chatId: 2, displayName: "Mom", isGroup: false, traits: momTraits),
                .contact(chatId: 1, displayName: "Alex Kim", isGroup: false, traits: globalTraits),
                .contact(chatId: 3, displayName: "Work Team", isGroup: true, traits: bossTraits),
            ],
            analyzedAt: Date(),
            totalMessagesAnalyzed: 248
        )
    }()
}

struct MockAIPipeline: AIPipelineProtocol {
    let suggestionStore: SuggestionStore

    func generateReplySuggestion(
        conversation: Conversation,
        messages: [ImportedMessage],
        incomingMessage: ImportedMessage,
        globalStyle: StyleProfile?,
        contactStyle: StyleProfile?,
        calendarContext: CalendarContext?
    ) async throws -> ReplySuggestion {
        try await Task.sleep(for: .milliseconds(400))

        if let existing = suggestionStore.pendingSuggestion(
            chatId: conversation.id,
            messageId: incomingMessage.id
        ) {
            return existing
        }

        let suggestion = ReplySuggestion(
            id: UUID(),
            chatId: conversation.id,
            incomingMessageId: incomingMessage.id,
            incomingMessageText: incomingMessage.text,
            replyText: "Yeah, that works for me!",
            confidence: 0.82,
            reasoning: "Casual affirmative matching your typical tone.",
            status: .pending,
            safetyBlocked: false,
            safetyReason: nil,
            createdAt: Date()
        )
        suggestionStore.save(suggestion)
        return suggestion
    }

    func approveSuggestion(_ suggestion: ReplySuggestion, editedText: String?) {
        var updated = suggestion
        updated.status = editedText != nil ? .edited : .approved
        updated.editedText = editedText
        suggestionStore.save(updated)
    }

    func dismissSuggestion(_ suggestion: ReplySuggestion) {
        var updated = suggestion
        updated.status = .dismissed
        suggestionStore.save(updated)
    }
}

@MainActor
final class MockCalendarService: CalendarServiceProtocol {
    var grantsAccess: Bool

    init(grantsAccess: Bool = true) {
        self.grantsAccess = grantsAccess
    }

    func requestAccess() async -> PermissionStatus {
        grantsAccess ? .granted : .denied
    }

    func authorizationStatus() -> PermissionStatus {
        grantsAccess ? .granted : .notDetermined
    }

    func fetchContext() async throws -> CalendarContext {
        grantsAccess ? MockCalendarData.sampleContext : CalendarContext(
            fetchedAt: Date(),
            today: AvailabilityChecker.dayAvailability(for: Date(), events: []),
            week: [],
            hasCalendarAccess: false
        )
    }

    func isAvailable(from start: Date, to end: Date) async -> Bool {
        let context = try await fetchContext()
        return AvailabilityChecker.isAvailable(from: start, to: end, on: context.today)
    }
}

enum MockCalendarData {
    static var sampleContext: CalendarContext {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func time(hour: Int, minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
        }

        let todayEvents: [CalendarEventItem] = [
            CalendarEventItem(
                id: "evt-1",
                title: "Team Standup",
                startDate: time(hour: 9),
                endDate: time(hour: 9, minute: 30),
                isAllDay: false,
                location: "Zoom"
            ),
            CalendarEventItem(
                id: "evt-2",
                title: "Product Review",
                startDate: time(hour: 14),
                endDate: time(hour: 15),
                isAllDay: false,
                location: nil
            ),
            CalendarEventItem(
                id: "evt-3",
                title: "Dinner with Sarah",
                startDate: time(hour: 18),
                endDate: time(hour: 22),
                isAllDay: false,
                location: "Downtown"
            ),
        ]

        let todayAvailability = AvailabilityChecker.dayAvailability(for: today, events: todayEvents)

        guard let thursday = calendar.date(byAdding: .day, value: 1, to: today) else {
            return CalendarContext(
                fetchedAt: Date(),
                today: todayAvailability,
                week: [todayAvailability],
                hasCalendarAccess: true
            )
        }

        let thursdayEvents = [
            CalendarEventItem(
                id: "evt-4",
                title: "Client Call",
                startDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: thursday)!,
                endDate: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: thursday)!,
                isAllDay: false,
                location: nil
            ),
        ]
        let thursdayAvailability = AvailabilityChecker.dayAvailability(for: thursday, events: thursdayEvents)

        return CalendarContext(
            fetchedAt: Date(),
            today: todayAvailability,
            week: [todayAvailability, thursdayAvailability],
            hasCalendarAccess: true
        )
    }
}

@MainActor
final class MockContactsService: ContactsServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
}

@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    func requestAccess() async -> PermissionStatus { .notDetermined }
    func authorizationStatus() -> PermissionStatus { .notDetermined }
    func refreshAuthorizationStatus() async -> PermissionStatus { .notDetermined }
}

// MARK: - Keychain API Key Store

struct KeychainAPIKeyStore: APIKeyStoreProtocol {
    func saveOpenAIKey(_ key: String) throws {
        try KeychainHelper.save(key, for: .openAIAPIKey)
    }

    func loadOpenAIKey() -> String? {
        KeychainHelper.load(for: .openAIAPIKey)
    }

    func deleteOpenAIKey() {
        KeychainHelper.delete(for: .openAIAPIKey)
    }

    var hasOpenAIKey: Bool {
        KeychainHelper.hasValue(for: .openAIAPIKey)
    }
}
