import SwiftUI

// MARK: - Theme

/// Centralized design tokens for ROLA.
/// Dark mode first — inspired by Linear, Raycast, and Apple HIG.
enum Theme {

    // MARK: Colors

    enum Colors {
        static let background = Color(hex: 0x0A0A0B)
        static let surface = Color(hex: 0x141416)
        static let surfaceElevated = Color(hex: 0x1C1C1F)
        static let border = Color(hex: 0x2A2A2E)
        static let borderSubtle = Color(hex: 0x1F1F23)

        static let accent = Color(hex: 0x6366F1)
        static let accentMuted = Color(hex: 0x6366F1).opacity(0.15)

        static let textPrimary = Color(hex: 0xFAFAFA)
        static let textSecondary = Color(hex: 0xA1A1AA)
        static let textTertiary = Color(hex: 0x71717A)

        static let success = Color(hex: 0x22C55E)
        static let warning = Color(hex: 0xF59E0B)
        static let error = Color(hex: 0xEF4444)
    }

    // MARK: Typography

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title = Font.system(size: 28, weight: .semibold, design: .default)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 15, weight: .regular, design: .default)
        static let callout = Font.system(size: 14, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: Radius

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
    }

    // MARK: Animation

    enum Motion {
        static let fast: Animation = .easeInOut(duration: 0.2)
        static let standard: Animation = .easeInOut(duration: 0.35)
        static let slow: Animation = .spring(response: 0.5, dampingFraction: 0.85)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - View Modifiers

struct ROLABackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}

struct ROLACardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .stroke(Theme.Colors.borderSubtle, lineWidth: 1)
            )
    }
}

extension View {
    func rolaBackground() -> some View {
        modifier(ROLABackground())
    }

    func rolaCard() -> some View {
        modifier(ROLACardStyle())
    }
}
