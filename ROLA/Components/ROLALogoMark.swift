import SwiftUI

// MARK: - ROLA Logo Mark

struct ROLALogoMark: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text("R")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 32, height: 32)
                .background(Theme.Colors.accentMuted)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(description)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Privacy Bullet

struct PrivacyBullet: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.success)
                .frame(width: 20)

            Text(text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Import Progress View

struct ImportProgressView: View {
    let progress: Double
    var phase: ImportPhase = .importingMessages
    var errorMessage: String?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if let errorMessage {
                errorContent(message: errorMessage)
            } else {
                progressContent
            }
        }
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Theme.Colors.warning)

            Text("Import failed")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }

    private var progressContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.border, lineWidth: 4)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Motion.fast, value: progress)

                Image(systemName: phase == .analyzingStyle ? "text.bubble" : "arrow.down.message")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(phase.title)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(phase.subtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            ProgressView(value: progress)
                .tint(Theme.Colors.accent)
                .frame(maxWidth: 280)
        }
    }
}

#Preview {
    ImportProgressView(progress: 0.6)
        .padding()
        .rolaBackground()
}
