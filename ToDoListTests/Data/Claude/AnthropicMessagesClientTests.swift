import Foundation
import Testing
@testable import MyApp

@Suite(.serialized)
struct AnthropicMessagesClientTests {
    private let request = ClaudeRequest(
        systemPrompt: "You turn text into tasks.",
        userMessage: "Buy milk tomorrow",
        tool: ClaudeTool(
            name: "create_task",
            description: "Creates a task draft.",
            inputSchema: .object(["type": .string("object")])
        ),
        maxTokens: 256
    )

    private func makeClient(key: String? = "test-key", baseURL: URL? = nil) -> AnthropicMessagesClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return AnthropicMessagesClient(
            apiKeyProvider: APIKeyProviderStub(key: key, baseURL: baseURL ?? ClaudeEndpoint.defaultBaseURL),
            session: URLSession(configuration: configuration)
        )
    }

    private func respond(status: Int = 200, body: String = "{}") {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
    }

    private let toolUseBody = """
    {"content":[{"type":"text","text":"ok"},{"type":"tool_use","id":"t1","name":"create_task","input":{"title":"Buy milk"}}]}
    """

    @Test func postsToTheMessagesEndpointWithAuthHeaders() async throws {
        var captured: URLRequest?
        StubURLProtocol.handler = { request in
            captured = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(toolUseBody.utf8))
        }
        _ = try await makeClient().send(request)

        let sent = try #require(captured)
        #expect(sent.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(sent.httpMethod == "POST")
        #expect(sent.value(forHTTPHeaderField: "authorization") == "Bearer test-key")
        #expect(sent.value(forHTTPHeaderField: "x-api-key") == nil)
        #expect(sent.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        #expect(sent.value(forHTTPHeaderField: "content-type") == "application/json")
        #expect(sent.timeoutInterval == 20)
    }

    @Test func postsToTheConfiguredBaseURL() async throws {
        var captured: URLRequest?
        StubURLProtocol.handler = { request in
            captured = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(toolUseBody.utf8))
        }
        _ = try await makeClient(baseURL: URL(string: "https://gateway.example.com/proxy")!).send(request)

        #expect(captured?.url?.absoluteString == "https://gateway.example.com/proxy/v1/messages")
    }

    @Test func bodyForcesTheToolCall() async throws {
        var body: Data?
        StubURLProtocol.handler = { request in
            body = request.httpBody
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(toolUseBody.utf8))
        }
        _ = try await makeClient().send(request)

        let bodyData = try #require(body)
        let json = try #require(JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(json["model"] as? String == "claude-haiku-5-5")
        #expect(json["max_tokens"] as? Int == 256)
        #expect(json["system"] as? String == "You turn text into tasks.")
        let messages = try #require(json["messages"] as? [[String: Any]])
        #expect(messages.count == 1)
        #expect(messages[0]["role"] as? String == "user")
        #expect(messages[0]["content"] as? String == "Buy milk tomorrow")
        let tools = try #require(json["tools"] as? [[String: Any]])
        #expect(tools.count == 1)
        #expect(tools[0]["name"] as? String == "create_task")
        #expect(tools[0]["description"] as? String == "Creates a task draft.")
        #expect((tools[0]["input_schema"] as? [String: Any])?["type"] as? String == "object")
        let choice = try #require(json["tool_choice"] as? [String: Any])
        #expect(choice["type"] as? String == "tool")
        #expect(choice["name"] as? String == "create_task")
    }

    @Test func returnsTheToolInputAsJSON() async throws {
        respond(body: toolUseBody)
        let response = try await makeClient().send(request)

        #expect(response.toolName == "create_task")
        let input = try #require(JSONSerialization.jsonObject(with: response.toolInput) as? [String: String])
        #expect(input == ["title": "Buy milk"])
    }

    @Test func throwsMissingAPIKeyWithoutCallingTheNetwork() async {
        var called = false
        StubURLProtocol.handler = { request in
            called = true
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(toolUseBody.utf8))
        }
        for key in [nil, "", "   "] as [String?] {
            await #expect(throws: ClaudeError.missingAPIKey) { try await makeClient(key: key).send(request) }
        }
        #expect(!called)
    }

    @Test func throwsInvalidResponseWhenNoToolUseBlockComesBack() async {
        respond(body: #"{"content":[{"type":"text","text":"hello"}]}"#)
        await #expect(throws: ClaudeError.invalidResponse) { try await makeClient().send(request) }
    }

    @Test func throwsInvalidResponseOnMalformedBody() async {
        respond(body: "not json")
        await #expect(throws: ClaudeError.invalidResponse) { try await makeClient().send(request) }
    }

    @Test(arguments: [
        (401, ClaudeError.unauthorized),
        (403, ClaudeError.unauthorized),
        (429, ClaudeError.rateLimited),
        (500, ClaudeError.serverError(500)),
        (529, ClaudeError.serverError(529)),
        (400, ClaudeError.serverError(400))
    ])
    func mapsHTTPStatusToClaudeError(status: Int, expected: ClaudeError) async {
        respond(status: status)
        await #expect(throws: expected) { try await makeClient().send(request) }
    }

    @Test(arguments: [
        (URLError.Code.timedOut, ClaudeError.timeout),
        (URLError.Code.notConnectedToInternet, ClaudeError.offline),
        (URLError.Code.networkConnectionLost, ClaudeError.offline),
        (URLError.Code.cannotConnectToHost, ClaudeError.offline)
    ])
    func mapsTransportFailureToClaudeError(code: URLError.Code, expected: ClaudeError) async {
        StubURLProtocol.handler = { _ in throw URLError(code) }
        await #expect(throws: expected) { try await makeClient().send(request) }
    }
}
