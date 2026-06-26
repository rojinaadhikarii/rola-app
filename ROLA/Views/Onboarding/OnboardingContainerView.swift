import SwiftUI

// MARK: - Onboarding Container

struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        VStack(spacing: 0) {
            if !appState.isImporting {
                header
            }

            ZStack {
                if appState.isImporting {
                    ImportProgressView(
                        progress: appState.importProgress,
                        phase: appState.importPhase
                    )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    stepContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(Theme.Motion.standard, value: appState.onboardingStep)
            .animation(Theme.Motion.standard, value: appState.isImporting)
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(appState: appState)
            }
        }
    }

    private var header: some View {
        HStack {
            if let viewModel, viewModel.canGoBack {
                ROLAIconButton(systemImage: "chevron.left") {
                    appState.goBackOnboarding()
                }
            } else {
                Color.clear.frame(width: 32, height: 32)
            }

            Spacer()

            PageIndicator(
                totalPages: OnboardingStep.allCases.count,
                currentPage: appState.onboardingStep.rawValue
            )

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch appState.onboardingStep {
        case .welcome:
            WelcomeView {
                appState.advanceOnboarding()
            }

        case .privacy:
            PrivacyView {
                appState.advanceOnboarding()
            }

        case .permissions:
            if let viewModel {
                PermissionsView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environment(AppState(container: .preview))
        .frame(width: 960, height: 640)
}
