import SwiftUI

// MARK: - Communication Profile View

struct CommunicationProfileView: View {
    let result: StyleAnalysisResult?
    var isLoading: Bool = false
    var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                loadingState
            } else if let errorMessage {
                errorState(message: errorMessage)
            } else if let result {
                profileContent(result: result)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .controlSize(.regular)
                .tint(Theme.Colors.accent)
            Text("Analyzing your communication style…")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func errorState(message: String) -> some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "Style analysis unavailable",
            message: message
        )
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "text.bubble",
            title: "No style profile yet",
            message: "Import your messages to generate a communication profile that learns how you write."
        )
    }

    private func profileContent(result: StyleAnalysisResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                overviewHeader(result: result)

                StyleProfileCard(profile: result.globalProfile, showRelationship: false)

                if !result.contactProfiles.isEmpty {
                    contactProfilesSection(result: result)
                }
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private func overviewHeader(result: StyleAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Your communication profile")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Analyzed \(result.totalMessagesAnalyzed) of your sent messages across \(result.contactProfiles.count + 1) contexts.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("Last updated \(result.analyzedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    private func contactProfilesSection(result: StyleAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Relationship-specific tone")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("ROLA adapts your voice based on who you're talking to.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            ForEach(result.contactProfiles.prefix(8)) { profile in
                StyleProfileCard(profile: profile)
            }
        }
    }
}

#Preview {
    CommunicationProfileView(result: MockStyleData.sampleResult)
        .frame(width: 600, height: 700)
        .rolaBackground()
}
