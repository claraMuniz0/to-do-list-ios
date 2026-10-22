import Testing
@testable import MyApp

struct SmartAddTextTests {
    @Test(arguments: ["", "  \n\t ", "\u{00A0}\u{2003}"])
    func rejectsBlankText(text: String) {
        #expect(throws: SmartAddTextError.empty) { try SmartAddText(text) }
    }

    @Test func trimsSurroundingWhitespaceAndKeepsInnerWhitespace() throws {
        #expect(try SmartAddText("  Dentist  Tuesday \n").value == "Dentist  Tuesday")
    }

    @Test func acceptsExactlyTheMaximumLengthAfterTrimming() throws {
        let padded = " " + String(repeating: "a", count: SmartAddText.maxLength) + " "
        #expect(try SmartAddText(padded).value.count == 280)
    }

    @Test func rejectsTextOverTheMaximumLength() {
        #expect(throws: SmartAddTextError.tooLong) {
            try SmartAddText(String(repeating: "a", count: SmartAddText.maxLength + 1))
        }
    }

    @Test(arguments: ["", " ", "\n\t", "\u{00A0}"])
    func blankTextIsBlank(text: String) {
        #expect(SmartAddText.isBlank(text))
    }

    @Test(arguments: ["a", "  a ", String(repeating: "a", count: 500)])
    func textWithContentIsNotBlank(text: String) {
        #expect(!SmartAddText.isBlank(text))
    }
}
