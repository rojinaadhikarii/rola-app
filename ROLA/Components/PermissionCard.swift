import SwiftUI

// MARK: - Permission Card

struct PermissionCard: View {
    let permission: PermissionType
    let status: PermissionStatus
    var isLoading: Bool = false
    var showOpenSettingsAction: Bool = false
    let onRequest: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            iconView

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(permission.title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    if permission.isRequired {
                        Text("Required")
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.accentMuted)
                            .clipShape(Capsule())
                    }
                }

                Text(permission.subtitle)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Theme.Spacing.md)

            actionView
        }
        .padding(Theme.Spacing.md)
        .rolaCard()
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Colors.surfaceElevated)
                .frame(width: 44, height: 44)

            Image(systemName: permission.systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(status == .granted ? Theme.Colors.success : Theme.Colors.accent)
        }
    }

    @ViewBuilder
    private var actionView: some View {
        switch status {
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.Colors.success)
                .symbolRenderingMode(.hierarchical)

        case .denied, .restricted:
            Button("Open Settings") {
                onOpenSettings()
            }
            .buttonStyle(.plain)
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.accent)

        case .notDetermined:
            if showOpenSettingsAction {
                Button("Open Settings") {
                    onOpenSettings()
                }
                .buttonStyle(.plain)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.accent)
            } else {
                Button {
                    onRequest()
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(permission == .fullDiskAccess ? "Set Up" : "Allow")
                                .font(Theme.Typography.caption)
                        }
                    }
                    .frame(width: 64, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.Colors.textPrimary)
                .background(Theme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                .disabled(isLoading)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PermissionCard(
            permission: .fullDiskAccess,
            status: .notDetermined,
            onRequest: {},
            onOpenSettings: {}
        )
        PermissionCard(
            permission: .contacts,
            status: .granted,
            onRequest: {},
            onOpenSettings: {}
        )
    }
    .padding()
    .rolaBackground()
}
