import Testing
@testable import MyApp

struct SwipeDeleteActionTests {
    @Test func labelAndFontMatchTheDesign() {
        #expect(SwipeDeleteAction.title == "Delete")
        #expect(SwipeDeleteAction.font == .swipeAction)
        #expect(DSFont.swipeAction.spec.size == 13)
        #expect(DSFont.swipeAction.spec.family == "Outfit")
        #expect(DSFont.swipeAction.spec.textStyle != nil)
    }

    @Test func spokenActionNamesTheTask() {
        #expect(SwipeDeleteAction.accessibilityLabel(taskTitle: "Buy milk") == "Delete Buy milk")
    }
}
