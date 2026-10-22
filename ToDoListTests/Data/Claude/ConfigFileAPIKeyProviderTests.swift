import Foundation
import Testing
@testable import MyApp

struct ConfigFileAPIKeyProviderTests {
    private func provider(_ value: Any?) -> ConfigFileAPIKeyProvider {
        ConfigFileAPIKeyProvider(infoDictionary: value.map { ["AnthropicAPIKey": $0] } ?? [:])
    }

    @Test func returnsTheConfiguredKey() {
        #expect(provider("sk-ant-123").apiKey() == "sk-ant-123")
    }

    @Test func trimsSurroundingWhitespace() {
        #expect(provider("  sk-ant-123\n").apiKey() == "sk-ant-123")
    }

    @Test(arguments: ["", "   ", "$(ANTHROPIC_API_KEY)"])
    func treatsBlankOrUnexpandedPlaceholderAsMissing(value: String) {
        #expect(provider(value).apiKey() == nil)
    }

    @Test func treatsAbsentOrNonStringEntryAsMissing() {
        #expect(provider(nil).apiKey() == nil)
        #expect(provider(42).apiKey() == nil)
    }
}

struct ConfigFileBaseURLTests {
    private func baseURL(_ value: Any?) -> URL {
        ConfigFileAPIKeyProvider(infoDictionary: value.map { ["AnthropicBaseURL": $0] } ?? [:]).baseURL
    }

    @Test func usesTheConfiguredBaseURL() {
        #expect(baseURL("https://gateway.example.com") == URL(string: "https://gateway.example.com"))
    }

    @Test(arguments: ["", "  ", "$(ANTHROPIC_BASE_URL)", "not a url", "ftp://host"])
    func fallsBackToAnthropicWhenMissingOrInvalid(value: String) {
        #expect(baseURL(value) == ClaudeEndpoint.defaultBaseURL)
    }

    @Test func fallsBackWhenAbsent() {
        #expect(baseURL(nil) == ClaudeEndpoint.defaultBaseURL)
    }
}

struct ClaudeAvailabilityTests {
    @Test func isAvailableWhenAKeyExists() {
        #expect(ClaudeAvailability(apiKeyProvider: APIKeyProviderStub(key: "sk-ant-123")).isAvailable)
    }

    @Test(arguments: [nil, "", "  "] as [String?])
    func isUnavailableWithoutAUsableKey(key: String?) {
        #expect(!ClaudeAvailability(apiKeyProvider: APIKeyProviderStub(key: key)).isAvailable)
    }
}
