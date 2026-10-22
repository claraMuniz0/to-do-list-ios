import Foundation
import Testing
@testable import MyApp

@MainActor
struct SmartAddViewModelTests {
    private func makeViewModel(_ parser: FakeTaskDraftParser = FakeTaskDraftParser()) -> SmartAddViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let useCase = ParseTaskDraftUseCase(
            parser: parser, dateProvider: DateProviderStub(current: Date(timeIntervalSince1970: 1_790_000_000)), calendar: calendar
        )
        return SmartAddViewModel(parseTaskDraft: useCase)
    }

    @Test func startsIdleWithEmptyInputAndCannotFill() {
        let viewModel = makeViewModel()
        #expect(viewModel.state == .idle)
        #expect(viewModel.input.isEmpty)
        #expect(!viewModel.canFill)
    }

    @Test func counterShowsTheLengthOutOfTheMaximum() {
        let viewModel = makeViewModel()
        viewModel.input = "Dentist"
        #expect(viewModel.counterText == "7 / 280")
    }

    @Test func spokenCounterReadsCountOfMaximumCharacters() {
        let viewModel = makeViewModel()
        viewModel.input = "Dentist"
        #expect(viewModel.spokenCounterText == "7 of 280 characters")
    }

    @Test func inputPastTheMaximumIsCutOff() {
        let viewModel = makeViewModel()
        viewModel.input = String(repeating: "a", count: 300)
        #expect(viewModel.input.count == SmartAddText.maxLength)
    }

    @Test func blankInputCannotFill() {
        let viewModel = makeViewModel()
        viewModel.input = "  \n "
        #expect(!viewModel.canFill)
    }

    @Test func textWithContentCanFill() {
        let viewModel = makeViewModel()
        viewModel.input = "Dentist"
        #expect(viewModel.canFill)
    }

    @Test func selectingAnExampleReplacesTheInput() {
        let viewModel = makeViewModel()
        viewModel.input = "something else"
        viewModel.selectExample(SmartAddViewModel.examples[0])
        #expect(viewModel.input == SmartAddViewModel.examples[0])
    }

    @Test func fillReturnsTheDraftAndGoesBackToIdle() async throws {
        let viewModel = makeViewModel()
        viewModel.input = "Dentist next Tuesday"
        let draft = await viewModel.fill()
        #expect(draft?.title.value == "Dentist")
        #expect(viewModel.state == .idle)
    }

    @Test func fillIsIgnoredWhenInputIsBlank() async {
        let parser = FakeTaskDraftParser()
        let viewModel = makeViewModel(parser)
        #expect(await viewModel.fill() == nil)
        #expect(parser.calls.isEmpty)
    }

    @Test(arguments: [SmartAddError.couldNotUnderstand, .offline, .failed])
    func aFailureIsShownAndTheTextIsKept(error: SmartAddError) async {
        let parser = FakeTaskDraftParser()
        parser.outcome = .failure(error)
        let viewModel = makeViewModel(parser)
        viewModel.input = "Dentist"
        #expect(await viewModel.fill() == nil)
        #expect(viewModel.state == .failed(error))
        #expect(viewModel.input == "Dentist")
        #expect(viewModel.errorMessage?.isEmpty == false)
    }

    @Test func editingTheInputClearsTheError() async {
        let parser = FakeTaskDraftParser()
        parser.outcome = .failure(.failed)
        let viewModel = makeViewModel(parser)
        viewModel.input = "Dentist"
        _ = await viewModel.fill()
        viewModel.input = "Dentist Friday"
        #expect(viewModel.state == .idle)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func tryingAgainAfterAFailureCanSucceed() async {
        let parser = FakeTaskDraftParser()
        parser.outcome = .failure(.offline)
        let viewModel = makeViewModel(parser)
        viewModel.input = "Dentist"
        _ = await viewModel.fill()
        parser.outcome = FakeTaskDraftParser().outcome
        #expect(await viewModel.fill() != nil)
        #expect(viewModel.state == .idle)
    }

    @Test func aCancelledRequestReturnsNothingAndStaysIdle() async {
        let viewModel = makeViewModel()
        viewModel.input = "Dentist"
        let task = Task { await viewModel.fill() }
        task.cancel()
        #expect(await task.value == nil)
        #expect(viewModel.state == .idle)
    }
}
