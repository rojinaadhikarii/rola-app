import Foundation

// MARK: - Onboarding View Model

@MainActor
@Observable
final class OnboardingViewModel {

    private let appState: AppState
    private let permissionManager: PermissionManagerProtocol

    var permissionStatuses: [PermissionType: PermissionStatus] = [:]
    var isRequestingPermission: PermissionType?

    init(appState: AppState) {
        self.appState = appState
        self.permissionManager = appState.container.permissionManager
        refreshPermissionStatuses()
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

    func refreshPermissionStatuses() {
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
    }

    func continueFromPermissions() async {
        await appState.simulateImport()
    }
}
