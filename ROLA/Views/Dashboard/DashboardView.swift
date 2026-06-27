import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DashboardViewModel?
    @State private var suggestionViewModel: SuggestionViewModel?
    @State private var showCopiedToast = false

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
        .toast(
            isPresented: $showCopiedToast,
            message: "Copied to clipboard — paste in Messages",
            systemImage: "doc.on.doc.fill"
        )
        .onAppear {
            if viewModel == nil {
                viewModel = DashboardViewModel(
                    conversationStore: conversationStore,
                    styleProfileStore: styleStore,
                    calendarContextStore: calendarStore,
                    suggestionStore: appState.suggestionStore
                )
                let suggestions = SuggestionViewModel(
                    aiPipeline: appState.aiPipeline,
                    learningService: appState.learningService,
                    suggestionStore: appState.suggestionStore,
                    styleProfileStore: styleStore,
                    calendarContextStore: calendarStore
                )
                suggestions.onReplyCopied = { showCopiedToast = true }
                suggestionViewModel = suggestions
                Task {
                    await calendarStore.refresh()
                    await appState.evaluateInboxNotifications()
                }
            }
        }
        .onChange(of: conversationStore.conversations.count) { _, _ in
            Task { await appState.evaluateInboxNotifications() }
        }
        .onChange(of: conversationStore.needsAttention.count) { _, _ in
            Task { await appState.evaluateInboxNotifications() }
        }
        .onChange(of: styleStore.hasProfile) { _, _ in }
        .onChange(of: calendarStore.context?.fetchedAt) { _, _ in }
        .onChange(of: conversationStore.selectedConversation?.id) { _, newId in
            handleConversationSelection(newId: newId, viewModel: viewModel)
        }
        .onChange(of: conversationStore.selectedMessages.count) { _, _ in
            handleMessagesLoaded(viewModel: viewModel)
        }
    }

    private func handleConversationSelection(newId: Int64?, viewModel: DashboardViewModel?) {
        guard let viewModel,
              let conversation = viewModel.selectedConversation,
              let suggestionViewModel else {
            suggestionViewModel?.reset()
            return
        }

        suggestionViewModel.loadSuggestion(
            for: conversation,
            messages: viewModel.selectedMessages
        )

        guard conversation.needsReply,
              !viewModel.isLoadingMessages,
              !viewModel.selectedMessages.isEmpty else { return }

        Task {
            await suggestionViewModel.generateSuggestion(
                for: conversation,
                messages: viewModel.selectedMessages
            )
        }
    }

    private func handleMessagesLoaded(viewModel: DashboardViewModel?) {
        guard let viewModel,
              let conversation = viewModel.selectedConversation,
              let suggestionViewModel,
              conversation.needsReply,
              !viewModel.isLoadingMessages else { return }

        suggestionViewModel.loadSuggestion(
            for: conversation,
            messages: viewModel.selectedMessages
        )

        Task {
            await suggestionViewModel.generateSuggestion(
                for: conversation,
                messages: viewModel.selectedMessages
            )
        }
    }

    private func dashboardHeader(viewModel: DashboardViewModel) -> some View {
        let health = appState.inboxMonitor.inboxHealth(for: viewModel.conversations)

        return HStack {
            HStack(spacing: Theme.Spacing.md) {
                InboxHealthRing(health: health, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ROLA")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(health.title)
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
                    Task {
                        await viewModel.refresh()
                        await appState.evaluateInboxNotifications()
                    }
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
                    .transition(.opacity.combined(with: .move(edge: .leading)))

                Divider()
                    .background(Theme.Colors.borderSubtle)

                detailPane(viewModel: viewModel)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(Theme.Motion.standard, value: viewModel.selectedFilter)
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
        .animation(Theme.Motion.fast, value: isSelected)
    }

    private func conversationList(viewModel: DashboardViewModel) -> some View {
        Group {
            if appState.conversationStore.isImporting && viewModel.conversations.isEmpty {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.xs) {
                        ForEach(0..<4, id: \.self) { _ in
                            ConversationRowSkeleton()
                        }
                    }
                    .padding(Theme.Spacing.sm)
                }
            } else if viewModel.filteredConversations.isEmpty {
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(Theme.Spacing.sm)
                    .animation(Theme.Motion.standard, value: viewModel.filteredConversations.map(\.id))
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

                if conversation.needsReply, let suggestionViewModel {
                    Divider().background(Theme.Colors.borderSubtle)
                    suggestionSection(
                        viewModel: viewModel,
                        suggestionViewModel: suggestionViewModel,
                        conversation: conversation
                    )
                }

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
                message: "Choose a thread that needs a reply to see AI suggestions in your voice."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
        }
    }

    @ViewBuilder
    private func suggestionSection(
        viewModel: DashboardViewModel,
        suggestionViewModel: SuggestionViewModel,
        conversation: Conversation
    ) -> some View {
        if !appState.apiKeyStore.hasOpenAIKey {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "key")
                    .foregroundStyle(Theme.Colors.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("OpenAI API key required")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Add your key in Settings to generate reply suggestions.")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                Spacer()
                Button("Settings") {
                    appState.openSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.surface)
        } else if let suggestion = suggestionViewModel.currentSuggestion {
            SuggestionCard(
                suggestion: suggestion,
                isGenerating: suggestionViewModel.isGenerating,
                errorMessage: suggestionViewModel.errorMessage,
                onApprove: { suggestionViewModel.approveSuggestion() },
                onEdit: { text in suggestionViewModel.editAndApprove(editedText: text) },
                onDismiss: { suggestionViewModel.dismissSuggestion() },
                onGenerate: {
                    Task {
                        await suggestionViewModel.generateSuggestion(
                            for: conversation,
                            messages: viewModel.selectedMessages
                        )
                    }
                }
            )
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.background)
        } else if suggestionViewModel.isGenerating || suggestionViewModel.errorMessage != nil {
            SuggestionCard(
                suggestion: placeholderSuggestion(for: conversation, messages: viewModel.selectedMessages),
                isGenerating: suggestionViewModel.isGenerating,
                errorMessage: suggestionViewModel.errorMessage,
                onApprove: {},
                onEdit: { _ in },
                onDismiss: {},
                onGenerate: {
                    Task {
                        await suggestionViewModel.generateSuggestion(
                            for: conversation,
                            messages: viewModel.selectedMessages
                        )
                    }
                }
            )
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.background)
        }
    }

    private func placeholderSuggestion(
        for conversation: Conversation,
        messages: [ImportedMessage]
    ) -> ReplySuggestion {
        let incoming = messages.last(where: { !$0.isFromMe })
        return ReplySuggestion(
            id: UUID(),
            chatId: conversation.id,
            incomingMessageId: incoming?.id,
            incomingMessageText: incoming?.text ?? conversation.lastMessageText ?? "",
            replyText: "",
            confidence: 0,
            reasoning: nil,
            status: .pending,
            safetyBlocked: false,
            safetyReason: nil,
            createdAt: Date()
        )
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
        switch viewModel.selectedFilter {
        case .suggestions:
            EmptyStateView(
                systemImage: "sparkles",
                title: "No pending suggestions",
                message: "Open a conversation that needs a reply to generate AI suggestions."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .followUps:
            EmptyStateView(
                systemImage: "clock.arrow.circlepath",
                title: "Follow-ups coming soon",
                message: "ROLA will remind you about conversations that went quiet."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .needsAttention where viewModel.conversations.isEmpty:
            EmptyStateView(
                systemImage: "tray",
                title: "No conversations",
                message: "Import your iMessage history to get started."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .needsAttention, .all:
            EmptyStateView(
                systemImage: "checkmark.circle",
                title: "All caught up",
                message: "No messages need your attention right now."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            EmptyStateView(
                systemImage: "tray",
                title: "Nothing here",
                message: "Try another filter or refresh your inbox."
            )
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
