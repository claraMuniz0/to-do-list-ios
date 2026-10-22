import SwiftUI

/// Bottom sheet listing Claude's suggested steps: tick which to keep, edit a text, add the chosen ones or ask again.
struct SuggestedStepsSheet: View {
    @Bindable var viewModel: TodoItemFormViewModel

    @State private var editingID: UUID?
    @FocusState private var focusedID: UUID?
    @ScaledMetric(relativeTo: .body) private var ringSize = DSTouchTarget.checkboxRing

    private var items: [SuggestedStep] {
        if case .suggestions(let items) = viewModel.suggestionState { return items }
        return []
    }

    private var addTitle: String {
        let count = viewModel.selectedSuggestionCount
        return count == 1 ? "Add 1 step" : "Add \(count) steps"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                VStack(spacing: 0) {
                    ForEach(items) { item in row(item) }
                }
                PrimaryButton(
                    title: addTitle, systemImage: "checkmark", fullWidth: true,
                    isEnabled: viewModel.selectedSuggestionCount > 0, disabledHint: "Select at least one step"
                ) { viewModel.addSelectedSuggestions() }
                tryDifferent
            }
            .padding(20)
        }
        .background(DSColor.surface.ignoresSafeArea())
        .presentationBackground(DSColor.surface)
        .presentationCornerRadius(28)
        .presentationDetents([.height(520), .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DSColor.accent)
                .frame(width: 44, height: 44)
                .background(DSColor.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text("Suggested steps")
                .dsFont(.emptyTitle)
                .foregroundStyle(DSColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("For “\(viewModel.title)”")
                .dsFont(.rowDescription)
                .foregroundStyle(DSColor.textSecondary)
        }
    }

    private func row(_ item: SuggestedStep) -> some View {
        HStack(spacing: 4) {
            Button { viewModel.toggleSuggestion(item.id) } label: {
                ZStack {
                    Circle()
                        .fill(item.isSelected ? DSColor.accent : Color.clear)
                        .overlay { Circle().strokeBorder(DSColor.accent, lineWidth: 2) }
                        .frame(width: ringSize, height: ringSize)
                    if item.isSelected {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(DSColor.onAccent)
                    }
                }
                .frame(width: DSTouchTarget.minimum, height: DSTouchTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.title)
            .accessibilityValue(item.isSelected ? "Selected" : "Not selected")

            if editingID == item.id {
                TextField("Step", text: Binding(get: { item.title }, set: { viewModel.editSuggestion(item.id, to: $0) }), axis: .vertical)
                    .dsFont(.inputText)
                    .foregroundStyle(DSColor.textPrimary)
                    .focused($focusedID, equals: item.id)
                    .submitLabel(.done)
                    .onSubmit { editingID = nil }
            } else {
                Text(item.title).dsFont(.inputText).foregroundStyle(DSColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: 0)
            Button {
                editingID = item.id
                focusedID = item.id
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(DSColor.textMuted)
                    .frame(width: DSTouchTarget.minimum, height: DSTouchTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(item.title)")
        }
        .frame(minHeight: DSTouchTarget.minimum)
    }

    private var tryDifferent: some View {
        Button { Task { await viewModel.requestSuggestions() } } label: {
            Label("Try different steps", systemImage: "arrow.clockwise")
                .dsFont(.softButton)
                .foregroundStyle(DSColor.accent)
                .frame(maxWidth: .infinity, minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Suggested steps") {
    let viewModel = TodoItemFormViewModel.preview(editing: .previewGroceries, suggested: ["Check the pantry", "Write the list", "Buy milk and eggs", "Pack the bags"])
    return SuggestedStepsSheet(viewModel: viewModel)
        .task { await viewModel.requestSuggestions() }
}
#endif
