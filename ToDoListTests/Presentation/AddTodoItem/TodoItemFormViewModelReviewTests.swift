import Foundation
import Testing
@testable import MyApp

@MainActor
struct TodoItemFormViewModelReviewTests {
    private let calendar = Calendar.utcGregorian

    private func makeDraft(dueDate: DueDate? = nil, categoryID: String = "work") -> TaskDraft {
        TaskDraft(
            title: try! TodoItemTitle("Dentist"),
            description: "Bring insurance card",
            categoryID: try! CategoryID(categoryID),
            dueDate: dueDate,
            steps: [try! StepTitle("Call"), try! StepTitle("Pay")]
        )
    }

    private func makeSUT(
        _ draft: TaskDraft, spy: TodoItemRepositorySpy = TodoItemRepositorySpy()
    ) -> TodoItemFormViewModel {
        let provider = DateProviderStub(current: calendar.makeDate(2026, 10, 8))
        return TodoItemFormViewModel(
            mode: .reviewingDraft(draft),
            addTodoItem: AddTodoItemUseCase(repository: spy, dateProvider: provider, calendar: calendar),
            updateTodoItem: UpdateTodoItemUseCase(repository: spy),
            deleteTodoItem: DeleteTodoItemUseCase(repository: spy),
            getTodoItem: GetTodoItemUseCase(repository: spy),
            dateProvider: provider,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
    }

    @Test func startsPrefilledFromTheDraft() throws {
        let date = try DueDate(year: 2026, month: 10, day: 13)
        let viewModel = makeSUT(makeDraft(dueDate: date))
        #expect(viewModel.title == "Dentist")
        #expect(viewModel.details == "Bring insurance card")
        #expect(viewModel.category == .work)
        #expect(viewModel.dueDate == date)
        #expect(viewModel.steps.map(\.title.value) == ["Call", "Pay"])
    }

    @Test func aDraftWithoutADateStaysWithoutOne() {
        #expect(makeSUT(makeDraft(dueDate: nil)).dueDate == nil)
    }

    @Test func anUnknownCategoryFallsBackToPersonal() {
        #expect(makeSUT(makeDraft(categoryID: "gone")).category == .personal)
    }

    @Test func showsTheBannerAndReviewCopyOnlyInReview() {
        let review = makeSUT(makeDraft())
        #expect(review.showsAIBanner)
        #expect(review.screenTitle == "Looks right?")
        #expect(review.screenSubtitle == "Here's what I understood")
        #expect(review.saveButtonTitle == "Save task")
        #expect(!review.canDelete)
    }

    @Test func savingStoresANewTaskWithTheEditedValuesAndSteps() async throws {
        let spy = TodoItemRepositorySpy()
        let viewModel = makeSUT(makeDraft(), spy: spy)
        viewModel.title = "Dentist Friday"
        viewModel.addStep("Book")
        #expect(await viewModel.save())
        let stored = try #require(spy.storedItems.first)
        #expect(stored.title.value == "Dentist Friday")
        #expect(stored.description == "Bring insurance card")
        #expect(stored.steps.map(\.title.value) == ["Call", "Pay", "Book"])
    }
}
