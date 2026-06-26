import SwiftUI

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            avatar

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(conversation.displayName)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    if let _ = conversation.lastMessageDate {
                        Text(conversation.formattedDate)
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                HStack(spacing: Theme.Spacing.sm) {
                    Text(conversation.lastMessagePreview)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(
                            conversation.needsReply
                                ? Theme.Colors.textSecondary
                                : Theme.Colors.textTertiary
                        )
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    if conversation.needsReply {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(isSelected ? Theme.Colors.surfaceElevated : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    conversation.isGroup
                        ? Theme.Colors.accentMuted
                        : Theme.Colors.surfaceElevated
                )
                .frame(width: 44, height: 44)

            if conversation.isGroup {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)
            } else {
                Text(conversation.initials)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ConversationRow(
            conversation: MockConversationData.sample[0],
            isSelected: true
        )
        ConversationRow(
            conversation: MockConversationData.sample[2],
            isSelected: false
        )
    }
    .padding()
    .rolaBackground()
}
