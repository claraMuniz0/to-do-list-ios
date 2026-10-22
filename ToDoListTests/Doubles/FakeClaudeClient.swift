@testable import MyApp

/// Replays queued outcomes in order and records every request, so feature tests never reach Claude.
final class FakeClaudeClient: ClaudeClient {
    private var outcomes: [Result<ClaudeResponse, ClaudeError>]
    private(set) var receivedRequests: [ClaudeRequest] = []

    init(outcomes: [Result<ClaudeResponse, ClaudeError>] = []) {
        self.outcomes = outcomes
    }

    func enqueue(_ response: ClaudeResponse) { outcomes.append(.success(response)) }
    func enqueue(_ error: ClaudeError) { outcomes.append(.failure(error)) }

    func send(_ request: ClaudeRequest) async throws -> ClaudeResponse {
        receivedRequests.append(request)
        guard !outcomes.isEmpty else { throw ClaudeError.invalidResponse }
        return try outcomes.removeFirst().get()
    }
}
