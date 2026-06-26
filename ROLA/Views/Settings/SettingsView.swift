import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var apiKey: String = ""
    @State private var isKeyVisible: Bool = false
    @State private var saveMessage: String?
    @State private var saveMessageIsError: Bool = false

    @State private var supabaseURL: String = ""
    @State private var supabaseAnonKey: String = ""
    @State private var supabaseEmail: String = ""
    @State private var supabasePassword: String = ""
    @State private var cloudMessage: String?
    @State private var cloudMessageIsError: Bool = false
    @State private var isCloudBusy: Bool = false

    private var apiKeyStore: APIKeyStoreProtocol {
        appState.container.apiKeyStore
    }

    var body: some View {
        VStack(spacing: 0) {
            settingsHeader

            Divider()
                .background(Theme.Colors.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    messagesSection
                    styleSection
                    calendarSection
                    cloudSyncSection
                    apiKeySection
                    aboutSection
                }
                .padding(Theme.Spacing.xl)
                .frame(maxWidth: 560, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            loadExistingKey()
            loadSupabaseConfig()
        }
    }

    private var settingsHeader: some View {
        HStack {
            ROLAIconButton(systemImage: "chevron.left") {
                appState.closeSettings()
            }

            Text("Settings")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionTitle("Messages")

            HStack {
                Text("Imported conversations")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text("\(appState.conversationStore.conversations.count)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            if let lastImport = appState.conversationStore.lastImportDate {
                HStack {
                    Text("Last import")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text(lastImport.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }

            ROLAButton(
                title: "Re-import Messages",
                style: .secondary,
                systemImage: "arrow.clockwise",
                isLoading: appState.conversationStore.isImporting
            ) {
                Task { await appState.conversationStore.refresh() }
            }
            .frame(maxWidth: 220)
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionTitle("Communication Style")

            if let profile = appState.styleProfileStore.globalProfile {
                HStack {
                    Text("Tone")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text(profile.traits.toneSummary.capitalized)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                HStack {
                    Text("Messages analyzed")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(profile.traits.messageCount)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                HStack {
                    Text("Contact profiles")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(appState.styleProfileStore.contactProfiles.count)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                HStack {
                    Text("Learning events")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(appState.feedbackStore.allFeedback.count)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            } else {
                Text("No style profile yet. Import messages to analyze your communication style.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            ROLAButton(
                title: "Re-analyze Style",
                style: .secondary,
                systemImage: "text.bubble",
                isLoading: appState.styleProfileStore.isAnalyzing
            ) {
                Task { await appState.styleProfileStore.analyze() }
            }
            .frame(maxWidth: 220)
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionTitle("Calendar")

            HStack {
                Text("Access")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text(appState.calendarContextStore.hasAccess ? "Granted" : "Not granted")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            if appState.calendarContextStore.hasAccess {
                HStack {
                    Text("Events today")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(appState.calendarContextStore.todayEventCount)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }

            ROLAButton(
                title: appState.calendarContextStore.hasAccess ? "Refresh Calendar" : "Grant Calendar Access",
                style: .secondary,
                systemImage: "calendar",
                isLoading: appState.calendarContextStore.isLoading
            ) {
                Task {
                    if appState.calendarContextStore.hasAccess {
                        await appState.calendarContextStore.refresh()
                    } else {
                        await appState.calendarContextStore.requestAccessAndRefresh()
                    }
                }
            }
            .frame(maxWidth: 240)
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }

    private var cloudSyncSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionTitle("Cloud Sync (Supabase)")

            Text("Back up derived style profiles and learning feedback. Raw messages never leave your Mac.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            settingsField("Project URL", text: $supabaseURL, placeholder: "https://xyz.supabase.co")
            settingsField("Anon Key", text: $supabaseAnonKey, placeholder: "eyJ...", secure: true)
            settingsField("Email", text: $supabaseEmail, placeholder: "you@example.com")
            settingsField("Password", text: $supabasePassword, placeholder: "••••••••", secure: true)

            HStack(spacing: Theme.Spacing.sm) {
                ROLAButton(title: "Save Config", style: .secondary) {
                    saveSupabaseConfig()
                }
                .frame(maxWidth: 130)

                if appState.syncService.isAuthenticated {
                    ROLAButton(title: "Sync Now", style: .primary, isLoading: isCloudBusy) {
                        Task { await syncNow() }
                    }
                    .frame(maxWidth: 120)

                    ROLAButton(title: "Sign Out", style: .secondary) {
                        appState.syncService.signOut()
                        showCloudMessage("Signed out of Supabase.", isError: false)
                    }
                    .frame(maxWidth: 100)
                } else {
                    ROLAButton(title: "Sign In", style: .primary, isLoading: isCloudBusy) {
                        Task { await signInToSupabase() }
                    }
                    .frame(maxWidth: 100)

                    ROLAButton(title: "Sign Up", style: .secondary, isLoading: isCloudBusy) {
                        Task { await signUpToSupabase() }
                    }
                    .frame(maxWidth: 100)
                }
            }

            HStack {
                Text("Status")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text(appState.syncService.status.label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }

            if appState.feedbackStore.pendingSyncCount > 0 {
                HStack {
                    Text("Pending upload")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(appState.feedbackStore.pendingSyncCount) events")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.warning)
                }
            }

            if let cloudMessage {
                Text(cloudMessage)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(cloudMessageIsError ? Theme.Colors.error : Theme.Colors.success)
            }

            Link("Set up Supabase →", destination: URL(string: "https://supabase.com/dashboard")!)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }

    private func settingsField(
        _ label: String,
        text: Binding<String>,
        placeholder: String,
        secure: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .textFieldStyle(.plain)
            .font(Theme.Typography.body)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionTitle("OpenAI API Key")

            Text("ROLA uses your own OpenAI API key. Your key is stored securely in the macOS Keychain and never leaves your device.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Theme.Spacing.sm) {
                Group {
                    if isKeyVisible {
                        TextField("sk-...", text: $apiKey)
                    } else {
                        SecureField("sk-...", text: $apiKey)
                    }
                }
                .textFieldStyle(.plain)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )

                Button {
                    isKeyVisible.toggle()
                } label: {
                    Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: Theme.Spacing.sm) {
                ROLAButton(title: "Save Key", style: .primary) {
                    saveAPIKey()
                }
                .frame(maxWidth: 140)

                if apiKeyStore.hasOpenAIKey {
                    ROLAButton(title: "Remove", style: .secondary) {
                        removeAPIKey()
                    }
                    .frame(maxWidth: 100)
                }
            }

            if let saveMessage {
                Text(saveMessage)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(saveMessageIsError ? Theme.Colors.error : Theme.Colors.success)
            }

            Link("Get an API key from OpenAI →", destination: URL(string: "https://platform.openai.com/api-keys")!)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionTitle("About")

            HStack {
                Text("Version")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text("0.7.0 (Milestone 7)")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            HStack {
                Text("Bundle ID")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text("com.rola.app")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            ROLAButton(title: "Reset Onboarding", style: .secondary) {
                appState.resetOnboarding()
            }
            .frame(maxWidth: 200)
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.textPrimary)
    }

    private func loadExistingKey() {
        if let existing = apiKeyStore.loadOpenAIKey() {
            apiKey = existing
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showMessage("Please enter an API key.", isError: true)
            return
        }
        guard trimmed.hasPrefix("sk-") else {
            showMessage("API keys typically start with \"sk-\".", isError: true)
            return
        }

        do {
            try apiKeyStore.saveOpenAIKey(trimmed)
            showMessage("API key saved securely to Keychain.", isError: false)
        } catch {
            showMessage(error.localizedDescription, isError: true)
        }
    }

    private func removeAPIKey() {
        apiKeyStore.deleteOpenAIKey()
        apiKey = ""
        showMessage("API key removed.", isError: false)
    }

    private func showMessage(_ message: String, isError: Bool) {
        saveMessage = message
        saveMessageIsError = isError
    }

    private func loadSupabaseConfig() {
        if let config = appState.syncService.loadConfig() {
            supabaseURL = config.projectURL
            supabaseAnonKey = config.anonKey
        }
    }

    private func saveSupabaseConfig() {
        let config = SupabaseConfig(
            projectURL: supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            anonKey: supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard config.isConfigured else {
            showCloudMessage("Enter both project URL and anon key.", isError: true)
            return
        }
        appState.syncService.saveConfig(config)
        showCloudMessage("Supabase configuration saved.", isError: false)
    }

    private func signInToSupabase() async {
        isCloudBusy = true
        defer { isCloudBusy = false }
        saveSupabaseConfig()
        do {
            try await appState.syncService.signIn(
                email: supabaseEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                password: supabasePassword
            )
            showCloudMessage("Signed in and synced.", isError: false)
        } catch {
            showCloudMessage(error.localizedDescription, isError: true)
        }
    }

    private func signUpToSupabase() async {
        isCloudBusy = true
        defer { isCloudBusy = false }
        saveSupabaseConfig()
        do {
            try await appState.syncService.signUp(
                email: supabaseEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                password: supabasePassword
            )
            showCloudMessage("Account created and synced.", isError: false)
        } catch {
            showCloudMessage(error.localizedDescription, isError: true)
        }
    }

    private func syncNow() async {
        isCloudBusy = true
        defer { isCloudBusy = false }
        await appState.syncService.syncIfNeeded()
        if case .failed(let message) = appState.syncService.status {
            showCloudMessage(message, isError: true)
        } else {
            showCloudMessage("Sync complete.", isError: false)
        }
    }

    private func showCloudMessage(_ message: String, isError: Bool) {
        cloudMessage = message
        cloudMessageIsError = isError
    }
}

#Preview {
    SettingsView()
        .environment(AppState(container: .preview))
        .frame(width: 960, height: 640)
        .rolaBackground()
}
