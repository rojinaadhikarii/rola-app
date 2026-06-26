import Foundation

// MARK: - Safety Category

enum SafetyCategory: String, Sendable {
    case emergency
    case medical
    case financial
    case legal
    case relationship
    case sensitive
    case unknownContact
}

// MARK: - Safety Check Result

struct SafetyCheckResult: Sendable {
    let isBlocked: Bool
    let category: SafetyCategory?
    let reason: String?
    let confidencePenalty: Double

    static let passed = SafetyCheckResult(
        isBlocked: false,
        category: nil,
        reason: nil,
        confidencePenalty: 0
    )
}

// MARK: - Safety Classifier

/// Rule-based safety gate — blocks sensitive topics from automatic suggestions.
enum SafetyClassifier {

    private static let blockedPatterns: [(category: SafetyCategory, keywords: [String])] = [
        (.emergency, ["911", "emergency", "urgent help", "accident", "hospital", "ambulance", "dying"]),
        (.medical, ["diagnosis", "prescription", "symptoms", "pregnant", "suicide", "depression", "therapist", "medication"]),
        (.financial, ["wire transfer", "bank account", "investment", "loan", "debt", "bitcoin", "crypto", "irs", "tax fraud"]),
        (.legal, ["lawyer", "attorney", "lawsuit", "court", "subpoena", "legal action", "sue"]),
        (.relationship, ["break up", "breakup", "divorce", "cheating", "affair", "separation"]),
        (.sensitive, ["funeral", "passed away", "died", "miscarriage", "abuse", "assault"]),
    ]

    static func preCheck(
        message: String,
        conversation: Conversation
    ) -> SafetyCheckResult {
        let lower = message.lowercased()

        for pattern in blockedPatterns {
            if pattern.keywords.contains(where: { lower.contains($0) }) {
                return SafetyCheckResult(
                    isBlocked: true,
                    category: pattern.category,
                    reason: blockReason(for: pattern.category),
                    confidencePenalty: 1
                )
            }
        }

        if conversation.displayName == "Unknown" || conversation.participantHandles.isEmpty {
            return SafetyCheckResult(
                isBlocked: true,
                category: .unknownContact,
                reason: "ROLA doesn't suggest replies for unknown contacts.",
                confidencePenalty: 1
            )
        }

        return .passed
    }

    static func postCheck(
        reply: String,
        confidence: Double
    ) -> SafetyCheckResult {
        let lower = reply.lowercased()

        let aiDisclosurePhrases = [
            "as an ai", "as a language model", "i'm an ai", "i cannot",
        ]
        if aiDisclosurePhrases.contains(where: { lower.contains($0) }) {
            return SafetyCheckResult(
                isBlocked: true,
                category: .sensitive,
                reason: "The suggestion didn't sound natural. Please write this one yourself.",
                confidencePenalty: 1
            )
        }

        if confidence < 0.3 {
            return SafetyCheckResult(
                isBlocked: false,
                category: nil,
                reason: "Low confidence — please review carefully.",
                confidencePenalty: 0
            )
        }

        return .passed
    }

    private static func blockReason(for category: SafetyCategory) -> String {
        switch category {
        case .emergency:
            "This looks like an emergency. Please respond personally right away."
        case .medical:
            "Medical conversations need a personal, thoughtful reply from you."
        case .financial:
            "Financial messages are too sensitive for AI suggestions."
        case .legal:
            "Legal matters should be handled with a personal response."
        case .relationship:
            "This conversation is too sensitive for AI suggestions."
        case .sensitive:
            "This is a sensitive topic. ROLA won't suggest a reply."
        case .unknownContact:
            "ROLA doesn't suggest replies for unknown contacts."
        }
    }
}
