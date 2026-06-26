import SwiftUI

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: ReplySuggestion
    var isGenerating: Bool = false
    var errorMessage: String?
    var onApprove: () -> Void
    var onEdit: (String) -> Void
    var onDismiss: () -> Void
    var onGenerate: () -> Void

    @State private var isEditing = false
    @State private var editedText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header

            if isGenerating {
                generatingView
            } else if let error = errorMessage {
                errorView(error)
            } else if suggestion.safetyBlocked || suggestion.status == .blocked {
                blockedView
            } else if suggestion.status == .failed {
                failedView
            } else if suggestion.isActionable {
                suggestionContent
            } else {
                resolvedView
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.Colors.accent)
            Text("AI Suggestion")
                .font(Theme.Typography.callout.weight(.semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            if suggestion.isActionable {
                ConfidenceBadge(level: suggestion.confidenceLevel)
            }
        }
    }

    private var generatingView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .controlSize(.small)
                .tint(Theme.Colors.accent)
            Text("Generating reply in your voice…")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label(message, systemImage: "exclamationmark.triangle")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.warning)

            Button("Try Again", action: onGenerate)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var blockedView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label(
                suggestion.safetyReason ?? "This message needs a personal reply from you.",
                systemImage: "hand.raised"
            )
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Colors.textSecondary)

            Button("Dismiss", action: onDismiss)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var failedView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label(
                suggestion.reasoning ?? "Could not generate a suggestion.",
                systemImage: "exclamationmark.triangle"
            )
            .font(Theme.Typography.callout)
            .foregroundStyle(Theme.Colors.warning)

            Button("Try Again", action: onGenerate)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var suggestionContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if isEditing {
                TextEditor(text: $editedText)
                    .font(Theme.Typography.body)
                    .frame(minHeight: 60, maxHeight: 120)
                    .padding(Theme.Spacing.xs)
                    .background(Theme.Colors.background, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
            } else {
                Text(suggestion.displayText)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .textSelection(.enabled)
                    .padding(Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.background, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
            }

            if let reasoning = suggestion.reasoning, !reasoning.isEmpty, !isEditing {
                Text(reasoning)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .italic()
            }

            actionButtons
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if isEditing {
                Button("Save & Copy") {
                    onEdit(editedText)
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.accent)

                Button("Cancel") {
                    isEditing = false
                    editedText = suggestion.displayText
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    onApprove()
                } label: {
                    Label("Approve & Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Colors.accent)

                Button("Edit") {
                    editedText = suggestion.displayText
                    isEditing = true
                }
                .buttonStyle(.bordered)

                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.bordered)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private var resolvedView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: resolvedIcon)
                .foregroundStyle(resolvedColor)
            Text(resolvedText)
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var resolvedIcon: String {
        switch suggestion.status {
        case .approved: "checkmark.circle.fill"
        case .edited: "pencil.circle.fill"
        case .dismissed: "xmark.circle.fill"
        default: "circle"
        }
    }

    private var resolvedColor: Color {
        switch suggestion.status {
        case .approved, .edited: Theme.Colors.success
        default: Theme.Colors.textTertiary
        }
    }

    private var resolvedText: String {
        switch suggestion.status {
        case .approved: "Copied to clipboard — paste in Messages"
        case .edited: "Edited reply copied to clipboard"
        case .dismissed: "Suggestion dismissed"
        default: ""
        }
    }
}

#Preview {
    SuggestionCard(
        suggestion: ReplySuggestion(
            id: UUID(),
            chatId: 1,
            incomingMessageId: 103,
            incomingMessageText: "Are you free Thursday?",
            replyText: "Sure! How about 3pm?",
            confidence: 0.85,
            reasoning: "Casual tone matching your style with Alex.",
            status: .pending,
            safetyBlocked: false,
            safetyReason: nil,
            createdAt: Date()
        ),
        onApprove: {},
        onEdit: { _ in },
        onDismiss: {},
        onGenerate: {}
    )
    .padding()
    .frame(width: 420)
    .rolaBackground()
}
