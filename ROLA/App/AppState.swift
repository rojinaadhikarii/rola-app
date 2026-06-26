import Foundation
import SwiftUI

// MARK: - Import Phase

enum ImportPhase: Equatable {
    case importingMessages
    case analyzingStyle

    var title: String {
        switch self {
        case .importingMessages: "Importing conversations"
        case .analyzingStyle: "Analyzing your style"
        }
    }

    var subtitle: String {
        switch self {
        case .importingMessages: "Reading your iMessage history…"
        case .analyzingStyle: "Learning how you write with different people…"
        }
    }
}

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
    var importPhase: ImportPhase = .importingMessages
    var hasCompletedOnboarding: Bool

    // MARK: Dependencies

    let container: DependencyContainer

    var conversationStore: ConversationStore {
        container.conversationStore
    }

    var styleProfileStore: StyleProfileStore {
        container.styleProfileStore
    }

    var calendarContextStore: CalendarContextStore {
        container.calendarContextStore
    }

    var suggestionStore: SuggestionStore {
        container.suggestionStore
    }

    var aiPipeline: AIPipelineProtocol {
        container.aiPipeline
    }

    var apiKeyStore: APIKeyStoreProtocol {
        container.apiKeyStore
    }

    var feedbackStore: FeedbackStore {
        container.feedbackStore
    }

    var syncService: SyncService {
        container.syncService
    }

    var learningService: LearningService {
        container.learningService
    }

    // MARK: Init

    init(container: DependencyContainer) {
        self.container = container
        let completed = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.hasCompletedOnboarding = completed
        self.route = completed ? .dashboard : .onboarding
        self.onboardingStep = .welcome

        if completed {
            Task { await refreshData() }
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
        styleProfileStore.clear()
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

    // MARK: Message Import + Style Analysis

    func importMessages() async {
        isImporting = true
        importProgress = 0
        importPhase = .importingMessages

        await conversationStore.importConversations { [weak self] progress in
            Task { @MainActor in
                self?.importProgress = progress * 0.6
            }
        }

        if conversationStore.importError != nil {
            isImporting = false
            return
        }

        importPhase = .analyzingStyle
        await styleProfileStore.analyze { [weak self] progress in
            Task { @MainActor in
                self?.importProgress = 0.6 + (progress * 0.4)
            }
        }

        isImporting = false
        importProgress = 1.0

        if conversationStore.importError == nil {
            completeOnboarding()
        }
    }

    func refreshData() async {
        await conversationStore.refresh()
        if conversationStore.importError == nil {
            await styleProfileStore.analyze()
        }
        await calendarContextStore.refresh()
    }

    /// Skip import but still complete onboarding (for testing).
    func skipImport() async {
        completeOnboarding()
    }

    var importError: String? {
        conversationStore.importError ?? styleProfileStore.analysisError
    }

    private static let onboardingKey = "com.rola.app.onboarding-complete"
}
