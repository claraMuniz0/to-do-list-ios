---
name: define-location
description: Decide which Clean Architecture layer (Domain, Presentation or Data) a new type, file or piece of logic belongs in before creating it. Use when adding any new entity, value object, use case, view model, view, repository, storage model or file, or when asked "where should this go".
---

# Define Location

Decide the layer by what the code IS, not by convenience. Dependencies point inward only: `Data -> Presentation -> Domain`; Domain imports only Foundation.

## Checklist (ask in order)
1. Business rule or state meaningful without UI/framework? -> **Domain**: entity, value object, use case.
2. A capability Domain needs from outside (store, clock, id generator), no implementation? -> **Domain**: protocol, no framework types in its signature (`TodoItemRepository`).
3. Shapes data for display or holds UI state? -> **Presentation**: view model, route enum, view-local formatting.
4. A view, screen, styling or component? -> **Presentation** (`Presentation/<Feature>/`) or, if reusable and feature-agnostic, **Shared/DesignSystem** (`Shared/DesignSystem/`); depends on a view model, never on a repository or use case directly.
5. Talks to SwiftData, files, network, system services? -> **Data**: repository implementations, `@Model` storage records (`TodoItemRecord`), mappers.
6. Composition root (wiring the repository into use cases and view models)? -> the `@main` file only.

## Fast disqualifiers for Domain
- Imports `SwiftUI`, `SwiftData`, `UIKit`, or any third-party SDK.
- Calls `Date()` or `UUID()` directly (inject a clock / id generator instead).
- Is a SwiftData `@Model`: it is a storage record, it belongs in Data.
- Only means "how do we show this" (colors, display strings): Presentation.

## When ambiguous
An entity method that returns a display string mixes layers: keep the rule in Domain, move formatting to Presentation. `Shared/` holds only `Shared/DesignSystem/` (feature-agnostic UI); never create other "Shared"/"Common"/"Utils" folders or layers to dodge the decision.

State the decision in one line before creating the file: "X goes in <layer> because <rule>." Then name it with `naming-convention`. Unsure whether a new dependency is allowed? Check the imports against the direction above; adding a package needs explicit user permission.
