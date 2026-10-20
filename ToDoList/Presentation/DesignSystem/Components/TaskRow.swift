import SwiftUI

/// Visual mapping for the two `TaskRow` states (open and done). Pure so it can be unit tested.
struct TaskRowStyle: Equatable {
    let isDone: Bool

    var titleColor: Color { isDone ? DSColor.textSecondary : DSColor.textPrimary }
    /// The design shows the done title without a line-through; muted color carries the state.
    var strikesThroughTitle: Bool { false }
    var surfaceFill: Color { isDone ? DSColor.bg : DSColor.surface }
    var shadow: DSShadow { isDone ? .none : .soft }
    var showsCheckmark: Bool { isDone }

    func chipBackground(for palette: ChipPalette) -> Color {
        isDone ? DSColor.doneChipBackground : palette.background
    }

    func chipForeground(for palette: ChipPalette) -> Color {
        isDone ? DSColor.textSecondary : palette.foreground
    }
}

/// Plain display data for the optional step counter. Unused in the MVP.
struct TaskRowStepProgress: Equatable {
    let completed: Int
    let total: Int
}

struct TaskRow: View {
    let title: String
    let description: String?
    let categoryName: String
    let palette: ChipPalette
    let isDone: Bool
    let stepProgress: TaskRowStepProgress?
    let onToggle: () -> Void

    init(
        title: String,
        description: String? = nil,
        categoryName: String,
        palette: ChipPalette,
        isDone: Bool = false,
        stepProgress: TaskRowStepProgress? = nil,
        onToggle: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.categoryName = categoryName
        self.palette = palette
        self.isDone = isDone
        self.stepProgress = stepProgress
        self.onToggle = onToggle
    }

    private var style: TaskRowStyle { TaskRowStyle(isDone: isDone) }

    var body: some View {
        HStack(spacing: 4) {
            checkbox
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .dsFont(.rowTitle)
                    .foregroundStyle(style.titleColor)
                    .strikethrough(style.strikesThroughTitle)
                if let description, !isDone {
                    Text(description)
                        .dsFont(.rowDescription)
                        .foregroundStyle(DSColor.textSecondary)
                }
                HStack(spacing: 8) {
                    CategoryChip(
                        label: categoryName,
                        palette: palette,
                        backgroundOverride: style.chipBackground(for: palette),
                        foregroundOverride: style.chipForeground(for: palette)
                    )
                    if let stepProgress {
                        Label("\(stepProgress.completed)/\(stepProgress.total)", systemImage: "checklist")
                            .dsFont(.stepCount)
                            .foregroundStyle(DSColor.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .padding(EdgeInsets(top: 14, leading: 8, bottom: 14, trailing: 16))
        .background(style.surfaceFill, in: RoundedRectangle(cornerRadius: DSRadius.md))
        .overlay { RoundedRectangle(cornerRadius: DSRadius.md).strokeBorder(DSColor.border, lineWidth: 1) }
        .dsShadow(style.shadow)
    }

    private var checkbox: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(isDone ? DSColor.accent : Color.clear)
                    .overlay { Circle().strokeBorder(DSColor.accent, lineWidth: 2) }
                    .frame(width: DSTouchTarget.checkboxRing, height: DSTouchTarget.checkboxRing)
                if style.showsCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DSColor.onAccent)
                }
            }
            .frame(width: DSTouchTarget.minimum, height: DSTouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isDone ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isToggle)
    }
}

#if DEBUG
#Preview("Open") { TaskRow(title: "Buy groceries", categoryName: "Shopping", palette: .green) {}.padding() }
#Preview("Open - description") {
    TaskRow(title: "Prepare slides", description: "Quarterly review deck", categoryName: "Work", palette: .blue) {}.padding()
}
#Preview("Open - steps") {
    TaskRow(
        title: "Plan trip", categoryName: "Personal", palette: .brick,
        stepProgress: TaskRowStepProgress(completed: 2, total: 5)
    ) {}.padding()
}
#Preview("Done") {
    TaskRow(title: "Completed task", categoryName: "Work", palette: .blue, isDone: true) {}.padding()
}
#Preview("Long title") {
    TaskRow(
        title: "Call the landlord about the broken heating system in the second bedroom",
        description: "Ask about the repair schedule and whether the building manager can come this week",
        categoryName: "Personal", palette: .brick
    ) {}.padding()
}
#Preview("Accessibility3") {
    TaskRow(title: "Prepare slides", description: "Quarterly review deck", categoryName: "Work", palette: .blue) {}
        .padding()
        .dynamicTypeSize(.accessibility3)
}
#endif
