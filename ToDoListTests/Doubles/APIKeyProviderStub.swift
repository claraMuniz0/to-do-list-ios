import Foundation
@testable import MyApp

struct APIKeyProviderStub: APIKeyProvider {
    var key: String?
    var baseURL: URL = ClaudeEndpoint.defaultBaseURL
    func apiKey() -> String? { key }
}
