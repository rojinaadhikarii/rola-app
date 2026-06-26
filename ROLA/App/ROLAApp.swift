import SwiftUI

@main
struct ROLAApp: App {

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
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 640)
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
