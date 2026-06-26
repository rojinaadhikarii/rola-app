import Foundation

// MARK: - Learning Engine

/// Applies approved/edited reply feedback to style profiles using incremental blending.
enum LearningEngine {

    /// Weight given to each new approved/edited message when updating traits.
    static let learningWeight = 0.2

    static func shouldLearn(from action: SuggestionAction) -> Bool {
        action == .approved || action == .edited
    }

    static func blend(existing: StyleTraits, sample: StyleTraits, weight: Double = learningWeight) -> StyleTraits {
        let retained = 1 - weight

        return StyleTraits(
            averageWordCount: existing.averageWordCount * retained + sample.averageWordCount * weight,
            averageCharacterCount: existing.averageCharacterCount * retained + sample.averageCharacterCount * weight,
            emojiRate: existing.emojiRate * retained + sample.emojiRate * weight,
            exclamationRate: existing.exclamationRate * retained + sample.exclamationRate * weight,
            questionRate: existing.questionRate * retained + sample.questionRate * weight,
            lowercaseRate: existing.lowercaseRate * retained + sample.lowercaseRate * weight,
            slangRate: existing.slangRate * retained + sample.slangRate * weight,
            topWords: mergeRanked(existing.topWords, sample.topWords, limit: 8),
            topEmojis: mergeRanked(existing.topEmojis, sample.topEmojis, limit: 5),
            commonGreetings: mergeRanked(existing.commonGreetings, sample.commonGreetings, limit: 4),
            commonSignOffs: mergeRanked(existing.commonSignOffs, sample.commonSignOffs, limit: 4),
            messageCount: existing.messageCount + 1
        )
    }

    static func traits(from text: String) -> StyleTraits {
        StyleAnalyzer.analyze(
            messages: [
                StyleMessageSample(
                    text: text,
                    chatId: 0,
                    displayName: "You",
                    isGroup: false
                ),
            ]
        )
    }

    static func updatedGlobalProfile(
        _ profile: StyleProfile,
        finalText: String
    ) -> StyleProfile {
        let sample = traits(from: finalText)
        return StyleProfile(
            id: profile.id,
            scope: profile.scope,
            chatId: profile.chatId,
            displayName: profile.displayName,
            relationship: profile.relationship,
            traits: blend(existing: profile.traits, sample: sample),
            analyzedAt: Date()
        )
    }

    static func updatedContactProfile(
        _ profile: StyleProfile,
        finalText: String
    ) -> StyleProfile {
        let sample = traits(from: finalText)
        return StyleProfile(
            id: profile.id,
            scope: profile.scope,
            chatId: profile.chatId,
            displayName: profile.displayName,
            relationship: profile.relationship,
            traits: blend(existing: profile.traits, sample: sample),
            analyzedAt: Date()
        )
    }

    static func newContactProfile(
        chatId: Int64,
        displayName: String,
        isGroup: Bool,
        finalText: String
    ) -> StyleProfile {
        let traits = self.traits(from: finalText)
        return StyleProfile.contact(
            chatId: chatId,
            displayName: displayName,
            isGroup: isGroup,
            traits: traits,
            analyzedAt: Date()
        )
    }

    // MARK: - Private

    private static func mergeRanked(_ existing: [String], _ incoming: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        var merged: [String] = []

        for item in existing + incoming where !item.isEmpty {
            let key = item.lowercased()
            guard seen.insert(key).inserted else { continue }
            merged.append(item)
            if merged.count >= limit { break }
        }

        return merged
    }
}
