import Foundation
import Testing
@testable import MyApp

struct ClaudeStepSuggesterTests {
    private func response(_ json: String, tool: String = "suggest_steps") -> ClaudeResponse {
        ClaudeResponse(toolName: tool, toolInput: Data(json.utf8))
    }

    private func suggest(
        _ client: FakeClaudeClient, existing: [String] = []
    ) async throws -> [String] {
        try await ClaudeStepSuggester(client: client)
            .suggest(title: "Plan trip", description: "Lisbon", existingSteps: existing.map { try! StepTitle($0) })
            .map(\.value)
    }

    @Test func decodesTheStepTitlesFromTheToolInput() async throws {
        let client = FakeClaudeClient(outcomes: [.success(response(#"{"steps":["Book flights","Reserve hotel"]}"#))])
        #expect(try await suggest(client) == ["Book flights", "Reserve hotel"])
    }

    @Test func dropsBlankAndOverlongTitlesInsteadOfFailing() async throws {
        let long = String(repeating: "x", count: 121)
        let client = FakeClaudeClient(outcomes: [.success(response(#"{"steps":["  ","\#(long)"," Pack bags "]}"#))])
        #expect(try await suggest(client) == ["Pack bags"])
    }

    @Test func forcesTheSuggestStepsToolAndSendsTheTaskAndExistingSteps() async throws {
        let client = FakeClaudeClient(outcomes: [.success(response(#"{"steps":[]}"#))])
        _ = try await suggest(client, existing: ["Pick dates"])
        let request = try #require(client.receivedRequests.first)
        #expect(request.tool.name == "suggest_steps")
        #expect(request.userMessage.contains("Plan trip"))
        #expect(request.userMessage.contains("Lisbon"))
        #expect(request.userMessage.contains("Pick dates"))
        #expect(request.systemPrompt == ClaudeStepSuggester.systemPrompt)
    }

    @Test func omitsTheExistingStepsSectionWhenThereAreNone() async throws {
        let client = FakeClaudeClient(outcomes: [.success(response(#"{"steps":[]}"#))])
        _ = try await suggest(client)
        #expect(client.receivedRequests.first?.userMessage.contains("Existing steps") == false)
    }

    @Test func offlineMapsToOffline() async {
        let client = FakeClaudeClient(outcomes: [.failure(.offline)])
        await #expect(throws: StepSuggestionError.offline) { try await suggest(client) }
    }

    @Test(arguments: [ClaudeError.timeout, .rateLimited, .unauthorized, .serverError(500), .invalidResponse, .missingAPIKey])
    func otherClaudeErrorsMapToFailed(error: ClaudeError) async {
        let client = FakeClaudeClient(outcomes: [.failure(error)])
        await #expect(throws: StepSuggestionError.failed) { try await suggest(client) }
    }

    @Test func malformedToolInputMapsToFailed() async {
        let client = FakeClaudeClient(outcomes: [.success(response(#"{"nope":1}"#))])
        await #expect(throws: StepSuggestionError.failed) { try await suggest(client) }
    }

    @Test func aReplyFromAnotherToolMapsToFailed() async {
        let client = FakeClaudeClient(outcomes: [.success(response(#"{"steps":["A"]}"#, tool: "other"))])
        await #expect(throws: StepSuggestionError.failed) { try await suggest(client) }
    }
}
