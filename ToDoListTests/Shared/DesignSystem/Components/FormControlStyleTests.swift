import Testing
@testable import MyApp

struct FormControlStyleTests {
    @Test func focusedBorderIsAccentAndThicker() {
        let focused = FormControlBorder(isFocused: true)
        let idle = FormControlBorder(isFocused: false)
        #expect(focused.usesAccent)
        #expect(idle.usesAccent == false)
        #expect(focused.lineWidth > idle.lineWidth)
    }

    @Test func textAreaIsTallerThanSingleLine() {
        #expect(FormControlMetrics.textAreaMinHeight > FormControlMetrics.singleLineMinHeight)
        #expect(FormControlMetrics.singleLineMinHeight >= DSTouchTarget.minimum)
    }

    @Test func circleIconButtonMeetsMinimumTarget() {
        #expect(CircleIconButtonMetrics.diameter >= DSTouchTarget.minimum)
    }

    @Test func dateRowMeetsMinimumTarget() {
        #expect(FormControlMetrics.dateRowMinHeight >= DSTouchTarget.minimum)
    }
}
