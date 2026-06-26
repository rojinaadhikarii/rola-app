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

    // MARK: Init

    init(container: DependencyContainer) {
        self.container = container
        let completed = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.hasCompletedOnboarding = completed
        self.route = completed ? .dashboard : .onboarding
        self.onboardingStep = .welcome
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

    // MARK: Import Simulation (Milestone 1 placeholder)

    func simulateImport() async {
        isImporting = true
        importProgress = 0

        for step in 1...10 {
            try? await Task.sleep(for: .milliseconds(200))
            importProgress = Double(step) / 10.0
        }

        isImporting = false
        completeOnboarding()
    }

    private static let onboardingKey = "com.rola.app.onboarding-complete"
}
