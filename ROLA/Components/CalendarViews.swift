import SwiftUI

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: CalendarEventItem

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Theme.Colors.accent)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(event.formattedTimeRange)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    if let location = event.location, !location.isEmpty {
                        Text("·")
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text(location)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .rolaCard()
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let day: DayAvailability
    var showFreeWindows: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text(day.isToday ? "Today" : day.formattedDate)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Text("\(day.events.count) event\(day.events.count == 1 ? "" : "s")")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            if day.events.isEmpty {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Theme.Colors.success)
                    Text("No events — you're free")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .rolaCard()
            } else {
                ForEach(day.events) { event in
                    CalendarEventRow(event: event)
                }
            }

            if showFreeWindows, !day.freeWindows.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Free windows")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    ForEach(day.freeWindows) { window in
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.success)
                            Text(window.formattedRange)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .rolaCard()
            }
        }
    }
}

// MARK: - Calendar Context View

struct CalendarContextView: View {
    let context: CalendarContext?
    var isLoading: Bool = false
    var hasAccess: Bool = false
    var errorMessage: String?
    var onRequestAccess: (() -> Void)?

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: Theme.Spacing.lg) {
                    ProgressView().tint(Theme.Colors.accent)
                    Text("Loading calendar…")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            } else if !hasAccess {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "Calendar access needed",
                    message: "Grant calendar access so ROLA can suggest replies based on your availability.",
                    actionTitle: "Grant Access"
                ) {
                    onRequestAccess?()
                }
            } else if let errorMessage {
                EmptyStateView(
                    systemImage: "exclamationmark.triangle",
                    title: "Could not load calendar",
                    message: errorMessage
                )
            } else if let context {
                calendarContent(context: context)
            } else {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "No calendar data",
                    message: "Refresh to load your schedule."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }

    private func calendarContent(context: CalendarContext) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Your schedule")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("ROLA uses this to craft context-aware reply suggestions.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                CalendarDayView(day: context.today)

                if context.week.count > 1 {
                    Text("This week")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    ForEach(context.week.dropFirst(), id: \.date) { day in
                        CalendarDayView(day: day, showFreeWindows: false)
                    }
                }

                contextPreviewCard(summary: context.promptSummary)
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private func contextPreviewCard(summary: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("AI context preview", systemImage: "sparkles")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)

            Text(summary)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }
}

// MARK: - Scheduling Hint Banner

struct SchedulingHintBanner: View {
    let hint: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Calendar context")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.accent)

                Text(hint)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.accentMuted)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }
}

#Preview {
    CalendarContextView(
        context: MockCalendarData.sampleContext,
        hasAccess: true
    )
    .frame(width: 500, height: 700)
    .rolaBackground()
}
