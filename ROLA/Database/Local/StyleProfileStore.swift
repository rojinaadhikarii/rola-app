import Foundation

// MARK: - Style Profile Store

@MainActor
@Observable
final class StyleProfileStore {

    private(set) var analysisResult: StyleAnalysisResult?
    private(set) var isAnalyzing = false
    private(set) var analysisError: String?
    private(set) var lastAnalyzedAt: Date?

    private let styleEngine: StyleEngineProtocol
    private let cacheURL: URL

    init(styleEngine: StyleEngineProtocol) {
        self.styleEngine = styleEngine
        self.cacheURL = Self.makeCacheURL()
        loadFromCache()
    }

    var globalProfile: StyleProfile? {
        analysisResult?.globalProfile
    }

    var contactProfiles: [StyleProfile] {
        analysisResult?.contactProfiles ?? []
    }

    var hasProfile: Bool {
        globalProfile != nil
    }

    func analyze(onProgress: (@Sendable (Double) -> Void)? = nil) async {
        isAnalyzing = true
        analysisError = nil
        defer { isAnalyzing = false }

        do {
            let result = try await styleEngine.analyzeStyle(onProgress: onProgress)
            analysisResult = result
            lastAnalyzedAt = result.analyzedAt
            saveToCache()
        } catch {
            analysisError = error.localizedDescription
        }
    }

    func profile(for chatId: Int64) -> StyleProfile? {
        contactProfiles.first { $0.chatId == chatId }
    }

    func applyLearning(
        feedback: UserFeedback,
        displayName: String,
        isGroup: Bool
    ) {
        guard LearningEngine.shouldLearn(from: feedback.action) else { return }

        if var result = analysisResult {
            result = applyLearningToResult(
                result,
                feedback: feedback,
                displayName: displayName,
                isGroup: isGroup
            )
            analysisResult = result
            lastAnalyzedAt = result.analyzedAt
            saveToCache()
            return
        }

        let contact = LearningEngine.newContactProfile(
            chatId: feedback.chatId,
            displayName: displayName,
            isGroup: isGroup,
            finalText: feedback.finalText
        )
        let result = StyleAnalysisResult(
            globalProfile: LearningEngine.updatedGlobalProfile(
                .global(traits: contact.traits),
                finalText: feedback.finalText
            ),
            contactProfiles: [contact],
            analyzedAt: Date(),
            totalMessagesAnalyzed: 1
        )
        analysisResult = result
        lastAnalyzedAt = result.analyzedAt
        saveToCache()
    }

    func mergeRemoteProfiles(_ remoteProfiles: [RemoteStyleProfile]) {
        guard !remoteProfiles.isEmpty else { return }

        var global = analysisResult?.globalProfile
        var contactMap = Dictionary(
            uniqueKeysWithValues: (analysisResult?.contactProfiles ?? []).compactMap { profile -> (String, StyleProfile)? in
                guard let chatId = profile.chatId else { return nil }
                return (ContactHasher.hash(chatId: chatId), profile)
            }
        )

        for remote in remoteProfiles {
            if remote.scope == "global" {
                if let existing = global {
                    if remote.updatedAt > existing.analyzedAt {
                        global = StyleProfile.global(traits: remote.traits, analyzedAt: remote.updatedAt)
                    }
                } else {
                    global = StyleProfile.global(traits: remote.traits, analyzedAt: remote.updatedAt)
                }
            } else if remote.scope == "contact", let hash = remote.contactHash {
                if let existing = contactMap[hash] {
                    if remote.updatedAt > existing.analyzedAt {
                        contactMap[hash] = StyleProfile(
                            id: existing.id,
                            scope: existing.scope,
                            chatId: existing.chatId,
                            displayName: existing.displayName,
                            relationship: existing.relationship,
                            traits: remote.traits,
                            analyzedAt: remote.updatedAt
                        )
                    }
                }
            }
        }

        guard let global else { return }

        analysisResult = StyleAnalysisResult(
            globalProfile: global,
            contactProfiles: Array(contactMap.values),
            analyzedAt: Date(),
            totalMessagesAnalyzed: analysisResult?.totalMessagesAnalyzed ?? global.traits.messageCount
        )
        lastAnalyzedAt = Date()
        saveToCache()
    }

    func clear() {
        analysisResult = nil
        lastAnalyzedAt = nil
        analysisError = nil
        try? FileManager.default.removeItem(at: cacheURL)
    }

    // MARK: - Cache

    private func applyLearningToResult(
        _ result: StyleAnalysisResult,
        feedback: UserFeedback,
        displayName: String,
        isGroup: Bool
    ) -> StyleAnalysisResult {
        let updatedGlobal = LearningEngine.updatedGlobalProfile(
            result.globalProfile,
            finalText: feedback.finalText
        )

        var contactProfiles = result.contactProfiles
        if let index = contactProfiles.firstIndex(where: { $0.chatId == feedback.chatId }) {
            contactProfiles[index] = LearningEngine.updatedContactProfile(
                contactProfiles[index],
                finalText: feedback.finalText
            )
        } else {
            contactProfiles.append(
                LearningEngine.newContactProfile(
                    chatId: feedback.chatId,
                    displayName: displayName,
                    isGroup: isGroup,
                    finalText: feedback.finalText
                )
            )
        }

        let totalMessages = result.totalMessagesAnalyzed + 1
        return StyleAnalysisResult(
            globalProfile: updatedGlobal,
            contactProfiles: contactProfiles,
            analyzedAt: Date(),
            totalMessagesAnalyzed: totalMessages
        )
    }

    private func loadFromCache() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return }

        do {
            let data = try Data(contentsOf: cacheURL)
            analysisResult = try JSONDecoder().decode(StyleAnalysisResult.self, from: data)
            lastAnalyzedAt = analysisResult?.analyzedAt
        } catch {
            analysisError = "Could not load cached style profile."
        }
    }

    private func saveToCache() {
        guard let analysisResult else { return }

        do {
            let data = try JSONEncoder().encode(analysisResult)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            analysisError = "Could not save style profile."
        }
    }

    private static func makeCacheURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let directory = appSupport.appendingPathComponent("com.rola.app", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("style-profile.json")
    }
}
