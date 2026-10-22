import Foundation

enum ClaudeError: Error, Equatable {
    case missingAPIKey
    case offline
    case timeout
    case rateLimited
    case unauthorized
    case serverError(Int)
    case invalidResponse
}
