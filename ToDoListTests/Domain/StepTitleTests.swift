import Testing
@testable import MyApp

struct StepTitleTests {
    @Test(arguments: ["", "  \n\t ", "\u{00A0}\u{2003}"])
    func rejectsBlankText(text: String) {
        #expect(throws: StepTitleError.empty) { try StepTitle(text) }
    }

    @Test func trimsSurroundingWhitespaceAndKeepsInnerWhitespace() throws {
        #expect(try StepTitle("  Buy  oat milk \n").value == "Buy  oat milk")
    }

    @Test func acceptsExactlyTheMaximumLengthAfterTrimming() throws {
        let padded = " " + String(repeating: "a", count: StepTitle.maxLength) + " "
        #expect(try StepTitle(padded).value.count == 120)
    }

    @Test func rejectsATitleOverTheMaximumLength() {
        #expect(throws: StepTitleError.tooLong) {
            try StepTitle(String(repeating: "a", count: StepTitle.maxLength + 1))
        }
    }

    @Test func equalTitlesAreEqual() throws {
        #expect(try StepTitle(" A ") == StepTitle("A"))
    }

    @Test(arguments: ["", " ", "\n\t", "\u{00A0}"])
    func blankTextIsBlank(text: String) {
        #expect(StepTitle.isBlank(text))
    }

    @Test(arguments: ["a", "  a ", String(repeating: "a", count: 500)])
    func textWithContentIsNotBlank(text: String) {
        #expect(!StepTitle.isBlank(text))
    }
}
