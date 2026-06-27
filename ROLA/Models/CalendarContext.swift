import Foundation

// MARK: - Calendar Event Item

struct CalendarEventItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?

    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    var formattedTimeRange: String {
        if isAllDay { return "All day" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}

// MARK: - Availability Window

struct AvailabilityWindow: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let start: Date
    let end: Date

    init(start: Date, end: Date) {
        self.id = UUID()
        self.start = start
        self.end = end
    }

    var formattedRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }
}

// MARK: - Day Availability

struct DayAvailability: Codable, Hashable, Sendable {
    let date: Date
    let events: [CalendarEventItem]
    let freeWindows: [AvailabilityWindow]

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    func isBusy(at moment: Date) -> Bool {
        events.contains { event in
            !event.isAllDay && moment >= event.startDate && moment < event.endDate
        }
    }

    func conflictingEvent(at moment: Date) -> CalendarEventItem? {
        events.first { event in
            !event.isAllDay && moment >= event.startDate && moment < event.endDate
        }
    }
}

// MARK: - Calendar Context

struct CalendarContext: Codable, Hashable, Sendable {
    let fetchedAt: Date
    let today: DayAvailability
    let week: [DayAvailability]
    let hasCalendarAccess: Bool

    var upcomingEvents: [CalendarEventItem] {
        week.flatMap(\.events).sorted { $0.startDate < $1.startDate }
    }

    var todayEventCount: Int {
        today.events.count
    }

    /// Natural-language summary for AI prompts (Milestone 6).
    var promptSummary: String {
        guard hasCalendarAccess else {
            return "Calendar access not granted."
        }

        var lines: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        if today.events.isEmpty {
            lines.append("Today (\(formatter.string(from: today.date))): no events scheduled.")
        } else {
            let eventDescriptions = today.events.map { event in
                if event.isAllDay {
                    return "\(event.title) (all day)"
                }
                return "\(event.title) \(event.formattedTimeRange)"
            }
            lines.append("Today: \(eventDescriptions.joined(separator: "; ")).")
        }

        if let nextFree = today.freeWindows.first(where: { $0.end > Date() }) {
            lines.append("Next free window today: \(nextFree.formattedRange).")
        }

        let upcoming = upcomingEvents
            .filter { $0.startDate > Date() }
            .prefix(3)

        if !upcoming.isEmpty {
            let upcomingText = upcoming.map { event in
                let day = formatter.string(from: event.startDate)
                return "\(day) \(event.title) at \(event.formattedTimeRange)"
            }
            lines.append("Upcoming: \(upcomingText.joined(separator: "; ")).")
        }

        return lines.joined(separator: " ")
    }
}
