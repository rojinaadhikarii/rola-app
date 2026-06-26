import SwiftUI

// MARK: - Page Indicator

struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Theme.Colors.accent : Theme.Colors.border)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(Theme.Motion.standard, value: currentPage)
            }
        }
    }
}

#Preview {
    PageIndicator(totalPages: 3, currentPage: 1)
        .padding()
        .rolaBackground()
}
