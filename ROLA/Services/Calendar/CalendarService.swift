import EventKit
import Foundation

// MARK: - Calendar Service

@MainActor
final class CalendarService: CalendarServiceProtocol {

    private let store = EKEventStore()
    private let fetchDays = 7

    func authorizationStatus() -> PermissionStatus {
        PermissionStatusMapper.from(calendar: EKEventStore.authorizationStatus(for: .event))
    }

    func requestAccess() async -> PermissionStatus {
        do {
            let granted = try await store.requestFullAccessToEvents()
            return granted ? .granted : .denied
        } catch {
            return .denied
        }
    }

    func fetchContext() async throws -> CalendarContext {
        guard authorizationStatus() == .granted else {
            return emptyContext(hasAccess: false)
        }

        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        guard let endDate = calendar.date(byAdding: .day, value: fetchDays, to: startOfToday) else {
            return emptyContext(hasAccess: true)
        }

        let predicate = store.predicateForEvents(
            withStart: startOfToday,
            end: endDate,
            calendars: nil
        )
        let ekEvents = store.events(matching: predicate)

        let items = ekEvents.map { event in
            CalendarEventItem(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Busy",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                location: event.location
            )
        }

        var eventsByDay: [Date: [CalendarEventItem]] = [:]
        for item in items {
            let day = calendar.startOfDay(for: item.startDate)
            eventsByDay[day, default: []].append(item)
        }

        let week = AvailabilityChecker.weekAvailability(
            startingFrom: now,
            eventsByDay: eventsByDay,
            days: fetchDays
        )

        let today = week.first ?? AvailabilityChecker.dayAvailability(for: startOfToday, events: [])

        return CalendarContext(
            fetchedAt: now,
            today: today,
            week: week,
            hasCalendarAccess: true
        )
    }

    func isAvailable(from start: Date, to end: Date) async -> Bool {
        guard authorizationStatus() == .granted else { return true }

        let context = try? await fetchContext()
        guard let today = context?.today else { return true }

        let calendar = Calendar.current
        if calendar.isDate(start, inSameDayAs: today.date) {
            return AvailabilityChecker.isAvailable(from: start, to: end, on: today)
        }

        if let day = context?.week.first(where: { calendar.isDate($0.date, inSameDayAs: start) }) {
            return AvailabilityChecker.isAvailable(from: start, to: end, on: day)
        }

        return true
    }

    private func emptyContext(hasAccess: Bool) -> CalendarContext {
        let today = AvailabilityChecker.dayAvailability(for: Date(), events: [])
        return CalendarContext(
            fetchedAt: Date(),
            today: today,
            week: [today],
            hasCalendarAccess: hasAccess
        )
    }
}
