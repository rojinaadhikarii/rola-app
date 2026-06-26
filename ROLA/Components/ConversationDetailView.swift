import SwiftUI

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ImportedMessage

    var body: some View {
        HStack {
            if message.isFromMe { Spacer(minLength: 48) }

            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                Text(message.text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(message.isFromMe ? Theme.Colors.accent : Theme.Colors.surfaceElevated)
                    .clipShape(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    )

                Text(message.formattedTime)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            if !message.isFromMe { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Conversation Detail View

struct ConversationDetailView: View {
    let conversation: Conversation
    let messages: [ImportedMessage]
    let isLoading: Bool
    var schedulingHint: String?

    var body: some View {
        VStack(spacing: 0) {
            detailHeader

            if let schedulingHint {
                SchedulingHintBanner(hint: schedulingHint)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.sm)
            }

            Divider()
                .background(Theme.Colors.borderSubtle)

            if isLoading {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                    .tint(Theme.Colors.accent)
                Spacer()
            } else if messages.isEmpty {
                Spacer()
                EmptyStateView(
                    systemImage: "bubble.left",
                    title: "No messages",
                    message: "Could not load messages for this conversation."
                )
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(Theme.Spacing.lg)
                    }
                    .onAppear {
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Theme.Colors.background)
    }

    private var detailHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 36, height: 36)

                Text(conversation.initials)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.displayName)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(conversation.isGroup ? "Group · \(conversation.serviceName)" : conversation.serviceName)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()

            if conversation.needsReply {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 6, height: 6)
                    Text("Needs reply")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.accent)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.accentMuted)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }
}

#Preview {
    ConversationDetailView(
        conversation: MockConversationData.sample[0],
        messages: MockConversationData.messages(for: 1),
        isLoading: false
    )
    .frame(width: 500, height: 400)
    .rolaBackground()
}
