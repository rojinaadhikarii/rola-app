import SwiftUI

// MARK: - Toast Banner

struct ToastBanner: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(Theme.Typography.callout)
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let systemImage: String
    var duration: TimeInterval = 2.5

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if isPresented {
                ToastBanner(message: message, systemImage: systemImage)
                    .padding(.top, Theme.Spacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(Theme.Motion.fast) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .animation(Theme.Motion.fast, value: isPresented)
    }
}

extension View {
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        systemImage: String = "checkmark.circle.fill"
    ) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, systemImage: systemImage))
    }
}

#Preview {
    Color.clear
        .toast(isPresented: .constant(true), message: "Copied to clipboard")
        .frame(width: 400, height: 200)
        .rolaBackground()
}
