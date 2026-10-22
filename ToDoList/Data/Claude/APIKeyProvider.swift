import Foundation

enum ClaudeEndpoint {
    static let defaultBaseURL = URL(string: "https://api.anthropic.com")!
}

protocol APIKeyProvider {
    /// `nil` when no usable token is configured.
    func apiKey() -> String?
    /// Where requests go; a gateway can replace the Anthropic host.
    var baseURL: URL { get }
}
