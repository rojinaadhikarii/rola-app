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

    func clear() {
        analysisResult = nil
        lastAnalyzedAt = nil
        analysisError = nil
        try? FileManager.default.removeItem(at: cacheURL)
    }

    // MARK: - Cache

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
