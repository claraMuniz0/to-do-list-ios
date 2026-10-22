import SwiftUI

/// "TO DO · 3" style label followed by a thin rule. Without a count (the Categories panel headers) only the title shows.
struct SectionHeader: View {
    let title: String
    let count: Int?
    let trailingAction: (title: String, action: () -> Void)?
    /// Spoken name of the trailing link when its visible text ("Clear all") is ambiguous out of context.
    let trailingAccessibilityLabel: String?

    /// With a `trailingAction` (e.g. "Clear all") the header shows the link instead of the rule, as the design's RECENT header does.
    /// Result counts ("2 results") go in `title`, so they get the rule and no dot.
    init(title: String, count: Int? = nil, trailingAction: (title: String, action: () -> Void)? = nil, trailingAccessibilityLabel: String? = nil) {
        self.title = title
        self.trailingAccessibilityLabel = trailingAccessibilityLabel
        self.count = count
        self.trailingAction = trailingAction
    }

    static func showsRule(hasTrailingAction: Bool) -> Bool { !hasTrailingAction }

    static let font = DSFont.sectionLabel
    static let tracking: CGFloat = 1.4
    static let labelColor = DSColor.textMuted

    static func label(title: String, count: Int?) -> String {
        guard let count else { return title.uppercased() }
        return "\(title.uppercased()) · \(count)"
    }

    /// Spoken form: the visual "·" would be read as "middle dot".
    static func accessibilityLabel(title: String, count: Int?) -> String {
        let spokenTitle = title.replacingOccurrences(of: " · ", with: ", ")
        guard let count else { return spokenTitle }
        return "\(spokenTitle), \(count) \(count == 1 ? "task" : "tasks")"
    }

    var body: some View {
        if let trailingAction {
            HStack(spacing: 12) {
                label
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Self.accessibilityLabel(title: title, count: count))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button(action: trailingAction.action) {
                    Text(trailingAction.title)
                        .dsFont(.pill)
                        .foregroundStyle(DSColor.accent)
                        .frame(minHeight: DSTouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(trailingAccessibilityLabel ?? trailingAction.title)
            }
        } else {
            HStack(spacing: 12) {
                label
                if Self.showsRule(hasTrailingAction: false) {
                    Rectangle().fill(DSColor.border).frame(height: 1)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.accessibilityLabel(title: title, count: count))
            .accessibilityAddTraits(.isHeader)
        }
    }

    private var label: some View {
        Text(Self.label(title: title, count: count))
            .dsFont(Self.font)
            .tracking(Self.tracking)
            .foregroundStyle(Self.labelColor)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
#Preview("To do") { SectionHeader(title: "To do", count: 3).padding() }
#Preview("Completed") { SectionHeader(title: "Completed", count: 1).padding() }
#Preview("Recent with Clear all") {
    SectionHeader(title: "Recent", trailingAction: (title: "Clear all", action: {})).padding()
}
#Preview("Results count") { SectionHeader(title: "2 results").padding() }
#Preview("By category") { SectionHeader(title: "By category").padding() }
#Preview("Recent - accessibility3") {
    SectionHeader(title: "Recent", trailingAction: (title: "Clear all", action: {})).padding().dynamicTypeSize(.accessibility3)
}
#Preview("Accessibility3") { SectionHeader(title: "Completed", count: 12).padding().dynamicTypeSize(.accessibility3) }
#endif
