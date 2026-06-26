import SwiftUI

// MARK: - ROLA Button

enum ROLAButtonStyle {
    case primary
    case secondary
    case ghost
}

struct ROLAButton: View {
    let title: String
    var style: ROLAButtonStyle = .primary
    var systemImage: String?
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(foregroundColor)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(title)
                    .font(Theme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.lg)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: Theme.Colors.textPrimary
        case .secondary, .ghost: Theme.Colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: Theme.Colors.accent
        case .secondary: Theme.Colors.surfaceElevated
        case .ghost: .clear
        }
    }
}

// MARK: - ROLA Icon Button

struct ROLAIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        ROLAButton(title: "Get Started", systemImage: "arrow.right") {}
        ROLAButton(title: "Back", style: .secondary) {}
        ROLAButton(title: "Loading", isLoading: true) {}
    }
    .padding()
    .rolaBackground()
}
