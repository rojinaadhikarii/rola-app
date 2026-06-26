import SwiftUI

// MARK: - Full Disk Access Guide Sheet

struct FullDiskAccessGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onOpenSettings: () -> Void

    private let steps: [(icon: String, text: String)] = [
        ("gearshape", "Open System Settings → Privacy & Security"),
        ("internaldrive", "Select Full Disk Access"),
        ("plus.circle", "Click + and add ROLA (or toggle it on)"),
        ("arrow.uturn.left", "Return to ROLA — access is detected automatically"),
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)

                Text("Enable Full Disk Access")
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("ROLA needs this to read your iMessage history locally. Your messages never leave your Mac.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Text("\(index + 1)")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 20, height: 20)
                            .background(Theme.Colors.accentMuted)
                            .clipShape(Circle())

                        Image(systemName: step.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 20)

                        Text(step.text)
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .rolaCard()

            HStack(spacing: Theme.Spacing.md) {
                ROLAButton(title: "Cancel", style: .secondary) {
                    dismiss()
                }

                ROLAButton(title: "Open System Settings", systemImage: "gearshape") {
                    onOpenSettings()
                    dismiss()
                }
            }
            .frame(maxWidth: 400)
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 480)
        .rolaBackground()
    }
}

#Preview {
    FullDiskAccessGuideSheet(onOpenSettings: {})
}
