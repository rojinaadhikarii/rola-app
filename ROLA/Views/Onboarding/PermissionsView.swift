import SwiftUI

// MARK: - Permissions View

struct PermissionsView: View {
  @Bindable var viewModel: OnboardingViewModel
  @Environment(AppState.self) private var appState

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
              onRequest: {
                Task {
                  await viewModel.requestPermission(permission)
                }
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
        if viewModel.permissionStatuses[.fullDiskAccess] != .granted {
          Text("Full Disk Access must be enabled in System Settings. Click \"Set Up\" for instructions.")
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 400)
        }

        ROLAButton(
          title: "Import Messages",
          systemImage: "arrow.down.message",
          isLoading: appState.isImporting
        ) {
          Task {
            await viewModel.continueFromPermissions()
          }
        }
        .frame(maxWidth: 320)
        .keyboardShortcut(.return, modifiers: [])

        Button("Skip for now") {
          Task {
            await appState.simulateImport()
          }
        }
        .buttonStyle(.plain)
        .font(Theme.Typography.caption)
        .foregroundStyle(Theme.Colors.textTertiary)
      }
    }
    .frame(maxWidth: 560)
    .frame(maxWidth: .infinity)
    .onAppear {
      viewModel.refreshPermissionStatuses()
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
