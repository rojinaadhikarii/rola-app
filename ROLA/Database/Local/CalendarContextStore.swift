import Foundation

// MARK: - Calendar Context Store

@MainActor
@Observable
final class CalendarContextStore {

    private(set) var context: CalendarContext?
    private(set) var isLoading = false
    private(set) var lastError: String?

    private let calendarService: CalendarServiceProtocol

    init(calendarService: CalendarServiceProtocol) {
        self.calendarService = calendarService
    }

    var hasAccess: Bool {
        calendarService.authorizationStatus() == .granted
    }

    var todayEventCount: Int {
        context?.todayEventCount ?? 0
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            context = try await calendarService.fetchContext()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func schedulingHint(for message: String) -> String? {
        guard let context else { return nil }
        return ContextAssembler.schedulingHint(for: message, context: context)
    }

    func requestAccessAndRefresh() async -> PermissionStatus {
        let status = await calendarService.requestAccess()
        if status == .granted {
            await refresh()
        }
        return status
    }
}
