---
name: new-screen
description: Create a feature screen or list/row view in the Presentation layer, wired to an @Observable view model instead of business logic. Use for Welcome, Add Task, Task List, Edit Task and their sheets. Not for reusable design-system pieces (use new-ds-component).
---

# New Screen

A view renders state and forwards intent. It never fetches, mutates, or applies business rules itself.

## Steps
1. Confirm the layer with `define-location`; name with `naming-convention`: `<Noun>View`, `<Feature>ViewModel`.
2. Get the design spec first (`design-to-swiftui-spec`); build from design-system components and tokens only, no raw hex/fonts.
3. Place under `Presentation/<Feature>/` (e.g. `Presentation/AddTodoItem/`).
4. **View model first, TDD** (`tdd-cycle`): `@Observable` class, one per screen, depends on use cases (never repositories), exposes state plus intent methods. Test: initial state, success, validation errors, failure paths. Inject a clock where dates matter.
5. The view takes the view model (or Domain values) in `init`; never a storage record or DTO. Domain types in, formatting in the view or a view-local helper.
6. Navigation via the `NavigationStack` + route enum owned by the router; sheets (date, category, steps) are presented by state, not by the view itself deciding.
7. Compose from small subviews once `body` mixes more than one concern.
8. Add previews with `create-preview` (loading/empty/error/populated).
9. Run `accessibility-check`, then `design-fidelity-checker` against the design.
10. Commits: `test:`/`feat:` for the view-model cycle, a separate commit for view/preview/accessibility, `docs:` pass last (`doc-comments-pass`).

## Common mistakes
- View calls a use case or repository directly.
- Business rules re-implemented in the view instead of read from the entity.
- View init takes a SwiftData record.
- One giant view file for a whole screen.
- Wiring dependencies anywhere but the composition root.
