import SwiftUI

/// What the Steps header shows and which dividers and move actions each row gets. Pure so it can be unit tested.
struct StepsFieldStyle: Equatable {
    static let title = "Steps"
    static let addPlaceholder = "Add a step"

    let stepCount: Int
    let progress: StepsProgress?
    /// `true` in Edit ("2 of 5" and a bar); `false` for the tag variant of Smart Add Review ("3 steps", no bar).
    let showsProgress: Bool
    let canAdd: Bool

    var headerDetail: String? {
        guard stepCount > 0 else { return nil }
        if showsProgress { return progress?.label }
        return stepCount == 1 ? "1 step" : "\(stepCount) steps"
    }

    var showsProgressBar: Bool { showsProgress && progress != nil }
    var showsAddRow: Bool { canAdd }

    /// Every row keeps its divider except the very last one on the card.
    func showsDivider(at index: Int) -> Bool { index < stepCount - 1 || showsAddRow }
    func canMoveUp(at index: Int) -> Bool { index > 0 && index < stepCount }
    func canMoveDown(at index: Int) -> Bool { index >= 0 && index < stepCount - 1 }
}

/// The pill in the Steps header; `nil` hides it (no Claude key, or Smart Add without a suggestion).
struct StepsFieldSuggestion {
    let title: String
    let isLoading: Bool
    let action: () -> Void
}

/// Steps card: header with count and an optional Claude pill, a progress bar, the step rows and an "Add a step" row.
/// The field never validates: every change goes to the owner, which answers `false` when it rejects the text.
struct StepsField: View {
    let steps: [Step]
    let progress: StepsProgress?
    let canAdd: Bool
    let showsProgress: Bool
    let suggestion: StepsFieldSuggestion?
    let onToggle: (StepID) -> Void
    let onRename: (StepID, String) -> Bool
    let onRemove: (StepID) -> Void
    let onMove: (Int, Int) -> Void
    let onAdd: (String) -> Bool

    init(
        steps: [Step],
        progress: StepsProgress?,
        canAdd: Bool,
        showsProgress: Bool = true,
        suggestion: StepsFieldSuggestion? = nil,
        onToggle: @escaping (StepID) -> Void,
        onRename: @escaping (StepID, String) -> Bool,
        onRemove: @escaping (StepID) -> Void,
        onMove: @escaping (Int, Int) -> Void,
        onAdd: @escaping (String) -> Bool
    ) {
        self.steps = steps
        self.progress = progress
        self.canAdd = canAdd
        self.showsProgress = showsProgress
        self.suggestion = suggestion
        self.onToggle = onToggle
        self.onRename = onRename
        self.onRemove = onRemove
        self.onMove = onMove
        self.onAdd = onAdd
    }

    @State private var openSwipeID: StepID?

    private var style: StepsFieldStyle {
        StepsFieldStyle(stepCount: steps.count, progress: progress, showsProgress: showsProgress, canAdd: canAdd)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if style.showsProgressBar, let progress { StepsProgressBar(progress: progress) }
            if !steps.isEmpty || style.showsAddRow { list }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(StepsFieldStyle.title)
                .dsFont(.chipOption)
                .foregroundStyle(DSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            if let detail = style.headerDetail {
                // The bar already speaks "N of M steps done", so the count text is not read twice.
                Text(detail)
                    .dsFont(.count)
                    .foregroundStyle(DSColor.textMuted)
                    .accessibilityHidden(style.showsProgressBar)
            }
            Spacer(minLength: 8)
            if let suggestion {
                SuggestPill(title: suggestion.title, isLoading: suggestion.isLoading, action: suggestion.action)
            }
        }
    }

    private var list: some View {
        let shape = RoundedRectangle(cornerRadius: DSRadius.md, style: .continuous)
        return VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                SwipeToDeleteRow(
                    isOpen: openSwipeID == step.id,
                    taskTitle: step.title.value,
                    onOpenChange: { openSwipeID = $0 ? step.id : nil },
                    onDelete: { openSwipeID = nil; onRemove(step.id) }
                ) {
                    EditableStepRow(
                        step: step,
                        showsDivider: style.showsDivider(at: index),
                        onToggle: { onToggle(step.id) },
                        onRename: { onRename(step.id, $0) },
                        onMoveUp: style.canMoveUp(at: index) ? { onMove(index, index - 1) } : nil,
                        onMoveDown: style.canMoveDown(at: index) ? { onMove(index, index + 1) } : nil
                    )
                    .background(DSColor.surface)
                }
            }
            if style.showsAddRow { AddStepRow(onAdd: onAdd) }
        }
        .padding(.horizontal, 18)
        .background(DSColor.surface, in: shape)
        .overlay { shape.strokeBorder(DSColor.border, lineWidth: 1) }
        .clipShape(shape)
    }
}

/// Keeps the text being typed apart from the stored title; a rejected rename snaps back to the stored title.
private struct EditableStepRow: View {
    let step: Step
    let showsDivider: Bool
    let onToggle: () -> Void
    let onRename: (String) -> Bool
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    @State private var draft: String

    init(
        step: Step,
        showsDivider: Bool,
        onToggle: @escaping () -> Void,
        onRename: @escaping (String) -> Bool,
        onMoveUp: (() -> Void)?,
        onMoveDown: (() -> Void)?
    ) {
        self.step = step
        self.showsDivider = showsDivider
        self.onToggle = onToggle
        self.onRename = onRename
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        _draft = State(initialValue: step.title.value)
    }

    var body: some View {
        StepRow(
            text: $draft,
            isDone: step.isDone,
            showsDivider: showsDivider,
            onToggle: onToggle,
            onSubmit: { if !onRename($0) { draft = step.title.value } },
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown
        )
        .onChange(of: step.title.value) { _, stored in draft = stored }
    }
}

/// Last row of the card: a plus and an input. A rejected or empty entry leaves the text so the user can fix it.
private struct AddStepRow: View {
    let onAdd: (String) -> Bool

    @State private var text = ""
    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(DSColor.accent)
                .frame(width: StepRowStyle.hitArea, height: StepRowStyle.hitArea)
                .padding(.leading, -(StepRowStyle.hitArea - 24) / 2)
                .accessibilityHidden(true)
            TextField(StepsFieldStyle.addPlaceholder, text: $text)
                .dsFont(.inputText)
                .foregroundStyle(DSColor.textPrimary)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(submit)
                .accessibilityLabel(StepsFieldStyle.addPlaceholder)
        }
        .padding(.vertical, 4)
        .frame(minHeight: StepRowStyle.minRowHeight)
    }

    private func submit() {
        if onAdd(text) { text = "" }
        // Keep typing: the next step is usually one more.
        isFocused = true
    }
}

#if DEBUG
private struct StepsFieldPreviewHost: View {
    @State var steps: [Step]
    var showsProgress = true
    var canAdd = true
    var suggestion: StepsFieldSuggestion? = StepsFieldSuggestion(title: "Suggest more", isLoading: false, action: {})

    var body: some View {
        StepsField(
            steps: steps,
            progress: StepList(steps).progress,
            canAdd: canAdd,
            showsProgress: showsProgress,
            suggestion: suggestion,
            onToggle: { id in if let i = steps.firstIndex(where: { $0.id == id }) { steps[i].toggle() } },
            onRename: { id, text in
                guard let title = try? StepTitle(text), let i = steps.firstIndex(where: { $0.id == id }) else { return false }
                steps[i].rename(title)
                return true
            },
            onRemove: { id in steps.removeAll { $0.id == id } },
            onMove: { from, to in steps.insert(steps.remove(at: from), at: to) },
            onAdd: { text in
                guard let title = try? StepTitle(text) else { return false }
                steps.append(Step(title: title))
                return true
            }
        )
        .padding(20)
    }
}

private func previewSteps(_ titles: [String], done: Set<Int> = []) -> [Step] {
    titles.enumerated().map { Step(title: try! StepTitle($1), isDone: done.contains($0)) }
}

private let sampleTitles = [
    "Check what's left in the pantry", "Write the shopping list", "Pick up milk, eggs and bread",
    "Grab fruit and veggies", "Pack the reusable bags"
]

#Preview("Edit, 2 of 5") { StepsFieldPreviewHost(steps: previewSteps(sampleTitles, done: [0, 1])) }
#Preview("Empty") { StepsFieldPreviewHost(steps: []) }
#Preview("Review tag, no bar") {
    StepsFieldPreviewHost(steps: previewSteps(Array(sampleTitles.prefix(3))), showsProgress: false)
}
#Preview("Loading suggestion") {
    StepsFieldPreviewHost(
        steps: previewSteps(sampleTitles, done: [0]),
        suggestion: StepsFieldSuggestion(title: "Suggest more", isLoading: true, action: {})
    )
}
#Preview("No Claude (pill hidden)") {
    StepsFieldPreviewHost(steps: previewSteps(sampleTitles, done: [0, 1]), suggestion: nil)
}
#Preview("Full list, no add row") {
    StepsFieldPreviewHost(steps: previewSteps((1...20).map { "Step \($0)" }, done: [0]), canAdd: false)
}
#Preview("Accessibility3") {
    StepsFieldPreviewHost(steps: previewSteps(sampleTitles, done: [0, 1])).dynamicTypeSize(.accessibility3)
}
#endif
