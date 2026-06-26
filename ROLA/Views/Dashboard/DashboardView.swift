import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        @Bindable var conversationStore = appState.conversationStore
        @Bindable var styleStore = appState.styleProfileStore
        @Bindable var calendarStore = appState.calendarContextStore

        VStack(spacing: 0) {
            if let viewModel {
                dashboardHeader(viewModel: viewModel)

                Divider()
                    .background(Theme.Colors.borderSubtle)

                dashboardContent(viewModel: viewModel)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DashboardViewModel(
                    conversationStore: conversationStore,
                    styleProfileStore: styleStore,
                    calendarContextStore: calendarStore
                )
                Task { await calendarStore.refresh() }
            }
        }
        .onChange(of: conversationStore.conversations.count) { _, _ in }
        .onChange(of: styleStore.hasProfile) { _, _ in }
        .onChange(of: calendarStore.context?.fetchedAt) { _, _ in }
    }

    private func dashboardHeader(viewModel: DashboardViewModel) -> some View {
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
                statPill(
                    label: "Inbox",
                    value: viewModel.inboxCount > 0 ? "\(viewModel.inboxCount)" : "—",
                    icon: "tray"
                )
                statPill(
                    label: "Style",
                    value: viewModel.hasStyleProfile ? "✓" : "—",
                    icon: "text.bubble"
                )
                statPill(
                    label: "Today",
                    value: viewModel.hasCalendarAccess
                        ? (viewModel.todayEventCount > 0 ? "\(viewModel.todayEventCount)" : "Free")
                        : "—",
                    icon: "calendar"
                )

                ROLAIconButton(systemImage: "arrow.clockwise") {
                    Task { await viewModel.refresh() }
                }

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

    @ViewBuilder
    private func dashboardContent(viewModel: DashboardViewModel) -> some View {
        HStack(spacing: 0) {
            sidebar(viewModel: viewModel)
                .frame(width: 200)

            Divider()
                .background(Theme.Colors.borderSubtle)

            if viewModel.selectedFilter == .yourStyle {
                CommunicationProfileView(
                    result: viewModel.styleAnalysisResult,
                    isLoading: viewModel.isAnalyzingStyle,
                    errorMessage: viewModel.styleAnalysisError
                )
            } else if viewModel.selectedFilter == .calendar {
                CalendarContextView(
                    context: viewModel.calendarContext,
                    isLoading: viewModel.isLoadingCalendar,
                    hasAccess: viewModel.hasCalendarAccess,
                    errorMessage: viewModel.calendarError,
                    onRequestAccess: {
                        Task { await viewModel.requestCalendarAccess() }
                    }
                )
            } else {
                conversationList(viewModel: viewModel)
                    .frame(width: 300)

                Divider()
                    .background(Theme.Colors.borderSubtle)

                detailPane(viewModel: viewModel)
            }
        }
    }

    private func sidebar(viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(DashboardFilter.allCases) { filter in
                sidebarItem(
                    title: filter.title,
                    count: viewModel.count(for: filter),
                    isSelected: viewModel.selectedFilter == filter,
                    isEnabled: isFilterEnabled(filter, viewModel: viewModel)
                ) {
                    viewModel.selectFilter(filter)
                }
            }

            Spacer()

            if let lastImport = viewModel.lastImportDate {
                Text("Imported \(lastImport.formatted(date: .abbreviated, time: .shortened))")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.background)
    }

    private func isFilterEnabled(_ filter: DashboardFilter, viewModel: DashboardViewModel) -> Bool {
        switch filter {
        case .needsAttention, .all, .yourStyle, .calendar:
            true
        case .suggestions, .followUps:
            viewModel.count(for: filter) > 0
        }
    }

    private func sidebarItem(
        title: String,
        count: Int,
        isSelected: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(
                        isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary
                    )

                Spacer()

                if count > 0 || title == "Your Style" {
                    Text(title == "Your Style" && count > 0 ? "✓" : "\(count)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                } else if title == "Calendar" && count == 0 && isSelected {
                    Text("Free")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.surfaceElevated : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled && !isSelected)
        .opacity(isEnabled || isSelected ? 1 : 0.45)
    }

    private func conversationList(viewModel: DashboardViewModel) -> some View {
        Group {
            if viewModel.filteredConversations.isEmpty {
                emptyListState(viewModel: viewModel)
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.xs) {
                        ForEach(viewModel.filteredConversations) { conversation in
                            Button {
                                Task {
                                    await viewModel.selectConversation(conversation)
                                }
                            } label: {
                                ConversationRow(
                                    conversation: conversation,
                                    isSelected: viewModel.selectedConversation?.id == conversation.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.Spacing.sm)
                }
            }
        }
        .background(Theme.Colors.background)
    }

    @ViewBuilder
    private func detailPane(viewModel: DashboardViewModel) -> some View {
        if let conversation = viewModel.selectedConversation {
            VStack(spacing: 0) {
                ConversationDetailView(
                    conversation: conversation,
                    messages: viewModel.selectedMessages,
                    isLoading: viewModel.isLoadingMessages,
                    schedulingHint: viewModel.schedulingHint(for: conversation)
                )

                if let contactProfile = appState.styleProfileStore.profile(for: conversation.id) {
                    Divider().background(Theme.Colors.borderSubtle)
                    contactStyleBanner(profile: contactProfile)
                }
            }
        } else if viewModel.conversations.isEmpty {
            EmptyStateView(
                systemImage: "message",
                title: "No conversations imported",
                message: "Import your iMessage history to see conversations that need your attention.",
                actionTitle: "Reset Onboarding"
            ) {
                appState.resetOnboarding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
        } else {
            EmptyStateView(
                systemImage: "bubble.left.and.bubble.right",
                title: "Select a conversation",
                message: "Choose a thread to preview recent messages. AI suggestions arrive in a future milestone."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
        }
    }

    private func contactStyleBanner(profile: StyleProfile) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "text.bubble")
                .foregroundStyle(Theme.Colors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your tone with \(profile.displayName ?? "them")")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(profile.traits.toneSummary.capitalized)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.surface)
    }

    @ViewBuilder
    private func emptyListState(viewModel: DashboardViewModel) -> some View {
        if viewModel.conversations.isEmpty {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "tray")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("No conversations")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.Colors.success)
                Text("All caught up")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("No messages need your attention right now.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppState(container: .preview))
        .frame(width: 960, height: 640)
        .rolaBackground()
        .task {
            let state = AppState(container: .preview)
            await state.conversationStore.importConversations()
            await state.styleProfileStore.analyze()
            await state.calendarContextStore.refresh()
        }
}
