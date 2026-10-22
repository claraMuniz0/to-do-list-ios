import SwiftUI

/// Describe screen of Smart add: one sentence in, a draft out. Renders the view model and forwards intent; holds no logic.
struct SmartAddView: View {
    @Bindable var viewModel: SmartAddViewModel
    let onFilled: (TaskDraft) -> Void
    let onManual: () -> Void
    let onClose: () -> Void

    @FocusState private var isInputFocused: Bool
    @State private var fillTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                nav
                ScreenHeader(subtitle: "Just say it", title: "Smart add")
                SmartInputField(
                    text: $viewModel.input,
                    label: "Describe your task",
                    placeholder: "e.g. Dentist next Tuesday at 3pm",
                    counterText: viewModel.counterText,
                    spokenCounterText: viewModel.spokenCounterText,
                    isFocused: $isInputFocused
                )
                .disabled(viewModel.isLoading)
                errorText
                examples
                privacyNote
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .bottom) { fillBar }
        .background(DSGradient.welcome.linearGradient.ignoresSafeArea())
        .accessibilityAction(.escape, close)
        .onAppear {
            isInputFocused = true
            AccessibilityNotification.ScreenChanged().post()
        }
        .onDisappear { fillTask?.cancel() }
        .onChange(of: viewModel.isLoading) { _, loading in
            if loading { AccessibilityNotification.Announcement("Filling in your task").post() }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            guard let message else { return }
            // Back to the field so the user can edit the sentence and try again; high priority so it is not cut off.
            isInputFocused = true
            var announcement = AttributedString(message)
            announcement.accessibilitySpeechAnnouncementPriority = .high
            AccessibilityNotification.Announcement(announcement).post()
        }
    }

    private func close() {
        fillTask?.cancel()
        onClose()
    }

    private func fill() {
        guard fillTask == nil else { return }
        isInputFocused = false
        fillTask = Task {
            let draft = await viewModel.fill()
            fillTask = nil
            if let draft { onFilled(draft) }
        }
    }

    /// Stacks at accessibility text sizes, where Close and the pill no longer fit on one row.
    private var nav: some View {
        ViewThatFits(in: .horizontal) {
            HStack { closeButton; Spacer(minLength: 12); manualButton }
            VStack(alignment: .leading, spacing: 12) { closeButton; manualButton }
        }
    }

    private var closeButton: some View {
        CircleIconButton(accessibilityLabel: "Close", action: close)
            .accessibilityHint("Discards what you typed")
    }

    private var manualButton: some View {
        NavPillButton(
            title: "Manual", systemImage: "pencil.line", style: .outlined,
            accessibilityHint: "Fills the task form yourself", action: onManual
        )
    }

    @ViewBuilder private var errorText: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .dsFont(.rowDescription)
                .foregroundStyle(DSColor.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onAppear { AccessibilityNotification.Announcement(message).post() }
        }
    }

    private var examples: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Or try something like")
                .dsFont(.chipOption)
                .foregroundStyle(DSColor.textSecondary)
                .accessibilityAddTraits(.isHeader)
            ForEach(SmartAddViewModel.examples, id: \.self) { example in
                Button { viewModel.selectExample(example) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(DSColor.accent)
                            .accessibilityHidden(true)
                        Text(example).multilineTextAlignment(.leading)
                    }
                    .dsFont(.smartExample)
                    .foregroundStyle(DSColor.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .frame(minHeight: DSTouchTarget.minimum)
                    .background(DSColor.surface, in: chipShape)
                    .overlay { chipShape.strokeBorder(DSColor.borderControl, lineWidth: 1) }
                    .contentShape(chipShape)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityLabel(example)
                .accessibilityHint("Uses this as your description")
            }
        }
    }

    /// A rounded rectangle, not a capsule, so an example that wraps at large text sizes keeps its padding.
    private var chipShape: RoundedRectangle { RoundedRectangle(cornerRadius: 22, style: .continuous) }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.shield").accessibilityHidden(true)
            Text("Claude fills the form. Your text is sent to Claude. You review before saving.")
        }
        .dsFont(.rowDescription)
        .foregroundStyle(DSColor.textSecondary)
        .accessibilityElement(children: .combine)
    }

    private var fillBar: some View {
        PrimaryButton(
            title: "Fill it in", systemImage: "sparkles", fullWidth: true,
            isEnabled: viewModel.canFill || viewModel.isLoading, isLoading: viewModel.isLoading,
            disabledHint: "Describe your task first", action: fill
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DSColor.bg)
    }
}

#if DEBUG
private struct PreviewParser: TaskDraftParsing {
    let outcome: Result<TaskDraft, SmartAddError>
    var delay: Duration = .zero
    func parse(_ text: SmartAddText, context: SmartAddContext) async throws -> TaskDraft {
        try await Task.sleep(for: delay)
        return try outcome.get()
    }
}

private struct PreviewClock: DateProvider {
    func now() -> Date { Date(timeIntervalSince1970: 1_791_460_800) }
}

extension SmartAddViewModel {
    /// Deterministic view model for previews; `delay` keeps the loading state on screen.
    static func preview(input: String = "", failing: SmartAddError? = nil, delay: Duration = .zero) -> SmartAddViewModel {
        let draft = TaskDraft(
            title: try! TodoItemTitle("Dentist"), description: nil, categoryID: Category.personal.id, dueDate: nil, steps: []
        )
        let useCase = ParseTaskDraftUseCase(
            parser: PreviewParser(outcome: failing.map { .failure($0) } ?? .success(draft), delay: delay),
            dateProvider: PreviewClock(), calendar: .current
        )
        let viewModel = SmartAddViewModel(parseTaskDraft: useCase)
        viewModel.input = input
        return viewModel
    }
}

private struct SmartAddPreviewHost: View {
    @State var viewModel: SmartAddViewModel
    var body: some View {
        SmartAddView(viewModel: viewModel, onFilled: { _ in }, onManual: {}, onClose: {})
    }
}

#Preview("Empty") { SmartAddPreviewHost(viewModel: .preview()) }
#Preview("Filled") {
    SmartAddPreviewHost(viewModel: .preview(input: "Dentist next Tuesday at 3pm, high priority. Bring insurance card."))
}
#Preview("Loading") { SmartAddPreviewHost(viewModel: .preview(input: "Dentist Tuesday", delay: .seconds(3600))) }
#Preview("Error - could not understand") {
    SmartAddPreviewHost(viewModel: .preview(input: "asdf", failing: .couldNotUnderstand))
}
#Preview("Accessibility3") {
    SmartAddPreviewHost(viewModel: .preview(input: "Dentist Tuesday")).dynamicTypeSize(.accessibility3)
}
#endif
