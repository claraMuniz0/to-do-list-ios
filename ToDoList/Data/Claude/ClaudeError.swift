import Foundation

/// Every failure a Claude call can surface; features map these to user-facing copy and never swallow them.
enum ClaudeError: Error, Equatable {
    case missingAPIKey
    case offline
    case timeout
    case rateLimited
    case unauthorized
    /// Any other non-2xx status, including 400 and Anthropic's 529 "overloaded".
    case serverError(Int)
    /// The reply had no `tool_use` block, was not valid JSON, or the transport failed in an unexpected way.
    case invalidResponse
}
