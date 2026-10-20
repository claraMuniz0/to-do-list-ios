import Foundation
import Testing
@testable import MyApp

struct TodoItemTests {
    private let now = Date(timeIntervalSince1970: 5_000)

    @Test func startsOpen() {
        let item = makeTodoItem()
        #expect(item.isCompleted == false)
        #expect(item.completedAt == nil)
    }

    @Test func completeRecordsTheCompletionTime() {
        var item = makeTodoItem()
        item.complete(at: now)
        #expect(item.isCompleted)
        #expect(item.completedAt == now)
    }

    @Test func completingTwiceKeepsTheFirstCompletionTime() {
        var item = makeTodoItem()
        item.complete(at: now)
        item.complete(at: now.addingTimeInterval(60))
        #expect(item.completedAt == now)
    }

    @Test func reopenClearsCompletion() {
        var item = makeTodoItem()
        item.complete(at: now)
        item.reopen()
        #expect(item.isCompleted == false)
    }

    @Test func reopeningAnOpenItemChangesNothing() {
        var item = makeTodoItem()
        item.reopen()
        #expect(item == makeTodoItem(id: item.id))
    }

    @Test func renameReplacesTheTitle() throws {
        var item = makeTodoItem()
        item.rename(try TodoItemTitle("Call the dentist"))
        #expect(item.title.value == "Call the dentist")
    }

    @Test func changeCategoryReplacesTheCategory() {
        var item = makeTodoItem(category: .personal)
        item.changeCategory(.work)
        #expect(item.category == .work)
    }

    @Test func rescheduleSetsAndClearsTheDueDate() {
        var item = makeTodoItem()
        item.reschedule(DueDate(year: 2026, month: 10, day: 8))
        #expect(item.dueDate == DueDate(year: 2026, month: 10, day: 8))
        item.reschedule(nil)
        #expect(item.dueDate == nil)
    }

    @Test func changeDescriptionTrimsText() {
        var item = makeTodoItem()
        item.changeDescription("  Two liters \n")
        #expect(item.description == "Two liters")
    }

    @Test(arguments: ["", "   ", "\n"])
    func blankDescriptionBecomesNil(blank: String) {
        var item = makeTodoItem(description: "Something")
        item.changeDescription(blank)
        #expect(item.description == nil)
    }

    @Test func initNormalizesBlankDescription() {
        #expect(makeTodoItem(description: "  ").description == nil)
    }

    @Test func reopenClearsTheCompletionTime() {
        var item = makeTodoItem()
        item.complete(at: now)
        item.reopen()
        #expect(item.completedAt == nil)
    }

    @Test func completingAfterReopenRecordsTheNewTime() {
        var item = makeTodoItem()
        item.complete(at: now)
        item.reopen()
        item.complete(at: now.addingTimeInterval(60))
        #expect(item.completedAt == now.addingTimeInterval(60))
    }

    @Test func canBeRestoredAsCompleted() throws {
        let item = TodoItem(title: try TodoItemTitle("Done"), category: .work, createdAt: now, completedAt: now)
        #expect(item.isCompleted)
        #expect(item.completedAt == now)
    }

    @Test func renameLeavesOtherFieldsUntouched() throws {
        var item = makeTodoItem(description: "Notes", category: .work, dueDate: DueDate(year: 2026, month: 10, day: 8), createdAt: now)
        let original = item
        item.rename(try TodoItemTitle("New"))
        #expect(item.id == original.id)
        #expect(item.createdAt == original.createdAt)
        #expect(item.description == original.description)
        #expect(item.category == original.category)
        #expect(item.dueDate == original.dueDate)
    }

    @Test func keepsCreationTimeAcrossChanges() {
        var item = makeTodoItem(createdAt: now)
        item.changeCategory(.work)
        item.complete(at: now.addingTimeInterval(10))
        #expect(item.createdAt == now)
    }
}
