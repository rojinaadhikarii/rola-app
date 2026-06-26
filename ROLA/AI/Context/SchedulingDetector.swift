import Foundation

// MARK: - Scheduling Detector

/// Detects scheduling-related language in messages.
enum SchedulingDetector {

    private static let schedulingKeywords = [
        "free", "available", "dinner", "lunch", "coffee", "meet", "meeting",
        "hang", "grab", "drinks", "plans", "schedule", "busy", "thursday",
        "friday", "saturday", "sunday", "monday", "tuesday", "wednesday",
        "tomorrow", "tonight", "this weekend", "next week",
    ]

    static func isSchedulingRelated(_ text: String) -> Bool {
        let lower = text.lowercased()
        return schedulingKeywords.contains { lower.contains($0) }
    }

    static func referencedDate(in text: String, from reference: Date = Date()) -> Date? {
        let lower = text.lowercased()
        let calendar = Calendar.current

        if lower.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: reference))
        }
        if lower.contains("tonight") || lower.contains("today") {
            return calendar.startOfDay(for: reference)
        }

        let weekdays: [(name: String, weekday: Int)] = [
            ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7),
        ]

        for (name, weekday) in weekdays where lower.contains(name) {
            return nextOccurrence(of: weekday, from: reference, calendar: calendar)
        }

        return nil
    }

    private static func nextOccurrence(
        of weekday: Int,
        from reference: Date,
        calendar: Calendar
    ) -> Date? {
        var components = DateComponents()
        components.weekday = weekday
        return calendar.nextDate(
            after: reference,
            matching: components,
            matchingPolicy: .nextTimePreservingSmallerComponents
        ).map { calendar.startOfDay(for: $0) }
    }
}
