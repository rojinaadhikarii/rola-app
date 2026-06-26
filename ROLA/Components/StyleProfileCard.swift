import SwiftUI

// MARK: - Style Trait Row

struct StyleTraitRow: View {
    let label: String
    let value: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(width: 20)
            }

            Text(label)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

// MARK: - Style Profile Card

struct StyleProfileCard: View {
    let profile: StyleProfile
    var showRelationship: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header

            Text(profile.traits.toneSummary.capitalized)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)

            Divider().background(Theme.Colors.borderSubtle)

            VStack(spacing: Theme.Spacing.sm) {
                StyleTraitRow(
                    label: "Avg. length",
                    value: String(format: "%.0f words", profile.traits.averageWordCount),
                    systemImage: "text.alignleft"
                )
                StyleTraitRow(
                    label: "Emoji use",
                    value: String(format: "%.1f per message", profile.traits.emojiRate),
                    systemImage: "face.smiling"
                )
                StyleTraitRow(
                    label: "Lowercase",
                    value: String(format: "%.0f%%", profile.traits.lowercaseRate * 100),
                    systemImage: "textformat"
                )
                StyleTraitRow(
                    label: "Messages analyzed",
                    value: "\(profile.traits.messageCount)",
                    systemImage: "bubble.left"
                )
            }

            if !profile.traits.topEmojis.isEmpty {
                emojiRow
            }

            if !profile.traits.topWords.isEmpty {
                tagRow(title: "Common words", items: profile.traits.topWords)
            }
        }
        .padding(Theme.Spacing.lg)
        .rolaCard()
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentMuted)
                    .frame(width: 40, height: 40)

                if profile.scope == .global {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Theme.Colors.accent)
                } else {
                    Text(String(profile.displayName?.prefix(1) ?? "?"))
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName ?? "Profile")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                if showRelationship && profile.scope == .contact {
                    Label(profile.relationship.title, systemImage: profile.relationship.systemImage)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()
        }
    }

    private var emojiRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Top emoji")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            ForEach(profile.traits.topEmojis, id: \.self) { emoji in
                Text(emoji)
                    .font(.system(size: 20))
            }

            Spacer()
        }
    }

    private func tagRow(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            FlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    StyleProfileCard(profile: MockStyleData.sampleResult.globalProfile)
        .padding()
        .rolaBackground()
        .frame(width: 400)
}
