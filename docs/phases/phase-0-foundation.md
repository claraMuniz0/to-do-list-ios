# Phase 0: Project foundation

**Status:** not started

## Goal
A green, empty shell with the Clean Architecture layers in place.

## Scope
- [ ] Layer structure: Domain, Presentation, Data
- [ ] `Task` entity (state + behavior, private fields, mutate via named methods)
- [ ] `TaskRepository` protocol in Domain
- [ ] In-memory `TaskRepository` implementation in Data
- [ ] Test target mirrors production folder structure

## Out of scope
- Persistent storage (SwiftData/CoreData), decided later
- Any UI

## Done when
- Test suite runs green on the empty shell.
