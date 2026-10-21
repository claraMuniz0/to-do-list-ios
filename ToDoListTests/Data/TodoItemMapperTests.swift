import Foundation
import Testing
@testable import MyApp

struct TodoItemMapperTests {
    private let mapper = TodoItemMapper(categories: Category.defaults)

    @Test func roundTripsAFullItem() throws {
        let item = makeTodoItem(
            title: "Call the dentist",
            description: "Ask about Friday",
            category: .work,
            dueDate: makeDueDate(2026, 10, 8)
        )
        #expect(try mapper.toDomain(mapper.toRecord(item)) == item)
    }

    @Test func roundTripsAnItemWithoutDescriptionOrDueDate() throws {
        let item = makeTodoItem()
        #expect(try mapper.toDomain(mapper.toRecord(item)) == item)
    }

    @Test func roundTripsCompletion() throws {
        var item = makeTodoItem()
        item.complete(at: Date(timeIntervalSince1970: 5_000))
        #expect(try mapper.toDomain(mapper.toRecord(item)) == item)
    }

    @Test func storesDueDateAsYearMonthDayAndCategoryAsID() {
        let record = mapper.toRecord(makeTodoItem(category: .shopping, dueDate: makeDueDate(2026, 1, 31)))
        #expect(record.dueYear == 2026 && record.dueMonth == 1 && record.dueDay == 31)
        #expect(record.categoryID == "shopping")
    }

    @Test func unknownCategoryFallsBackToPersonal() throws {
        let record = mapper.toRecord(makeTodoItem(category: .work))
        record.categoryID = "deleted-category"
        #expect(try mapper.toDomain(record).category == .personal)
    }

    @Test func blankStoredTitleThrows() {
        let record = mapper.toRecord(makeTodoItem())
        record.title = "   "
        #expect(throws: TodoItemTitleError.empty) { try mapper.toDomain(record) }
    }

    @Test func partialStoredDueDateMapsToNil() throws {
        let record = mapper.toRecord(makeTodoItem(dueDate: makeDueDate(2026, 10, 8)))
        record.dueMonth = nil
        #expect(try mapper.toDomain(record).dueDate == nil)
    }

    @Test func corruptStoredDueDateThrowsInsteadOfBecomingAnInvalidDate() {
        let record = mapper.toRecord(makeTodoItem(dueDate: makeDueDate(2026, 10, 8)))
        record.dueMonth = 13
        #expect(throws: DueDateError.invalidDate) { try mapper.toDomain(record) }
    }
}
