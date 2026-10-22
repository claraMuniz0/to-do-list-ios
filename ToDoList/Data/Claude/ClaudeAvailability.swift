import Foundation

/// Drives whether Claude entry points are shown: no usable key means they are hidden, not disabled.
struct ClaudeAvailability {
    let apiKeyProvider: APIKeyProvider

    var isAvailable: Bool { apiKeyProvider.apiKey()?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
}
