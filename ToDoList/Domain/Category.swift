import Foundation

enum CategoryError: Error, Equatable {
    case emptyName
}

/// A task category. A value type (not an enum) so user-created categories can arrive later
/// without replacing it; the three seeded ones keep stable ids.
///
/// Named `Category` as decided; inside test targets Foundation's `Category` makes the bare name
/// ambiguous, so tests alias it.
///
/// - Throws: `CategoryError.emptyName` when the name is blank.
struct Category: Hashable {
    let id: String
    let name: String
    let colorKey: String

    init(id: String, name: String, colorKey: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryError.emptyName }
        self.id = id
        self.name = trimmed
        self.colorKey = colorKey
    }

    static let work = seeded(id: "work", name: "Work", colorKey: "work")
    static let personal = seeded(id: "personal", name: "Personal", colorKey: "personal")
    static let shopping = seeded(id: "shopping", name: "Shopping", colorKey: "shopping")
    static let defaults: [Category] = [work, personal, shopping]

    private static func seeded(id: String, name: String, colorKey: String) -> Category {
        // Seeds are compile-time constants with non-empty names.
        try! Category(id: id, name: name, colorKey: colorKey)
    }
}
