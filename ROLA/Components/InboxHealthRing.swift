import SwiftUI

// MARK: - Inbox Health Ring

struct InboxHealthRing: View {
    let health: InboxHealth
    var size: CGFloat = 44

    @State private var animatedScore: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.borderSubtle, lineWidth: 4)

            Circle()
                .trim(from: 0, to: animatedScore)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Image(systemName: health.systemImage)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(ringColor)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(Theme.Motion.slow) {
                animatedScore = health.score
            }
        }
        .onChange(of: health.score) { _, newValue in
            withAnimation(Theme.Motion.slow) {
                animatedScore = newValue
            }
        }
        .accessibilityLabel(health.title)
    }

    private var ringColor: Color {
        switch health {
        case .excellent, .good: Theme.Colors.success
        case .attention: Theme.Colors.warning
        case .overloaded: Theme.Colors.error
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        InboxHealthRing(health: .excellent)
        InboxHealthRing(health: .attention)
        InboxHealthRing(health: .overloaded)
    }
    .padding()
    .rolaBackground()
}
