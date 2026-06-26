import Foundation

// MARK: - Style Scope

enum StyleScope: String, Codable, Hashable, Sendable {
    case global
    case contact
}

// MARK: - Relationship Category

enum RelationshipCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case family
    case friend
    case work
    case other

    var title: String {
        switch self {
        case .family: "Family"
        case .friend: "Friends"
        case .work: "Work"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .family: "house.fill"
        case .friend: "person.2.fill"
        case .work: "briefcase.fill"
        case .other: "person.fill"
        }
    }

    static func infer(displayName: String, isGroup: Bool) -> RelationshipCategory {
        let lower = displayName.lowercased()
        let familyKeywords = [
            "mom", "dad", "mother", "father", "mama", "papa",
            "sister", "brother", "grandma", "grandpa", "aunt", "uncle", "family",
        ]
        if familyKeywords.contains(where: { lower.contains($0) }) {
            return .family
        }
        if lower.contains("team") || lower.contains("work") || lower.contains("office")
            || lower.contains("boss") || lower.contains("manager") {
            return .work
        }
        if isGroup {
            return .friend
        }
        return .other
    }
}

// MARK: - Style Traits

struct StyleTraits: Codable, Hashable, Sendable {
    var averageWordCount: Double
    var averageCharacterCount: Double
    var emojiRate: Double
    var exclamationRate: Double
    var questionRate: Double
    var lowercaseRate: Double
    var slangRate: Double
    var topWords: [String]
    var topEmojis: [String]
    var commonGreetings: [String]
    var commonSignOffs: [String]
    var messageCount: Int

    static let empty = StyleTraits(
        averageWordCount: 0,
        averageCharacterCount: 0,
        emojiRate: 0,
        exclamationRate: 0,
        questionRate: 0,
        lowercaseRate: 0,
        slangRate: 0,
        topWords: [],
        topEmojis: [],
        commonGreetings: [],
        commonSignOffs: [],
        messageCount: 0
    )

    var toneSummary: String {
        var parts: [String] = []

        if averageWordCount < 6 {
            parts.append("brief")
        } else if averageWordCount > 15 {
            parts.append("detailed")
        }

        if emojiRate > 0.5 {
            parts.append("expressive with emoji")
        } else if emojiRate < 0.1 {
            parts.append("text-focused")
        }

        if lowercaseRate > 0.6 {
            parts.append("casual lowercase")
        }

        if slangRate > 0.2 {
            parts.append("playful")
        }

        if exclamationRate > 0.3 {
            parts.append("enthusiastic")
        }

        return parts.isEmpty ? "balanced" : parts.joined(separator: ", ")
    }
}

// MARK: - Style Profile

struct StyleProfile: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let scope: StyleScope
    let chatId: Int64?
    let displayName: String?
    let relationship: RelationshipCategory
    let traits: StyleTraits
    let analyzedAt: Date

    static func global(traits: StyleTraits, analyzedAt: Date = Date()) -> StyleProfile {
        StyleProfile(
            id: "global",
            scope: .global,
            chatId: nil,
            displayName: "You",
            relationship: .other,
            traits: traits,
            analyzedAt: analyzedAt
        )
    }

    static func contact(
        chatId: Int64,
        displayName: String,
        isGroup: Bool,
        traits: StyleTraits,
        analyzedAt: Date = Date()
    ) -> StyleProfile {
        StyleProfile(
            id: "contact:\(chatId)",
            scope: .contact,
            chatId: chatId,
            displayName: displayName,
            relationship: RelationshipCategory.infer(displayName: displayName, isGroup: isGroup),
            traits: traits,
            analyzedAt: analyzedAt
        )
    }
}

// MARK: - Style Analysis Result

struct StyleAnalysisResult: Codable, Hashable, Sendable {
    let globalProfile: StyleProfile
    let contactProfiles: [StyleProfile]
    let analyzedAt: Date
    let totalMessagesAnalyzed: Int

    var profilesByRelationship: [RelationshipCategory: [StyleProfile]] {
        Dictionary(grouping: contactProfiles, by: \.relationship)
    }
}
