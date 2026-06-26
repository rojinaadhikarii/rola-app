import Foundation
import SwiftUI

// MARK: - App State

/// Global application state and navigation.
@MainActor
@Observable
final class AppState {

    // MARK: Navigation

    var route: AppRoute
    var onboardingStep: OnboardingStep

    // MARK: Onboarding Progress

    var isImporting: Bool = false
    var importProgress: Double = 0
    var hasCompletedOnboarding: Bool

    // MARK: Dependencies

    let container: DependencyContainer

    var conversationStore: ConversationStore {
        container.conversationStore
    }

    // MARK: Init

    init(container: DependencyContainer) {
        self.container = container
        let completed = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.hasCompletedOnboarding = completed
        self.route = completed ? .dashboard : .onboarding
        self.onboardingStep = .welcome

        if completed {
            Task { await container.conversationStore.refresh() }
        }
    }

    // MARK: Onboarding Actions

    func advanceOnboarding() {
        guard let next = OnboardingStep(rawValue: onboardingStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        withAnimation(Theme.Motion.standard) {
            onboardingStep = next
        }
    }

    func goBackOnboarding() {
        guard onboardingStep.rawValue > 0,
              let previous = OnboardingStep(rawValue: onboardingStep.rawValue - 1)
        else { return }
        withAnimation(Theme.Motion.standard) {
            onboardingStep = previous
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        hasCompletedOnboarding = true
        withAnimation(Theme.Motion.standard) {
            route = .dashboard
        }
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
        hasCompletedOnboarding = false
        onboardingStep = .welcome
        route = .onboarding
    }

    func openSettings() {
        withAnimation(Theme.Motion.fast) {
            route = .settings
        }
    }

    func closeSettings() {
        withAnimation(Theme.Motion.fast) {
            route = .dashboard
        }
    }

    // MARK: Message Import

    func importMessages() async {
        isImporting = true
        importProgress = 0

        await conversationStore.importConversations { [weak self] progress in
            Task { @MainActor in
                self?.importProgress = progress
            }
        }

        isImporting = false
        importProgress = 1.0

        if conversationStore.importError == nil {
            completeOnboarding()
        }
    }

    /// Skip import but still complete onboarding (for testing).
    func skipImport() async {
        completeOnboarding()
    }

    var importError: String? {
        conversationStore.importError
    }

    private static let onboardingKey = "com.rola.app.onboarding-complete"
}
