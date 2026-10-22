import Testing
@testable import MyApp

struct TaskDraftTests {
    private func draft(description: String? = nil, steps: [String] = []) throws -> TaskDraft {
        TaskDraft(
            title: try TodoItemTitle("Dentist"),
            description: description,
            categoryID: Category.personal.id,
            dueDate: nil,
            steps: try steps.map { try StepTitle($0) }
        )
    }

    @Test(arguments: ["", "  \n", "\u{00A0}"])
    func aBlankDescriptionBecomesNil(text: String) throws {
        #expect(try draft(description: text).description == nil)
    }

    @Test func aDescriptionIsTrimmed() throws {
        #expect(try draft(description: "  Bring card \n").description == "Bring card")
    }

    @Test func keepsAtMostAsManyStepsAsAStepListHolds() throws {
        let titles = (1...(StepList.maxSteps + 5)).map { "Step \($0)" }
        #expect(try draft(steps: titles).steps.count == StepList.maxSteps)
    }

    @Test func dropsRepeatedStepsIgnoringCase() throws {
        #expect(try draft(steps: ["Call", "call", "Pay"]).steps.map(\.value) == ["Call", "Pay"])
    }
}
