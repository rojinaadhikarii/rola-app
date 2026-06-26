import Foundation

// MARK: - Style Engine

struct StyleEngine: StyleEngineProtocol {

    private let reader: ChatDBReader
    private let messageLimit: Int

    init(reader: ChatDBReader = ChatDBReader(), messageLimit: Int = 5_000) {
        self.reader = reader
        self.messageLimit = messageLimit
    }

    func analyzeStyle(onProgress: (@Sendable (Double) -> Void)?) async throws -> StyleAnalysisResult {
        guard FullDiskAccessChecker.isGranted else {
            throw MessageImportError.fullDiskAccessRequired
        }

        return try await Task.detached { [reader, messageLimit] in
            onProgress?(0.1)

            let rows = try reader.fetchOutgoingMessages(limit: messageLimit)
            onProgress?(0.5)

            let samples = rows.compactMap { row -> StyleMessageSample? in
                let text = row.text ?? AttributedBodyDecoder.decodeText(from: row.attributedBody)
                guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return nil
                }
                return StyleMessageSample(
                    text: text,
                    chatId: row.chatId,
                    displayName: row.chatDisplayName ?? "Contact",
                    isGroup: row.isGroup
                )
            }

            onProgress?(0.8)

            guard samples.count >= StyleAnalyzer.minimumGlobalMessages else {
                throw StyleAnalysisError.insufficientData(
                    required: StyleAnalyzer.minimumGlobalMessages,
                    found: samples.count
                )
            }

            let result = StyleAnalyzer.buildProfiles(from: samples)
            onProgress?(1.0)
            return result
        }.value
    }
}

// MARK: - Style Analysis Error

enum StyleAnalysisError: LocalizedError {
    case insufficientData(required: Int, found: Int)

    var errorDescription: String? {
        switch self {
        case .insufficientData(let required, let found):
            "Need at least \(required) of your sent messages to build a style profile. Found \(found)."
        }
    }
}
