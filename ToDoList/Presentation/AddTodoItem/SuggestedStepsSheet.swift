import SwiftUI

/// Bottom sheet listing Claude's suggested steps: tick which to keep, edit a text, add the chosen ones or ask again.
/// A retry keeps the rows on screen and reports a failure inline, so nothing the user ticked or edited is lost.
struct SuggestedStepsSheet: View {
    @Bindable var viewModel: TodoItemFormViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var editingID: UUID?
    @FocusState private var focusedID: UUID?
    @AccessibilityFocusState private var isHeaderFocused: Bool
    @ScaledMetric(relativeTo: .body) private var ringSize = DSTouchTarget.checkboxRing
    @ScaledMetric(relativeTo: .body) private var checkSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var detentHeight: CGFloat = 520

    private var items: [SuggestedStep] {
        if case .suggestions(let items) = viewModel.suggestionState { return items }
        return []
    }

    private var addTitle: String {
        let count = viewModel.selectedSuggestionCount
        return count == 1 ? "Add 1 step" : "Add \(count) steps"
    }

    private var retryMessage: String? {
        switch viewModel.retryProblem {
        case .failed(.offline): "You're offline. Check your connection and try again."
        case .failed: "Couldn't get new steps. Try again."
        case .empty: "No new steps to suggest."
        default: nil
        }
    }

    /// The ring grows with text size, so its tap frame must too or it would overflow into the step text.
    private var controlSize: CGFloat { max(DSTouchTarget.minimum, ringSize) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                VStack(spacing: 0) {
                    ForEach(items) { item in row(item) }
                }
                .opacity(viewModel.isSuggesting ? 0.5 : 1)
                .disabled(viewModel.isSuggesting)
                if let retryMessage {
                    Text(retryMessage).dsFont(.rowDescription).foregroundStyle(DSColor.danger)
                }
            }
            .padding(20)
        }
        // Pinned so "Add N steps" stays reachable however tall the text gets.
        .safeAreaInset(edge: .bottom) { actions }
        .background(DSColor.surface.ignoresSafeArea())
        .presentationBackground(DSColor.surface)
        .presentationCornerRadius(28)
        // At accessibility sizes the content never fits the partial detent, so only the full sheet is offered.
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(detentHeight), .large])
        .presentationDragIndicator(.visible)
        .accessibilityAction(.escape) { dismiss() }
        .onAppear {
            isHeaderFocused = true
            AccessibilityNotification.Announcement("\(items.count) steps suggested").post()
        }
        .onChange(of: viewModel.isSuggesting) { _, isSuggesting in
            if isSuggesting {
                AccessibilityNotification.Announcement("Thinking of steps").post()
            } else if viewModel.retryProblem == nil {
                AccessibilityNotification.Announcement("\(items.count) new steps suggested").post()
            }
        }
        .onChange(of: viewModel.retryProblem) { _, problem in
            if problem != nil, let retryMessage { AccessibilityNotification.Announcement(retryMessage).post() }
        }
        // Focus is set a tick after the field exists; the pencil always reads "Edit" unless editing stops with it.
        .onChange(of: editingID) { _, id in focusedID = id }
        .onChange(of: focusedID) { _, id in if id == nil { editingID = nil } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DSColor.accent)
                    .frame(width: 44, height: 44)
                    .background(DSColor.accentSoft, in: Circle())
                    .accessibilityHidden(true)
                Spacer()
                CircleIconButton(accessibilityLabel: "Close") { dismiss() }
            }
            Text("Suggested steps")
                .dsFont(.emptyTitle)
                .foregroundStyle(DSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isHeaderFocused)
            Text("For “\(viewModel.title)”")
                .dsFont(.rowDescription)
                .foregroundStyle(DSColor.textSecondary)
        }
    }

    private var actions: some View {
        VStack(spacing: 4) {
            PrimaryButton(
                title: addTitle, systemImage: "checkmark", fullWidth: true,
                isEnabled: viewModel.selectedSuggestionCount > 0 && !viewModel.isSuggesting,
                disabledHint: "Select at least one step"
            ) {
                let count = viewModel.selectedSuggestionCount
                viewModel.addSelectedSuggestions()
                dismiss()
                AccessibilityNotification.Announcement(count == 1 ? "Added 1 step" : "Added \(count) steps").post()
            }
            tryDifferent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(DSColor.surface)
    }

    @ViewBuilder private func row(_ item: SuggestedStep) -> some View {
        if typeSize.isAccessibilitySize {
            // Checkbox and pencil sit above the text so the title keeps the whole width.
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) { checkbox(item); Spacer(minLength: 0); pencil(item) }
                title(item).padding(.leading, 8).padding(.bottom, 8)
            }
        } else {
            HStack(spacing: 4) {
                checkbox(item)
                title(item)
                pencil(item)
            }
            .frame(minHeight: DSTouchTarget.minimum)
        }
    }

    private func checkbox(_ item: SuggestedStep) -> some View {
        Button { viewModel.toggleSuggestion(item.id) } label: {
            ZStack {
                Circle()
                    .fill(item.isSelected ? DSColor.accent : Color.clear)
                    .overlay { Circle().strokeBorder(DSColor.accent, lineWidth: 2) }
                    .frame(width: ringSize, height: ringSize)
                if item.isSelected {
                    Image(systemName: "checkmark").font(.system(size: checkSize, weight: .bold)).foregroundStyle(DSColor.onAccent)
                }
            }
            .frame(width: controlSize, height: controlSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue(item.isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(item.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder private func title(_ item: SuggestedStep) -> some View {
        if editingID == item.id {
            TextField("Step", text: Binding(get: { item.title }, set: { viewModel.editSuggestion(item.id, to: $0) }), axis: .vertical)
                .dsFont(.inputText)
                .foregroundStyle(DSColor.textPrimary)
                .focused($focusedID, equals: item.id)
                .submitLabel(.done)
                .onSubmit { editingID = nil }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Edit step")
        } else {
            Text(item.title).dsFont(.inputText).foregroundStyle(DSColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)
        }
    }

    private func pencil(_ item: SuggestedStep) -> some View {
        Button { editingID = item.id } label: {
            Image(systemName: "pencil")
                .foregroundStyle(DSColor.textMuted)
                .frame(width: DSTouchTarget.minimum, height: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit \(item.title)")
        .accessibilityHint("Changes the text of this step before it is added")
    }

    private var tryDifferent: some View {
        Button { Task { await viewModel.requestSuggestions() } } label: {
            HStack(spacing: 8) {
                if viewModel.isSuggesting { ProgressView().controlSize(.small).tint(DSColor.accent) }
                Label("Try different steps", systemImage: "arrow.clockwise")
            }
            .dsFont(.softButton)
            .foregroundStyle(DSColor.accent)
            .frame(maxWidth: .infinity, minHeight: DSTouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSuggesting)
        .accessibilityValue(viewModel.isSuggesting ? "Thinking of steps" : "")
    }
}

#if DEBUG
#Preview("Suggested steps") {
    let viewModel = TodoItemFormViewModel.preview(editing: .previewGroceries, suggested: ["Check the pantry", "Write the list", "Buy milk and eggs", "Pack the bags"])
    return SuggestedStepsSheet(viewModel: viewModel)
        .task { await viewModel.requestSuggestions() }
}
#Preview("Suggested steps - accessibility3") {
    let viewModel = TodoItemFormViewModel.preview(editing: .previewGroceries, suggested: ["Check the pantry", "Write the list", "Buy milk and eggs"])
    return SuggestedStepsSheet(viewModel: viewModel)
        .dynamicTypeSize(.accessibility3)
        .task { await viewModel.requestSuggestions() }
}
#endif
