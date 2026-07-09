import SwiftUI
import UserNotifications

@main
struct ROLAApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState: AppState

    init() {
        let container = DependencyContainer.live
        _appState = State(initialValue: AppState(container: container))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    appDelegate.configure(with: appState)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 640)
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    let notificationDelegate = NotificationDelegate()
    private weak var appState: AppState?

    func configure(with appState: AppState) {
        self.appState = appState
        UNUserNotificationCenter.current().delegate = notificationDelegate
        notificationDelegate.onSelectChat = { [weak appState] chatId in
            Task { @MainActor in
                await appState?.openConversationFromNotification(chatId: chatId)
            }
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.route {
            case .onboarding:
                OnboardingContainerView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))

            case .dashboard:
                DashboardView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

            case .settings:
                SettingsView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(Theme.Motion.standard, value: appState.route)
        .rolaBackground()
    }
}

#Preview {
    RootView()
        .environment(AppState(container: .preview))
}
