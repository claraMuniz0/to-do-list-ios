import Foundation

/// Asks Claude for steps through a forced `suggest_steps` tool call and maps the reply to validated titles.
struct ClaudeStepSuggester: StepSuggesting {
    static let toolName = "suggest_steps"
    static let systemPrompt = """
    You break a to-do task into small, concrete steps. Reply only by calling the suggest_steps tool. \
    Give 3 to 6 short imperative steps, no numbering, in the same language as the task. \
    If existing steps are listed, suggest only new steps that do not repeat or overlap them.
    """
    private static let maxTokens = 512

    private let client: ClaudeClient

    init(client: ClaudeClient) {
        self.client = client
    }

    private struct Suggestion: Decodable {
        let steps: [String]
    }

    /// A title Claude returns that is blank or too long is dropped, so one bad entry never fails the whole answer.
    func suggest(title: String, description: String?, existingSteps: [StepTitle]) async throws -> [StepTitle] {
        let response: ClaudeResponse
        do {
            response = try await client.send(request(title: title, description: description, existingSteps: existingSteps))
        } catch ClaudeError.offline {
            throw StepSuggestionError.offline
        } catch {
            throw StepSuggestionError.failed
        }
        guard response.toolName == Self.toolName,
              let suggestion = try? JSONDecoder().decode(Suggestion.self, from: response.toolInput)
        else { throw StepSuggestionError.failed }
        return suggestion.steps.compactMap { try? StepTitle($0) }
    }

    private func request(title: String, description: String?, existingSteps: [StepTitle]) -> ClaudeRequest {
        var message = "Task: \(title)"
        if let description, !description.isEmpty { message += "\nDescription: \(description)" }
        if !existingSteps.isEmpty {
            message += "\nExisting steps:\n" + existingSteps.map { "- \($0.value)" }.joined(separator: "\n")
        }
        return ClaudeRequest(
            systemPrompt: Self.systemPrompt,
            userMessage: message,
            tool: ClaudeTool(
                name: Self.toolName,
                description: "Returns the suggested steps for the task.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "steps": .object(["type": .string("array"), "items": .object(["type": .string("string")])])
                    ]),
                    "required": .array([.string("steps")])
                ])
            ),
            maxTokens: Self.maxTokens
        )
    }
}
