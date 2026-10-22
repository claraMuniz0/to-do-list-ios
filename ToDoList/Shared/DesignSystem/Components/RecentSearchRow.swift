import SwiftUI

/// Copy and sizes of a recent-search row, kept apart from the view so they are unit tested.
enum RecentSearchRowRules {
    static let height: CGFloat = 52
    static let minimumTapTarget: CGFloat = DSTouchTarget.minimum

    static func rowAccessibilityLabel(term: String) -> String { "Recent search, \(term)" }
    static func fillAccessibilityLabel(term: String) -> String { "Use \(term)" }
}

/// Two separate targets: the row (`onSelect`, runs the search) and the arrow (`onFill`, only copies the term
/// into the field). `showsDivider` is false for the last row of a list, as in the design.
struct RecentSearchRow: View {
    let term: String
    let showsDivider: Bool
    let onSelect: () -> Void
    let onFill: () -> Void

    init(term: String, showsDivider: Bool = true, onSelect: @escaping () -> Void, onFill: @escaping () -> Void) {
        self.term = term
        self.showsDivider = showsDivider
        self.onSelect = onSelect
        self.onFill = onFill
    }

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    Image(systemName: "clock")
                        .font(.system(size: iconSize))
                        .foregroundStyle(DSColor.textMuted)
                        .accessibilityHidden(true)
                    Text(term)
                        .dsFont(.inputText)
                        .foregroundStyle(DSColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: RecentSearchRowRules.height)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(RecentSearchRowRules.rowAccessibilityLabel(term: term))

            Button(action: onFill) {
                Image(systemName: "arrow.up.left")
                    .font(.system(size: iconSize))
                    .foregroundStyle(DSColor.textMuted)
                    .frame(minWidth: RecentSearchRowRules.minimumTapTarget, minHeight: RecentSearchRowRules.height)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(RecentSearchRowRules.fillAccessibilityLabel(term: term))
            .accessibilityHint("Puts it in the search field without searching")
        }
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(DSColor.border).frame(height: 1).accessibilityHidden(true)
            }
        }
    }
}

#if DEBUG
#Preview("Recent rows") {
    VStack(spacing: 0) {
        RecentSearchRow(term: "groceries", onSelect: {}, onFill: {})
        RecentSearchRow(term: "dentist", onSelect: {}, onFill: {})
        RecentSearchRow(term: "report", showsDivider: false, onSelect: {}, onFill: {})
    }
    .padding()
}
#Preview("Long term") {
    RecentSearchRow(
        term: "Buy groceries for the week and plan the dentist visit before the quarterly report",
        onSelect: {}, onFill: {}
    ).padding()
}
#Preview("Accessibility3") {
    RecentSearchRow(term: "groceries", onSelect: {}, onFill: {}).padding().dynamicTypeSize(.accessibility3)
}
#endif
