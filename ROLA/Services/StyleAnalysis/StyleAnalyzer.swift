import Foundation

// MARK: - Style Message Sample

struct StyleMessageSample: Sendable {
    let text: String
    let chatId: Int64
    let displayName: String
    let isGroup: Bool
}

// MARK: - Style Analyzer

/// Heuristic analysis of outgoing message text — no ML required for MVP.
enum StyleAnalyzer {

    static let minimumGlobalMessages = 10
    static let minimumContactMessages = 5

    private static let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "is", "it", "i", "you", "me", "my", "your", "we", "they", "that",
        "this", "with", "was", "are", "be", "have", "has", "had", "do", "did",
        "so", "if", "not", "no", "yes", "ok", "okay", "yeah", "yep", "nah",
        "im", "ive", "ill", "youre", "dont", "cant", "wont", "its", "thats",
    ]

    private static let greetingPatterns = [
        "hey", "hi", "hello", "yo", "sup", "morning", "evening", "hiya", "heya",
    ]

    private static let signOffPatterns = [
        "thanks", "thank you", "thx", "ty", "ttyl", "bye", "later", "love you",
        "see you", "talk soon", "cheers", "np", "sounds good", "perfect",
    ]

    private static let slangPatterns = [
        "lol", "lmao", "haha", "hehe", "omg", "tbh", "imo", "idk", "nvm", "fr",
    ]

    static func analyze(messages: [StyleMessageSample]) -> StyleTraits {
        let texts = messages.map(\.text).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !texts.isEmpty else { return .empty }

        let wordCounts = texts.map { wordCount(in: $0) }
        let charCounts = texts.map { $0.count }

        let emojiCounts = texts.map { countEmojis(in: $0) }
        let exclamationCounts = texts.map { $0.filter { $0 == "!" }.count }
        let questionCounts = texts.map { $0.filter { $0 == "?" }.count }
        let lowercaseCounts = texts.filter { isMostlyLowercase($0) }.count
        let slangCounts = texts.map { countSlang(in: $0) }

        let allWords = texts.flatMap { tokenize($0) }
        let topWords = topElements(in: allWords, limit: 8)

        let allEmojis = texts.flatMap { extractEmojis(from: $0) }
        let topEmojis = topElements(in: allEmojis, limit: 5)

        let greetings = detectPatterns(in: texts, patterns: greetingPatterns, position: .start)
        let signOffs = detectPatterns(in: texts, patterns: signOffPatterns, position: .end)

        let count = texts.count

        return StyleTraits(
            averageWordCount: Double(wordCounts.reduce(0, +)) / Double(count),
            averageCharacterCount: Double(charCounts.reduce(0, +)) / Double(count),
            emojiRate: Double(emojiCounts.reduce(0, +)) / Double(count),
            exclamationRate: Double(exclamationCounts.filter { $0 > 0 }.count) / Double(count),
            questionRate: Double(questionCounts.filter { $0 > 0 }.count) / Double(count),
            lowercaseRate: Double(lowercaseCounts) / Double(count),
            slangRate: Double(slangCounts.filter { $0 > 0 }.count) / Double(count),
            topWords: topWords,
            topEmojis: topEmojis,
            commonGreetings: greetings,
            commonSignOffs: signOffs,
            messageCount: count
        )
    }

    static func buildProfiles(from messages: [StyleMessageSample]) -> StyleAnalysisResult {
        let analyzedAt = Date()
        let globalTraits = analyze(messages: messages)

        let grouped = Dictionary(grouping: messages, by: \.chatId)
        var contactProfiles: [StyleProfile] = []

        for (chatId, chatMessages) in grouped {
            guard chatMessages.count >= minimumContactMessages else { continue }
            let displayName = chatMessages.first?.displayName ?? "Contact"
            let isGroup = chatMessages.first?.isGroup ?? false
            let traits = analyze(messages: chatMessages)
            contactProfiles.append(
                StyleProfile.contact(
                    chatId: chatId,
                    displayName: displayName,
                    isGroup: isGroup,
                    traits: traits,
                    analyzedAt: analyzedAt
                )
            )
        }

        contactProfiles.sort { $0.traits.messageCount > $1.traits.messageCount }

        return StyleAnalysisResult(
            globalProfile: .global(traits: globalTraits, analyzedAt: analyzedAt),
            contactProfiles: contactProfiles,
            analyzedAt: analyzedAt,
            totalMessagesAnalyzed: messages.count
        )
    }

    // MARK: - Tokenization

    private static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }

    private static func wordCount(in text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    private static func topElements(in elements: [String], limit: Int) -> [String] {
        var counts: [String: Int] = [:]
        for element in elements {
            counts[element, default: 0] += 1
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    // MARK: - Emoji

    private static func extractEmojis(from text: String) -> [String] {
        text.unicodeScalars
            .filter { $0.properties.isEmoji && ($0.value > 0x238C || $0.properties.isEmojiPresentation) }
            .map { String($0) }
    }

    private static func countEmojis(in text: String) -> Int {
        extractEmojis(from: text).count
    }

    // MARK: - Style Signals

    private static func isMostlyLowercase(_ text: String) -> Bool {
        let letters = text.filter(\.isLetter)
        guard !letters.isEmpty else { return false }
        let lowercase = letters.filter(\.isLowercase).count
        return Double(lowercase) / Double(letters.count) > 0.8
    }

    private static func countSlang(in text: String) -> Int {
        let lower = text.lowercased()
        return slangPatterns.filter { lower.contains($0) }.count
    }

    private enum PatternPosition {
        case start
        case end
    }

    private static func detectPatterns(
        in texts: [String],
        patterns: [String],
        position: PatternPosition
    ) -> [String] {
        var counts: [String: Int] = [:]

        for text in texts {
            let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            for pattern in patterns {
                let matches: Bool = switch position {
                case .start:
                    lower.hasPrefix(pattern) || lower.contains(" \(pattern)")
                case .end:
                    lower.hasSuffix(pattern) || lower.contains("\(pattern)!") || lower.contains("\(pattern).")
                }
                if matches {
                    counts[pattern, default: 0] += 1
                }
            }
        }

        return counts
            .sorted { $0.value > $1.value }
            .prefix(4)
            .map(\.key)
    }
}
