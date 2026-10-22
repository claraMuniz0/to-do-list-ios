import Foundation

struct ClaudeTool: Equatable, Sendable {
    let name: String
    let description: String
    let inputSchema: JSONValue
}

/// One system prompt, one user message and one tool Claude is forced to call.
struct ClaudeRequest: Equatable, Sendable {
    let systemPrompt: String
    let userMessage: String
    let tool: ClaudeTool
    let maxTokens: Int
}
