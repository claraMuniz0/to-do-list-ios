import Foundation
import Testing
@testable import MyApp

struct ParseTaskDraftUseCaseTests {
    private struct FixedDateProvider: DateProvider {
        let date: Date
        func now() -> Date { date }
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeUseCase(_ parser: FakeTaskDraftParser) -> ParseTaskDraftUseCase {
        let noon = Self.calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!
        return ParseTaskDraftUseCase(parser: parser, dateProvider: FixedDateProvider(date: noon), calendar: Self.calendar)
    }

    @Test func asksTheParserWithTheTrimmedTextTodayAndTheCategories() async throws {
        let parser = FakeTaskDraftParser()
        _ = try await makeUseCase(parser).execute(text: "  Dentist Tuesday ", categories: Category.defaults)
        #expect(parser.calls == [.init(
            text: "Dentist Tuesday",
            context: SmartAddContext(today: try DueDate(year: 2026, month: 10, day: 7), categories: Category.defaults)
        )])
    }

    @Test func returnsTheParsedDraft() async throws {
        let expected = TaskDraft(
            title: try TodoItemTitle("Buy milk"), description: nil,
            categoryID: Category.shopping.id, dueDate: nil, steps: []
        )
        let draft = try await makeUseCase(FakeTaskDraftParser(draft: expected))
            .execute(text: "Buy milk", categories: Category.defaults)
        #expect(draft == expected)
    }

    @Test func rejectsBlankTextWithoutCallingTheParser() async {
        let parser = FakeTaskDraftParser()
        await #expect(throws: SmartAddTextError.empty) {
            try await makeUseCase(parser).execute(text: "  ", categories: Category.defaults)
        }
        #expect(parser.calls.isEmpty)
    }

    @Test func rejectsOverlongTextWithoutCallingTheParser() async {
        let parser = FakeTaskDraftParser()
        await #expect(throws: SmartAddTextError.tooLong) {
            try await makeUseCase(parser).execute(
                text: String(repeating: "a", count: SmartAddText.maxLength + 1), categories: Category.defaults
            )
        }
        #expect(parser.calls.isEmpty)
    }

    @Test(arguments: [SmartAddError.couldNotUnderstand, .offline, .failed])
    func passesParserFailuresThrough(error: SmartAddError) async {
        let parser = FakeTaskDraftParser()
        parser.outcome = .failure(error)
        await #expect(throws: error) {
            try await makeUseCase(parser).execute(text: "Dentist", categories: Category.defaults)
        }
    }
}
