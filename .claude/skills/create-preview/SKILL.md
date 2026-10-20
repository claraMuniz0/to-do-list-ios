---
name: create-preview
description: Add or update SwiftUI previews for a view, one per realistic state, with deterministic sample data. Use right after creating or changing a view (new-ds-component, new-screen), or when a view has no preview or an outdated one.
---

# Create Preview

The preview is a view's fast feedback loop, like a unit test for logic. Every view gets one before it is done.

## Steps
1. Use the `#Preview("Name")` macro, never `PreviewProvider`. Name previews by state ("Done", "Empty", "Error"), not numbers.
2. **App code cannot import the test target.** Never reuse test `make...` factories. Create sample data in the app target inside `#if DEBUG`, named `.preview(...)`, mirroring the test factory's defaults:
   ```swift
   #if DEBUG
   extension TodoItem {
       static func preview(title: String = "Buy groceries", isDone: Bool = false) -> TodoItem { ... }
   }
   #endif
   ```
3. **One preview per state the view can render**, not only the happy path: design-system components (each variant/selected/done), screens with a view model (loading, empty, error, populated), long text, no description, no due date.
4. View-model-backed screens get an injected stub/fake (deterministic), never the real SwiftData repository.
5. Keep data deterministic: no `Date()` or `UUID()` unless fixed, no network.
6. Light mode only for now; add a large Dynamic Type preview (`.dynamicTypeSize(.accessibility3)`) for any text-bearing view.
7. Design-system components also get an entry in `DesignSystemGallery`.

## Common mistakes
- Importing a test factory from app code (does not compile).
- Only a happy-path preview.
- Sample data that never exercises layout-breaking cases (nil description, very long title).
- Sample factories outside the `#if DEBUG` guard.
