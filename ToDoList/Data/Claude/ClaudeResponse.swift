import Foundation

/// The forced tool call Claude made. `toolInput` is raw JSON so each feature decodes its own draft type.
struct ClaudeResponse: Equatable, Sendable {
    let toolName: String
    let toolInput: Data
}
