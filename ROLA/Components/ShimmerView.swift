import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Theme.Colors.textTertiary.opacity(0.18),
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Conversation Row Skeleton

struct ConversationRowSkeleton: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Theme.Colors.surfaceElevated)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(height: 12)
                    .frame(maxWidth: 140)

                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(height: 10)
            }
        }
        .padding(Theme.Spacing.md)
        .shimmer()
    }
}

#Preview {
    VStack {
        ConversationRowSkeleton()
        ConversationRowSkeleton()
    }
    .padding()
    .rolaBackground()
}
