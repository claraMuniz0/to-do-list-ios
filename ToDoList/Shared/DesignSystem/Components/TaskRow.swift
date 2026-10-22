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

    var accessibilityValue: String { isDone ? "Completed" : "Not completed" }
    var toggleActionName: String { isDone ? "Mark as not completed" : "Mark as completed" }
    var openHint: String { "Opens the task for editing" }

    /// One spoken label for the whole row. The description is skipped when done because it is not shown.
    func accessibilityLabel(
        title: String, description: String?, categoryName: String, stepProgress: TaskRowStepProgress? = nil
    ) -> String {
        var parts = [title]
        if let description, !description.isEmpty, !isDone { parts.append(description) }
        parts.append(categoryName)
        if let stepProgress { parts.append("\(stepProgress.completed) of \(stepProgress.total) steps done") }
        return parts.joined(separator: ", ")
    }

    func chipBackground(for palette: ChipPalette) -> Color {
        isDone ? DSColor.doneChipBackground : palette.background
    }

    func chipForeground(for palette: ChipPalette) -> Color {
        isDone ? DSColor.textSecondary : palette.foreground
    }
}

/// Plain display data for the optional step counter; `nil` on a task without steps.
struct TaskRowStepProgress: Equatable {
    let completed: Int
    let total: Int

    init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
    }

    init(_ progress: StepsProgress) {
        self.init(completed: progress.done, total: progress.total)
    }
}

/// The description is hidden when `isDone`. The checkbox toggles completion; tapping the rest of the row calls `onOpen`.
/// `stepProgress` is display data only; the row never computes it.
struct TaskRow: View {
    let title: String
    let description: String?
    let categoryName: String
    let palette: ChipPalette
    let isDone: Bool
    let stepProgress: TaskRowStepProgress?
    let onOpen: () -> Void
    let onToggle: () -> Void

    init(
        title: String,
        description: String? = nil,
        categoryName: String,
        palette: ChipPalette,
        isDone: Bool = false,
        stepProgress: TaskRowStepProgress? = nil,
        onOpen: @escaping () -> Void = {},
        onToggle: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.categoryName = categoryName
        self.palette = palette
        self.isDone = isDone
        self.stepProgress = stepProgress
        self.onOpen = onOpen
        self.onToggle = onToggle
    }

    private var style: TaskRowStyle { TaskRowStyle(isDone: isDone) }

    @ScaledMetric(relativeTo: .body) private var ringSize = DSTouchTarget.checkboxRing
    @ScaledMetric(relativeTo: .body) private var checkmarkSize: CGFloat = 14
    private var touchSize: CGFloat { max(DSTouchTarget.minimum, ringSize + 18) }

    private var chip: some View {
        CategoryChip(
            label: categoryName,
            palette: palette,
            backgroundOverride: style.chipBackground(for: palette),
            foregroundOverride: style.chipForeground(for: palette)
        )
    }

    @ViewBuilder private var stepCount: some View {
        if let stepProgress {
            Label("\(stepProgress.completed)/\(stepProgress.total)", systemImage: "checklist")
                .dsFont(.stepCount)
                .foregroundStyle(DSColor.textMuted)
        }
    }

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
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { chip; stepCount }
                    VStack(alignment: .leading, spacing: 6) { chip; stepCount }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The whole row is one VoiceOver element; the visible checkbox stays a real Button for touch and pointer.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(style.accessibilityLabel(title: title, description: description, categoryName: categoryName, stepProgress: stepProgress))
        .accessibilityValue(style.accessibilityValue)
        .accessibilityHint(style.openHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onOpen)
        .accessibilityAction(named: style.toggleActionName, onToggle)
        .padding(EdgeInsets(top: 14, leading: 8, bottom: 14, trailing: 16))
        .dsBackground(style.surfaceFill, in: RoundedRectangle(cornerRadius: DSRadius.md), shadow: style.shadow)
        .overlay { RoundedRectangle(cornerRadius: DSRadius.md).strokeBorder(DSColor.border, lineWidth: 1) }
        .contentShape(RoundedRectangle(cornerRadius: DSRadius.md))
        .onTapGesture(perform: onOpen)
    }

    private var checkbox: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(isDone ? DSColor.accent : Color.clear)
                    .overlay { Circle().strokeBorder(DSColor.accent, lineWidth: 2) }
                    .frame(width: ringSize, height: ringSize)
                if style.showsCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: checkmarkSize, weight: .bold))
                        .foregroundStyle(DSColor.onAccent)
                }
            }
            .frame(width: touchSize, height: touchSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
