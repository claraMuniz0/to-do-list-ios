import SwiftUI
import Testing
@testable import MyApp

struct FilterPillTests {
    @Test func expandablePillSpeaksItsPanelState() {
        #expect(FilterPill.accessibilityValue(isExpanded: true) == "Expanded")
        #expect(FilterPill.accessibilityValue(isExpanded: false) == "Collapsed")
    }

    @Test func plainPillHasNoSpokenValue() {
        #expect(FilterPill.accessibilityValue(isExpanded: nil) == nil)
    }

    @Test func unselectedPillOutlineUsesTheControlBorderForContrast() {
        #expect(FilterPill.borderColor(isSelected: false).lightHex == DSColor.borderControl.lightHex)
    }

    @Test func selectedPillHasNoOutline() {
        #expect(FilterPill.borderColor(isSelected: true) == .clear)
    }
}
