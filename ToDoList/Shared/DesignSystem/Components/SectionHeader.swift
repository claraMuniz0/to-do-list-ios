import SwiftUI

/// "TO DO · 3" style label followed by a thin rule.
struct SectionHeader: View {
    let title: String
    let count: Int

    init(title: String, count: Int) {
        self.title = title
        self.count = count
    }

    static func label(title: String, count: Int) -> String {
        "\(title.uppercased()) · \(count)"
    }

    /// Spoken form: the visual "·" would be read as "middle dot".
    static func accessibilityLabel(title: String, count: Int) -> String {
        "\(title), \(count) \(count == 1 ? "task" : "tasks")"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(Self.label(title: title, count: count))
                .dsFont(.chipTag)
                .tracking(1)
                .foregroundStyle(DSColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(DSColor.border).frame(height: 1)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityLabel(title: title, count: count))
        .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
#Preview("To do") { SectionHeader(title: "To do", count: 3).padding() }
#Preview("Completed") { SectionHeader(title: "Completed", count: 1).padding() }
#Preview("Accessibility3") { SectionHeader(title: "Completed", count: 12).padding().dynamicTypeSize(.accessibility3) }
#endif
