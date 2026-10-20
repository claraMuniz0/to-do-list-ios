---
name: new-value-object
description: Scaffold a self-validating Swift value object (e.g. TodoItemTitle, TodoItemID, DueDate) with its test file, test first. Use when a domain concept would otherwise be a raw String/Int/UUID/Date (primitive obsession) or the user asks for a new value object.
---

# New value object

Follow the `tdd-cycle` skill for commands, commits and guardrails. Test first, always.

## Location and shape
- Production: `ToDoList/Domain/<Name>.swift`. Imports only `Foundation`.
- Test: `ToDoListTests/Domain/<Name>Tests.swift` (mirrors the production folder), Swift Testing.
- `struct <Name>: Equatable, Hashable, Sendable`, storage is `private let`, exposed read-only via a named property (e.g. `value`).
- Throwing `init(_ raw: String) throws(<Name>Error)` or `throws`, normalizing then validating.
- Typed error: `enum <Name>Error: Error, Equatable { case empty ... }`. One case per rule, never a generic error.

## Steps
- [ ] Confirm rules with the user's spec/phase doc (decisions in docs/phases/phase-0-foundation.md are binding). If unclear, state the assumption and proceed.
- [ ] RED: write the first test (valid input stores the value), run, commit `test:`.
- [ ] One test per rule, each red then green (own commits):
  - empty string throws `.empty`
  - whitespace-only (spaces, tabs, newlines) throws `.empty`
  - leading/trailing whitespace is trimmed (`"  Buy milk \n"` -> `"Buy milk"`)
  - inner whitespace is preserved
  - boundary lengths if a max exists: exactly max passes, max+1 throws (`.tooLong`); min-1 / min
  - equality: two inputs that normalize equal are `==`
- [ ] GREEN: minimum implementation per test.
- [ ] REFACTOR while green.
- [ ] Use `#expect(throws: <Name>Error.empty) { try <Name>("") }` for failures.

## Example (TodoItemTitle)
```swift
import Foundation

enum TodoItemTitleError: Error, Equatable { case empty }

struct TodoItemTitle: Equatable, Hashable, Sendable {
    private let storage: String
    var value: String { storage }

    init(_ raw: String) throws(TodoItemTitleError) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw .empty }
        storage = trimmed
    }
}
```

## Rules
- No `UIKit`/`SwiftUI`/`SwiftData`/`Codable` coupling in Domain. DTO mapping lives in Data.
- No `Date()` in Domain; date-based objects take values or an injected clock.
- Doc comments (WHY: failure conditions, trimming rule) only in the final `docs:` commit.
