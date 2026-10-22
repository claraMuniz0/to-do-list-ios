import Foundation
import Testing
@testable import MyApp

struct ClaudeTaskDraftParserTests {
    private let today = try! DueDate(year: 2026, month: 10, day: 7)

    private func response(_ json: String, tool: String = "create_task_draft") -> ClaudeResponse {
        ClaudeResponse(toolName: tool, toolInput: Data(json.utf8))
    }

    private func parse(
        _ client: FakeClaudeClient, text: String = "Dentist next Tuesday", categories: [MyApp.Category] = MyApp.Category.defaults
    ) async throws -> TaskDraft {
        try await ClaudeTaskDraftParser(client: client)
            .parse(try SmartAddText(text), context: SmartAddContext(today: today, categories: categories))
    }

    private func client(_ json: String) -> FakeClaudeClient {
        FakeClaudeClient(outcomes: [.success(response(json))])
    }

    @Test func mapsEveryFieldOfTheToolInput() async throws {
        let draft = try await parse(client(#"""
        {"title":"Dentist","description":"Bring insurance card","category_id":"work","due_date":"2026-10-13","steps":["Call","Pay"]}
        """#))
        #expect(draft.title.value == "Dentist")
        #expect(draft.description == "Bring insurance card")
        #expect(draft.categoryID == MyApp.Category.work.id)
        #expect(draft.dueDate == (try DueDate(year: 2026, month: 10, day: 13)))
        #expect(draft.steps.map(\.value) == ["Call", "Pay"])
    }

    @Test func aTitleAloneIsEnoughAndTheRestStaysEmpty() async throws {
        let draft = try await parse(client(#"{"title":"Buy milk"}"#))
        #expect(draft.description == nil)
        #expect(draft.dueDate == nil)
        #expect(draft.steps.isEmpty)
        #expect(draft.categoryID == MyApp.Category.personal.id)
    }

    @Test(arguments: ["", "   "])
    func aBlankTitleCouldNotBeUnderstood(title: String) async {
        await #expect(throws: SmartAddError.couldNotUnderstand) {
            try await parse(client(#"{"title":"\#(title)"}"#))
        }
    }

    @Test func aMissingTitleCouldNotBeUnderstood() async {
        await #expect(throws: SmartAddError.couldNotUnderstand) {
            try await parse(client(#"{"description":"x"}"#))
        }
    }

    @Test func anOverlongTitleIsCutToTheMaximumLength() async throws {
        let draft = try await parse(client(#"{"title":"\#(String(repeating: "a", count: 200))"}"#))
        #expect(draft.title.value.count == TodoItemTitle.maxLength)
    }

    @Test(arguments: ["2026-02-30", "tomorrow", "13/10/2026", "2026-10-13T15:00", "", "2025-10-13"])
    func anUnusableDateBecomesNil(date: String) async throws {
        let draft = try await parse(client(#"{"title":"Dentist","due_date":"\#(date)"}"#))
        #expect(draft.dueDate == nil)
    }

    @Test func aDateInThePastOfTheCurrentYearIsKept() async throws {
        let draft = try await parse(client(#"{"title":"Dentist","due_date":"2026-10-01"}"#))
        #expect(draft.dueDate == (try DueDate(year: 2026, month: 10, day: 1)))
    }

    @Test func anUnknownCategoryFallsBackToPersonal() async throws {
        let draft = try await parse(client(#"{"title":"Dentist","category_id":"hobbies"}"#))
        #expect(draft.categoryID == MyApp.Category.personal.id)
    }

    @Test func aCustomCategoryIsKept() async throws {
        let gym = MyApp.Category(id: try CategoryID("gym"), name: try CategoryName("Gym"), color: CategoryColor("gym"))
        let draft = try await parse(
            client(#"{"title":"Leg day","category_id":"gym"}"#), categories: MyApp.Category.defaults + [gym]
        )
        #expect(draft.categoryID == gym.id)
    }

    @Test func dropsBlankAndOverlongStepsInsteadOfFailing() async throws {
        let long = String(repeating: "x", count: 121)
        let draft = try await parse(client(#"{"title":"Trip","steps":[" ","\#(long)"," Pack "]}"#))
        #expect(draft.steps.map(\.value) == ["Pack"])
    }

    @Test func forcesTheToolAndSendsTheSentenceTodayAndCategoryIds() async throws {
        let fake = client(#"{"title":"Dentist"}"#)
        _ = try await parse(fake)
        let request = try #require(fake.receivedRequests.first)
        #expect(request.tool.name == "create_task_draft")
        #expect(request.userMessage == "Dentist next Tuesday")
        #expect(request.systemPrompt.contains("2026-10-07"))
        #expect(request.systemPrompt.contains("work"))
        #expect(request.systemPrompt.contains("shopping"))
    }

    @Test func asksForStepsEvenWhenTheSentenceListsNone() async throws {
        let fake = client(#"{"title":"Plan trip"}"#)
        _ = try await parse(fake)
        let prompt = try #require(fake.receivedRequests.first).systemPrompt
        #expect(prompt.contains("Always give 3 to 6 short"))
        #expect(!prompt.contains("give steps only if the user listed them"))
    }

    @Test func offlineMapsToOffline() async {
        let fake = FakeClaudeClient(outcomes: [.failure(.offline)])
        await #expect(throws: SmartAddError.offline) { try await parse(fake) }
    }

    @Test(arguments: [ClaudeError.timeout, .rateLimited, .unauthorized, .serverError(500), .invalidResponse, .missingAPIKey])
    func otherClaudeErrorsMapToFailed(error: ClaudeError) async {
        let fake = FakeClaudeClient(outcomes: [.failure(error)])
        await #expect(throws: SmartAddError.failed) { try await parse(fake) }
    }

    @Test func malformedToolInputMapsToFailed() async {
        await #expect(throws: SmartAddError.failed) { try await parse(client("not json")) }
    }

    @Test func aDifferentToolNameMapsToFailed() async {
        let fake = FakeClaudeClient(outcomes: [.success(response(#"{"title":"x"}"#, tool: "other"))])
        await #expect(throws: SmartAddError.failed) { try await parse(fake) }
    }
}
