import Foundation

/// Validates the sentence, then asks the parser for a draft with today's date and the available categories.
/// - Throws: `SmartAddTextError` before the parser is touched; otherwise whatever the `TaskDraftParsing` port throws, unchanged.
struct ParseTaskDraftUseCase {
    private let parser: TaskDraftParsing
    private let dateProvider: DateProvider
    private let calendar: Calendar

    init(parser: TaskDraftParsing, dateProvider: DateProvider, calendar: Calendar) {
        self.parser = parser
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    func execute(text: String, categories: [Category]) async throws -> TaskDraft {
        let sentence = try SmartAddText(text)
        let context = SmartAddContext(today: .today(using: dateProvider, calendar: calendar), categories: categories)
        return try await parser.parse(sentence, context: context)
    }
}
