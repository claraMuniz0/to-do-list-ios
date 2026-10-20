import Foundation

/// A color key resolved to an actual palette in Presentation, so Domain stays free of UI types.
/// Unknown keys are tolerated; the palette falls back to a default.
struct CategoryColor: Hashable {
    let key: String

    init(_ key: String) {
        self.key = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
