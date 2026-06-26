import Foundation

// MARK: - Prompt Builder

enum PromptBuilder {

    static func systemPrompt() -> String {
        """
        You are ROLA, an AI relationship copilot. Your job is to draft a text message reply \
        that sounds EXACTLY like the user — not like an AI assistant.

        Rules:
        - Sound natural, human, and casual (unless the user's style is formal).
        - Match the user's typical message length, emoji usage, and tone.
        - Adapt tone based on who they're talking to (friend vs family vs work).
        - Use calendar context when the message involves scheduling.
        - NEVER mention that you are AI.
        - NEVER be overly formal, verbose, or robotic.
        - Keep replies concise — most texts are 1-2 sentences.
        - Return valid JSON only.
        """
    }

    static func userPrompt(for request: SuggestionRequest) -> String {
        let conversation = request.conversation
        let messages = request.messages
        let lastIncoming = messages.last(where: { !$0.isFromMe })
            ?? messages.last

        let history = messages.suffix(8).map { msg in
            let sender = msg.isFromMe ? "You" : conversation.displayName
            return "\(sender): \(msg.text)"
        }.joined(separator: "\n")

        var contextParts: [String] = []

        contextParts.append("Contact: \(conversation.displayName)")
        contextParts.append("Relationship: \(relationshipLabel(for: request.contactStyle))")

        if let global = request.globalStyle {
            contextParts.append("Your general style: \(global.traits.toneSummary).")
            if !global.traits.topEmojis.isEmpty {
                contextParts.append("Your common emoji: \(global.traits.topEmojis.joined(separator: " ")).")
            }
        }

        if let contact = request.contactStyle {
            contextParts.append("Your style with \(contact.displayName ?? "them"): \(contact.traits.toneSummary).")
            if !contact.traits.commonGreetings.isEmpty {
                contextParts.append("Greetings you use: \(contact.traits.commonGreetings.joined(separator: ", ")).")
            }
        }

        if let calendar = request.calendarContext, calendar.hasCalendarAccess {
            contextParts.append(ContextAssembler.buildAIContext(
                message: lastIncoming?.text ?? "",
                calendarContext: calendar,
                styleProfile: nil
            ))
        }

        let timeOfDay = TimeOfDay.current.label
        contextParts.append("Time of day: \(timeOfDay).")

        return """
        \(contextParts.joined(separator: "\n"))

        Recent conversation:
        \(history)

        Draft a reply to the last message from \(conversation.displayName).

        Respond with JSON:
        {
          "reply": "your suggested reply text",
          "confidence": 0.0 to 1.0,
          "reasoning": "brief explanation of tone choices"
        }
        """
    }

    private static func relationshipLabel(for profile: StyleProfile?) -> String {
        profile?.relationship.title ?? "Contact"
    }
}

// MARK: - Time of Day

enum TimeOfDay {
    case morning
    case afternoon
    case evening
    case night

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    var label: String {
        switch self {
        case .morning: "morning"
        case .afternoon: "afternoon"
        case .evening: "evening"
        case .night: "night"
        }
    }
}
