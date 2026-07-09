import SwiftUI

// MARK: - Empty State View

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentMuted)
                    .frame(width: 72, height: 72)

                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .scaleEffect(isVisible ? 1 : 0.85)
            .opacity(isVisible ? 1 : 0)

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(message)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            .offset(y: isVisible ? 0 : 8)
            .opacity(isVisible ? 1 : 0)

            if let actionTitle, let action {
                ROLAButton(title: actionTitle, style: .secondary, action: action)
                    .frame(maxWidth: 200)
                    .opacity(isVisible ? 1 : 0)
            }
        }
        .padding(Theme.Spacing.xl)
        .onAppear {
            withAnimation(Theme.Motion.slow) {
                isVisible = true
            }
        }
    }
}

#Preview {
    EmptyStateView(
        systemImage: "message",
        title: "No messages yet",
        message: "Import your messages to get started.",
        actionTitle: "Import"
    ) {}
    .rolaBackground()
}
