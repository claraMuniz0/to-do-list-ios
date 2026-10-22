import Foundation

/// Reads the key the build injected into Info.plist from the git-ignored `Secrets.xcconfig`.
struct ConfigFileAPIKeyProvider: APIKeyProvider {
    static let infoDictionaryKey = "AnthropicAPIKey"

    var infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]

    func apiKey() -> String? {
        guard let raw = infoDictionary[Self.infoDictionaryKey] as? String else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // An unset build variable leaves the literal `$(NAME)` placeholder in the plist.
        guard !key.isEmpty, !key.hasPrefix("$(") else { return nil }
        return key
    }
}
