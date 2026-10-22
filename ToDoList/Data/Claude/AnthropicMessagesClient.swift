import Foundation

/// Talks to the Anthropic Messages API over plain `URLSession`; no SDK, no retries.
struct AnthropicMessagesClient: ClaudeClient {
    static let model = "claude-haiku-5-5"
    static let timeout: TimeInterval = 20
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let apiVersion = "2023-06-01"

    let apiKeyProvider: APIKeyProvider
    var session: URLSession = .shared

    func send(_ request: ClaudeRequest) async throws -> ClaudeResponse {
        guard let key = apiKeyProvider.apiKey()?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty else {
            throw ClaudeError.missingAPIKey
        }
        let (data, response) = try await perform(try urlRequest(for: request, key: key))
        try Self.validate(statusCode: response.statusCode)
        return try Self.decode(data)
    }

    private func urlRequest(for request: ClaudeRequest, key: String) throws -> URLRequest {
        var urlRequest = URLRequest(url: Self.endpoint, timeoutInterval: Self.timeout)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(key, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try JSONEncoder().encode(MessagesBody(request))
        return urlRequest
    }

    private func perform(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else { throw ClaudeError.invalidResponse }
            return (data, http)
        } catch let error as URLError {
            throw Self.map(error)
        }
    }

    private static func map(_ error: URLError) -> Error {
        switch error.code {
        case .timedOut: ClaudeError.timeout
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
             .cannotFindHost, .dataNotAllowed, .internationalRoamingOff: ClaudeError.offline
        case .cancelled: error
        default: ClaudeError.invalidResponse
        }
    }

    private static func validate(statusCode: Int) throws {
        switch statusCode {
        case 200..<300: return
        case 401, 403: throw ClaudeError.unauthorized
        case 429: throw ClaudeError.rateLimited
        default: throw ClaudeError.serverError(statusCode)
        }
    }

    private static func decode(_ data: Data) throws -> ClaudeResponse {
        guard let body = try? JSONDecoder().decode(ResponseBody.self, from: data),
              let toolUse = body.content.first(where: { $0.type == "tool_use" }),
              let name = toolUse.name, let input = toolUse.input,
              let encoded = try? JSONEncoder().encode(input) else {
            throw ClaudeError.invalidResponse
        }
        return ClaudeResponse(toolName: name, toolInput: encoded)
    }
}

private struct MessagesBody: Encodable {
    struct Message: Encodable { let role: String; let content: String }
    struct Tool: Encodable {
        let name: String
        let description: String
        let inputSchema: JSONValue
        enum CodingKeys: String, CodingKey { case name, description, inputSchema = "input_schema" }
    }
    struct ToolChoice: Encodable { let type: String; let name: String }

    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]
    let tools: [Tool]
    let toolChoice: ToolChoice
    enum CodingKeys: String, CodingKey { case model, system, messages, tools, maxTokens = "max_tokens", toolChoice = "tool_choice" }

    init(_ request: ClaudeRequest) {
        model = AnthropicMessagesClient.model
        maxTokens = request.maxTokens
        system = request.systemPrompt
        messages = [Message(role: "user", content: request.userMessage)]
        tools = [Tool(name: request.tool.name, description: request.tool.description, inputSchema: request.tool.inputSchema)]
        toolChoice = ToolChoice(type: "tool", name: request.tool.name)
    }
}

private struct ResponseBody: Decodable {
    struct Block: Decodable {
        let type: String
        let name: String?
        let input: JSONValue?
    }
    let content: [Block]
}
