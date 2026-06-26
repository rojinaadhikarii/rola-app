import SwiftUI

// MARK: - Welcome View

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.Spacing.xl) {
                ROLALogoMark(size: 72)

                VStack(spacing: Theme.Spacing.md) {
                    Text("ROLA")
                        .font(Theme.Typography.largeTitle)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Your AI relationship copilot")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Text("Stay connected without the mental burden of everyday messages. ROLA drafts replies that sound like you — always in your control.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
                    .padding(.top, Theme.Spacing.sm)
            }

            Spacer()

            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.md) {
                    FeatureRow(
                        systemImage: "text.bubble",
                        title: "Sounds like you",
                        description: "Learns your tone for every relationship"
                    )
                    FeatureRow(
                        systemImage: "calendar",
                        title: "Context-aware",
                        description: "Considers your calendar and conversation history"
                    )
                    FeatureRow(
                        systemImage: "hand.raised",
                        title: "You're in control",
                        description: "Review, edit, or dismiss every suggestion"
                    )
                }
                .frame(maxWidth: 440)

                ROLAButton(
                    title: "Get Started",
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
    WelcomeView(onContinue: {})
        .padding()
        .rolaBackground()
        .frame(width: 960, height: 640)
}
