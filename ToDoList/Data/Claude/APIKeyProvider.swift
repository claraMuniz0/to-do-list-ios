import Foundation

protocol APIKeyProvider {
    /// `nil` when no usable key is configured.
    func apiKey() -> String?
}
