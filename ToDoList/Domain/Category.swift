import Foundation

/// A task category. A value type (not an enum) so user-created categories can arrive later
/// without replacing it; the three seeded ones keep stable ids.
///
/// Named `Category` as decided; inside test targets Foundation's `Category` makes the bare name
/// ambiguous, so tests alias it.
struct Category: Hashable {
    let id: CategoryID
    let name: CategoryName
    let color: CategoryColor

    static let work = seeded("work", name: "Work")
    static let personal = seeded("personal", name: "Personal")
    static let shopping = seeded("shopping", name: "Shopping")
    static let defaults: [Category] = [work, personal, shopping]

    /// Seeds use their own id as color key.
    private static func seeded(_ id: String, name: String) -> Category {
        // Compile-time constants with non-empty values.
        Category(id: try! CategoryID(id), name: try! CategoryName(name), color: CategoryColor(id))
    }
}
