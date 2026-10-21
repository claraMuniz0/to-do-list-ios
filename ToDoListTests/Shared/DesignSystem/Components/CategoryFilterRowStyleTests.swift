import SwiftUI
import Testing
@testable import MyApp

struct CategoryFilterRowStyleTests {
    @Test func selectedRowHasAccentBorderAndFilledIndicator() {
        let style = CategoryFilterRowStyle(isSelected: true)
        #expect(style.borderColor.lightHex == DSColor.accent.lightHex)
        #expect(style.borderWidth == 2)
        #expect(style.indicatorFill.lightHex == DSColor.accent.lightHex)
        #expect(style.indicatorStroke.lightHex == DSColor.accent.lightHex)
        #expect(style.showsCheckmark)
    }

    @Test func unselectedRowHasThinBorderAndEmptyIndicator() {
        let style = CategoryFilterRowStyle(isSelected: false)
        #expect(style.borderColor.lightHex == DSColor.borderControl.lightHex)
        #expect(style.borderWidth == 1)
        #expect(style.indicatorFill == .clear)
        #expect(style.indicatorStroke.lightHex == DSColor.textMuted.lightHex)
        #expect(!style.showsCheckmark)
    }

    @Test func countLabelPluralises() {
        #expect(CategoryFilterRowStyle.countLabel(0) == "0 tasks")
        #expect(CategoryFilterRowStyle.countLabel(1) == "1 task")
        #expect(CategoryFilterRowStyle.countLabel(2) == "2 tasks")
    }

    @Test func accessibilityLabelJoinsNameAndCount() {
        #expect(CategoryFilterRowStyle.accessibilityLabel(name: "Work", openCount: 2) == "Work, 2 tasks")
        #expect(CategoryFilterRowStyle.accessibilityLabel(name: "Shopping", openCount: 1) == "Shopping, 1 task")
    }

    @Test func countUsesTheMonoCaptionToken() {
        #expect(DSFont.count.spec.family == "DM Mono")
        #expect(DSFont.count.spec.size == 12)
        #expect(DSFont.count.spec.weight == .regular)
        #expect(DSFont.count.spec.textStyle == .caption)
    }
}
