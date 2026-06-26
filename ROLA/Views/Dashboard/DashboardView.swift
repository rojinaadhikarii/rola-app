import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        @Bindable var store = appState.conversationStore

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
                viewModel = DashboardViewModel(conversationStore: store)
            }
        }
        .onChange(of: store.conversations.count) { _, _ in
            // Ensure sidebar counts stay in sync after import.
        }
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
                statPill(label: "Streak", value: "—", icon: "flame")
                statPill(label: "Saved", value: "—", icon: "clock")

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

    private func dashboardContent(viewModel: DashboardViewModel) -> some View {
        HStack(spacing: 0) {
            sidebar(viewModel: viewModel)
                .frame(width: 200)

            Divider()
                .background(Theme.Colors.borderSubtle)

            conversationList(viewModel: viewModel)
                .frame(width: 300)

            Divider()
                .background(Theme.Colors.borderSubtle)

            detailPane(viewModel: viewModel)
        }
    }

    private func sidebar(viewModel: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(DashboardFilter.allCases) { filter in
                sidebarItem(
                    title: filter.title,
                    count: viewModel.count(for: filter),
                    isSelected: viewModel.selectedFilter == filter,
                    isEnabled: filter == .needsAttention || filter == .all
                        || viewModel.count(for: filter) > 0
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

                Text("\(count)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
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
            ConversationDetailView(
                conversation: conversation,
                messages: viewModel.selectedMessages,
                isLoading: viewModel.isLoadingMessages
            )
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
            await AppState(container: .preview).conversationStore.importConversations()
        }
}
