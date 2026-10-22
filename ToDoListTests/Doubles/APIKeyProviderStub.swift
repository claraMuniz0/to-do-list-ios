@testable import MyApp

struct APIKeyProviderStub: APIKeyProvider {
    var key: String?
    func apiKey() -> String? { key }
}
