import Foundation

// MARK: - OpenAI Error

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "OpenAI API key not configured. Add your key in Settings."
        case .invalidResponse:
            "Received an invalid response from OpenAI."
        case .apiError(let statusCode, let message):
            "OpenAI error (\(statusCode)): \(message)"
        case .decodingFailed:
            "Could not parse the AI response."
        }
    }
}

// MARK: - OpenAI Response

struct OpenAIGenerationResult: Sendable {
    let reply: String
    let confidence: Double
    let reasoning: String?
}

// MARK: - OpenAI Client

struct OpenAIClient: Sendable {

    private let session: URLSession
    private let model: String

    init(session: URLSession = .shared, model: String = "gpt-4o-mini") {
        self.session = session
        self.model = model
    }

    func generate(
        systemPrompt: String,
        userPrompt: String,
        apiKey: String
    ) async throws -> OpenAIGenerationResult {
        guard !apiKey.isEmpty else { throw OpenAIError.missingAPIKey }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt),
            ],
            responseFormat: .init(type: "json_object"),
            temperature: 0.8
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError(statusCode: http.statusCode, message: message)
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw OpenAIError.invalidResponse
        }

        return try parseGenerationJSON(content)
    }

    private func parseGenerationJSON(_ content: String) throws -> OpenAIGenerationResult {
        guard let data = content.data(using: .utf8) else {
            throw OpenAIError.decodingFailed
        }

        let parsed = try JSONDecoder().decode(GenerationJSON.self, from: data)
        guard !parsed.reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIError.decodingFailed
        }

        return OpenAIGenerationResult(
            reply: parsed.reply.trimmingCharacters(in: .whitespacesAndNewlines),
            confidence: min(max(parsed.confidence, 0), 1),
            reasoning: parsed.reasoning
        )
    }
}

// MARK: - API Models

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case responseFormat = "response_format"
    }
}

private struct ChatMessage: Encodable {
    let role: String
    let content: String
}

private struct ResponseFormat: Encodable {
    let type: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ResponseMessage
    }

    struct ResponseMessage: Decodable {
        let content: String
    }
}

private struct GenerationJSON: Decodable {
    let reply: String
    let confidence: Double
    let reasoning: String?
}
