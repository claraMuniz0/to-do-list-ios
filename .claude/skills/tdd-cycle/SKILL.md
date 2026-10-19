---
name: tdd-cycle
description: Run one red/green/refactor TDD loop for a single behavior in this iOS app. Use whenever adding or changing any production Swift code (feature, bug fix, entity behavior, view model), before writing production code.
---

# TDD cycle (one loop = one behavior)

Rules: no production code without a failing test first. Swift Testing only (`import Testing`, `@Test`, `#expect`). Small, atomic steps.

## Setup (once per session)
- [ ] Read the real scheme: `xcodebuild -list -project ToDoListApp.xcodeproj`. Never guess the name.
- [ ] Test command: `xcodebuild test -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 17'`
- [ ] If no test target exists, stop: adding one edits `project.pbxproj` and needs explicit user permission.

## Red
- [ ] Write ONE failing test. File `<Production>Tests.swift`, in a test folder mirroring the production folder (e.g. `Domain/TodoItemTitle.swift` -> `ToDoListTests/Domain/TodoItemTitleTests.swift`).
- [ ] Run the test command. Confirm it fails for the RIGHT reason (assertion fails or the missing type/method), not a typo or setup error.
- [ ] Commit: `test: add failing test for [feature]`

## Green
- [ ] Write the minimum code to pass. No extra behavior.
- [ ] Run the test command. Whole suite must be green.
- [ ] Commit: `feat: implement [feature] to pass test`

## Refactor
- [ ] Clean up production and test code while staying green; rerun tests after each change.
- [ ] Never refactor across multiple layers at once.
- [ ] Commit (only if something changed): `refactor: clean up [target] without altering behavior`

## Guardrails
- Never rerun the same failing test command more than 3 times without changing code. Stop and analyze the failure instead.
- Cover boundary values, empty/nil states and failure paths; never swallow errors.
- Domain: no framework imports beyond Foundation, never call `Date()` (inject a clock).
- Do not install packages or touch Xcode project files without explicit permission.
- Never commit `.env` or credential files.
- Commits: Conventional Commits; follow the attribution rules in the session.
- Doc comments go in a separate `docs:` commit at the end of the feature, never mixed in.
