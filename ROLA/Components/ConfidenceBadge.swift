import SwiftUI

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let level: ConfidenceLevel

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: level.systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(level.title)
                .font(Theme.Typography.caption2)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch level {
        case .high: Theme.Colors.success
        case .medium: Theme.Colors.warning
        case .low: Theme.Colors.error
        }
    }
}

#Preview {
    HStack {
        ConfidenceBadge(level: .high)
        ConfidenceBadge(level: .medium)
        ConfidenceBadge(level: .low)
    }
    .padding()
    .rolaBackground()
}
