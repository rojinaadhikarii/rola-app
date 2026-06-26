import SwiftUI

// MARK: - Permissions View

struct PermissionsView: View {
  @Bindable var viewModel: OnboardingViewModel
  @Environment(AppState.self) private var appState
  @State private var showFullDiskAccessGuide = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: Theme.Spacing.xl) {
        VStack(spacing: Theme.Spacing.md) {
          Text("Set up permissions")
            .font(Theme.Typography.title)
            .foregroundStyle(Theme.Colors.textPrimary)

          Text("ROLA needs a few permissions to work. You stay in control of each one.")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 480)
        }

        VStack(spacing: Theme.Spacing.sm) {
          ForEach(PermissionType.allCases) { permission in
            PermissionCard(
              permission: permission,
              status: viewModel.permissionStatuses[permission] ?? .notDetermined,
              isLoading: viewModel.isRequestingPermission == permission,
              showOpenSettingsAction: viewModel.shouldShowOpenSettings(for: permission),
              onRequest: {
                handlePermissionRequest(permission)
              },
              onOpenSettings: {
                viewModel.openSystemSettings(for: permission)
              }
            )
          }
        }
        .frame(maxWidth: 520)
      }

      Spacer()

      VStack(spacing: Theme.Spacing.md) {
        if let error = appState.importError {
          Text(error)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.error)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400)
        }

        if !viewModel.allRequiredPermissionsGranted {
          Text(requiredPermissionsHint)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400)
        }

        ROLAButton(
          title: "Import Messages",
          systemImage: "arrow.down.message",
          isLoading: appState.isImporting,
          isDisabled: !viewModel.allRequiredPermissionsGranted
        ) {
          Task {
            await viewModel.continueFromPermissions()
          }
        }
        .frame(maxWidth: 320)
        .keyboardShortcut(.return, modifiers: [])

        Button("Skip for now") {
          Task {
            await appState.skipImport()
          }
        }
        .buttonStyle(.plain)
        .font(Theme.Typography.caption)
        .foregroundStyle(Theme.Colors.textTertiary)
      }
    }
    .frame(maxWidth: 560)
    .frame(maxWidth: .infinity)
    .task {
      await viewModel.refreshPermissionStatuses()
    }
    .sheet(isPresented: $showFullDiskAccessGuide) {
      FullDiskAccessGuideSheet {
        viewModel.openSystemSettings(for: .fullDiskAccess)
      }
    }
  }

  private var requiredPermissionsHint: String {
    if viewModel.permissionStatuses[.fullDiskAccess] != .granted {
      return "Full Disk Access is required to read iMessage history. Enable it in System Settings."
    }
    if viewModel.permissionStatuses[.contacts] != .granted {
      return "Contacts access is required to match messages with people you know."
    }
    return "Grant required permissions to continue."
  }

  private func handlePermissionRequest(_ permission: PermissionType) {
    if permission == .fullDiskAccess {
      showFullDiskAccessGuide = true
      return
    }

    Task {
      await viewModel.requestPermission(permission)
    }
  }
}

#Preview {
  PermissionsView(viewModel: OnboardingViewModel(appState: AppState(container: .preview)))
    .environment(AppState(container: .preview))
    .padding()
    .rolaBackground()
    .frame(width: 960, height: 640)
}
