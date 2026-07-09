import Foundation

// MARK: - Context Assembler

/// Assembles multi-source context for AI reply generation (Milestone 6).
enum ContextAssembler {

    static func schedulingHint(
        for message: String,
        context: CalendarContext?
    ) -> String? {
        guard SchedulingDetector.isSchedulingRelated(message),
              let context,
              context.hasCalendarAccess
        else { return nil }

        if let referencedDay = SchedulingDetector.referencedDate(in: message) {
            let calendar = Calendar.current
            let day = context.week.first {
                calendar.isDate($0.date, inSameDayAs: referencedDay)
            } ?? context.today

            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"

            if day.events.isEmpty {
                return "Your calendar shows you're free on \(formatter.string(from: day.date))."
            }

            let busyRanges = day.events
                .filter { !$0.isAllDay }
                .map { "\($0.formattedTimeRange) (\($0.title))" }

            if busyRanges.isEmpty {
                return "You have all-day events on \(formatter.string(from: day.date)) but no timed conflicts."
            }

            return "On \(formatter.string(from: day.date)), you're busy: \(busyRanges.joined(separator: ", "))."
        }

        if context.today.events.isEmpty {
            return "Nothing on your calendar today."
        }

        let count = context.today.events.count
        return "You have \(count) event\(count == 1 ? "" : "s") on your calendar today."
    }

    static func buildAIContext(
        message: String,
        calendarContext: CalendarContext?,
        styleProfile: StyleProfile?
    ) -> String {
        var parts: [String] = []

        if let calendarContext {
            parts.append("Calendar: \(calendarContext.promptSummary)")
        }

        if let hint = schedulingHint(for: message, context: calendarContext) {
            parts.append("Scheduling: \(hint)")
        }

        if let styleProfile {
            parts.append("Writing style: \(styleProfile.traits.toneSummary).")
        }

        return parts.joined(separator: "\n")
    }
}
