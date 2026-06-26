import Foundation

// MARK: - Availability Checker

/// Computes free windows and busy checks from calendar events.
enum AvailabilityChecker {

    static let defaultDayStartHour = 8
    static let defaultDayEndHour = 22

    static func dayAvailability(
        for date: Date,
        events: [CalendarEventItem],
        dayStartHour: Int = defaultDayStartHour,
        dayEndHour: Int = defaultDayEndHour
    ) -> DayAvailability {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard let dayStart = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: startOfDay),
              let dayEnd = calendar.date(bySettingHour: dayEndHour, minute: 0, second: 0, of: startOfDay)
        else {
            return DayAvailability(date: startOfDay, events: events, freeWindows: [])
        }

        let timedEvents = events
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        var freeWindows: [AvailabilityWindow] = []
        var cursor = dayStart

        for event in timedEvents {
            let eventStart = max(event.startDate, dayStart)
            let eventEnd = min(event.endDate, dayEnd)

            guard eventEnd > dayStart, eventStart < dayEnd else { continue }

            if eventStart > cursor {
                freeWindows.append(AvailabilityWindow(start: cursor, end: eventStart))
            }
            cursor = max(cursor, eventEnd)
        }

        if cursor < dayEnd {
            freeWindows.append(AvailabilityWindow(start: cursor, end: dayEnd))
        }

        return DayAvailability(date: startOfDay, events: events, freeWindows: freeWindows)
    }

    static func isAvailable(
        from start: Date,
        to end: Date,
        on day: DayAvailability
    ) -> Bool {
        guard start < end else { return false }

        for event in day.events where !event.isAllDay {
            let overlaps = start < event.endDate && end > event.startDate
            if overlaps { return false }
        }
        return true
    }

    static func weekAvailability(
        startingFrom date: Date = Date(),
        eventsByDay: [Date: [CalendarEventItem]],
        days: Int = 7
    ) -> [DayAvailability] {
        let calendar = Calendar.current
        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date))
            else { return nil }
            let dayEvents = eventsByDay[calendar.startOfDay(for: day)] ?? []
            return dayAvailability(for: day, events: dayEvents)
        }
    }
}
