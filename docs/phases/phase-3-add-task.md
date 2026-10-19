# Phase 3: Add Task (manual)

**Status:** not started
**Design:** `to-do.pen`, "Add Task", "Select Date", "Task List"

## Goal
Create a task manually and see it in a list.

## Scope
### Persistence (first step)
- [ ] SwiftData `@Model` storage record in Data (never in Domain), mapped to/from `TodoItem`
- [ ] `SwiftDataTodoItemRepository` implementing `TodoItemRepository`, tested with an in-memory `ModelContainer`
- [ ] Swap the composition root from `InMemoryTodoItemRepository` to SwiftData

### Domain
- [ ] `TodoItemTitle` value object (self-validating: non-empty, trimmed)
- [ ] `Category` (Work / Personal / Shopping) and `DueDate` value objects
- [ ] `AddTodoItemUseCase`

### Form
- [ ] Task name, optional description
- [ ] Category picker (Work / Personal / Shopping)
- [ ] Due date: Today / Tomorrow / Next week pills + calendar sheet
- [ ] Save button; validation feedback; edge cases (empty title, past date)

### Minimal Task List
- [ ] Open tasks ("TO DO") and completed tasks ("COMPLETED")
- [ ] Tap circle to complete / reopen
- [ ] Quick Add Input

## Out of scope
- Filters (Active/Done/Categories), search, swipe to delete
- Steps, new categories, Smart Add

## Done when
- A task can be created and shows up in the list.
