import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            dashboardHeader

            Divider()
                .background(Theme.Colors.borderSubtle)

            dashboardContent
        }
    }

    private var dashboardHeader: some View {
        HStack {
            HStack(spacing: Theme.Spacing.md) {
                ROLALogoMark(size: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ROLA")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Relationship Copilot")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                statPill(label: "Inbox", value: "—", icon: "tray")
                statPill(label: "Streak", value: "—", icon: "flame")
                statPill(label: "Saved", value: "—", icon: "clock")

                ROLAIconButton(systemImage: "gearshape") {
                    appState.openSettings()
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    private func statPill(label: String, value: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(label)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }

    private var dashboardContent: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 240)

            Divider()
                .background(Theme.Colors.borderSubtle)

            mainContent
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sidebarItem(title: "Needs Attention", count: 0, isSelected: true)
            sidebarItem(title: "Suggestions", count: 0, isSelected: false)
            sidebarItem(title: "Follow-ups", count: 0, isSelected: false)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.background)
    }

    private func sidebarItem(title: String, count: Int, isSelected: Bool) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.callout)
                .foregroundStyle(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)

            Spacer()

            Text("\(count)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(isSelected ? Theme.Colors.surfaceElevated : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }

    private var mainContent: some View {
        EmptyStateView(
            systemImage: "message",
            title: "Import your messages to get started",
            message: "Once ROLA has access to your iMessage history, you'll see conversations that need your attention — with AI reply suggestions that sound like you.",
            actionTitle: "Reset Onboarding"
        ) {
            appState.resetOnboarding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}

#Preview {
    DashboardView()
        .environment(AppState(container: .preview))
        .frame(width: 960, height: 640)
        .rolaBackground()
}
