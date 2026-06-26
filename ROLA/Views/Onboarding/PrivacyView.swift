import SwiftUI

// MARK: - Privacy View

struct PrivacyView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.accentMuted)
                        .frame(width: 72, height: 72)

                    Image(systemName: "lock.shield")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Theme.Colors.accent)
                }

                VStack(spacing: Theme.Spacing.md) {
                    Text("Your messages stay on your Mac")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("ROLA reads iMessage history locally to learn your style. We never upload your conversations.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    PrivacyBullet(
                        systemImage: "checkmark.circle.fill",
                        text: "Messages are processed entirely on your device"
                    )
                    PrivacyBullet(
                        systemImage: "checkmark.circle.fill",
                        text: "Only style profiles sync to the cloud — never raw message content"
                    )
                    PrivacyBullet(
                        systemImage: "checkmark.circle.fill",
                        text: "ROLA never sends messages without your explicit approval"
                    )
                    PrivacyBullet(
                        systemImage: "checkmark.circle.fill",
                        text: "You can delete your data at any time"
                    )
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: 480)
                .rolaCard()
            }

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Text("Full Disk Access is required to read iMessage history. You'll grant this in the next step.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)

                ROLAButton(
                    title: "I Understand",
                    systemImage: "arrow.right",
                    action: onContinue
                )
                .frame(maxWidth: 320)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PrivacyView(onContinue: {})
        .padding()
        .rolaBackground()
        .frame(width: 960, height: 640)
}
