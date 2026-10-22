import Foundation

protocol ClaudeClient {
    func send(_ request: ClaudeRequest) async throws -> ClaudeResponse
}
