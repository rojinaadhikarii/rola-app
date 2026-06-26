import Foundation

// MARK: - Onboarding View Model

@MainActor
@Observable
final class OnboardingViewModel {

    private let appState: AppState
    private let permissionManager: PermissionManagerProtocol
    private let refreshObserver: PermissionRefreshObserver

    var permissionStatuses: [PermissionType: PermissionStatus] = [:]
    var isRequestingPermission: PermissionType?

    init(appState: AppState) {
        self.appState = appState
        self.permissionManager = appState.container.permissionManager
        self.refreshObserver = PermissionRefreshObserver()

        refreshObserver.onRefresh = { [weak self] in
            Task { await self?.refreshPermissionStatuses() }
        }

        Task { await refreshPermissionStatuses() }
    }

    var currentStep: OnboardingStep {
        appState.onboardingStep
    }

    var canGoBack: Bool {
        currentStep.rawValue > 0 && !appState.isImporting
    }

    var allRequiredPermissionsGranted: Bool {
        PermissionType.allCases
            .filter(\.isRequired)
            .allSatisfy { permissionStatuses[$0] == .granted }
    }

    var hasPromptedFullDiskAccess: Bool {
        permissionManager.hasPromptedFullDiskAccess
    }

    func shouldShowOpenSettings(for permission: PermissionType) -> Bool {
        let status = permissionStatuses[permission] ?? .notDetermined

        if permission == .fullDiskAccess {
            return hasPromptedFullDiskAccess && status != .granted
        }

        return status == .denied || status == .restricted
    }

    func refreshPermissionStatuses() async {
        await permissionManager.refreshAllStatuses()
        for permission in PermissionType.allCases {
            permissionStatuses[permission] = permissionManager.status(for: permission)
        }
    }

    func requestPermission(_ permission: PermissionType) async {
        isRequestingPermission = permission
        let status = await permissionManager.request(permission)
        permissionStatuses[permission] = status
        isRequestingPermission = nil
    }

    func openSystemSettings(for permission: PermissionType) {
        permissionManager.openSystemSettings(for: permission)
        Task {
            // Re-check after a short delay in case settings were changed in-place.
            try? await Task.sleep(for: .milliseconds(500))
            await refreshPermissionStatuses()
        }
    }

    func continueFromPermissions() async {
        await appState.importMessages()
    }
}
