import SwiftUI

/// One scrolling screen that shows every design-system component in every state, for visual review.
struct DesignSystemGallery: View {
    @State private var inputText = ""
    @State private var titleText = ""
    @State private var notesText = ""
    @State private var steps = ["Write the list", "Pick up milk", "Pack the bags"].enumerated().map {
        Step(title: try! StepTitle($1), isDone: $0 == 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ScreenHeader(subtitle: "Design system", title: "Gallery")

                section("Category chip") {
                    HStack {
                        CategoryChip(style: .tag, isSelected: false, label: "Work", palette: .blue)
                        CategoryChip(style: .tag, isSelected: false, label: "Personal", palette: .brick)
                        CategoryChip(style: .tag, isSelected: false, label: "Shopping", palette: .green)
                    }
                    HStack {
                        CategoryChip(style: .option, isSelected: false, label: "Work", palette: .blue)
                        CategoryChip(style: .option, isSelected: true, label: "Personal", palette: .brick)
                    }
                }

                section("Primary button") {
                    PrimaryButton(title: "Add task", systemImage: "plus", fullWidth: false, isEnabled: true) {}
                    PrimaryButton(title: "Save", systemImage: "checkmark", fullWidth: true, isEnabled: true) {}
                    PrimaryButton(title: "Save", systemImage: "checkmark", fullWidth: true, isEnabled: false) {}
                }

                section("Filter pill") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterPill(title: "All", isSelected: true) {}
                            FilterPill(title: "Active", isSelected: false) {}
                            FilterPill(title: "Done", isSelected: false) {}
                        
                        }
                    }
                }

                section("Category filter row") {
                    CategoryFilterRow(name: "Work", openCount: 2, palette: .blue, isSelected: true) {}
                    CategoryFilterRow(name: "Personal", openCount: 1, palette: .brick, isSelected: false) {}
                    CategoryFilterRow(name: "Shopping", openCount: 0, palette: .green, isSelected: false) {}
                }

                section("Add task input") {
                    AddTaskInput(text: $inputText, onOptions: {}, onAdd: {})
                }

                section("Task row") {
                    TaskRow(title: "Prepare slides", description: "Quarterly review", categoryName: "Work", palette: .blue, isDone: false, onToggle: {})
                    TaskRow(title: "Buy milk", description: nil, categoryName: "Shopping", palette: .green, isDone: false, onToggle: {})
                    TaskRow(title: "Call mom", description: nil, categoryName: "Personal", palette: .brick, isDone: true, onToggle: {})
                }

                section("Steps") {
                    StepsField(
                        steps: steps,
                        progress: StepList(steps).progress,
                        canAdd: steps.count < StepList.maxSteps,
                        suggestion: StepsFieldSuggestion(title: "Suggest more", isLoading: false, action: {}),
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
                }

                section("Form controls") {
                    FormField(label: "Task name") { TextInputField(text: $titleText) }
                    FormField(label: "Description", isOptional: true) { TextAreaField(text: $notesText) }
                    FormField(label: "Due date") { DateRow(value: "Today, Oct 8") {} }
                    CircleIconButton(accessibilityLabel: "Close") {}
                }

                section("Circular icon button") {
                    HStack(spacing: 8) {
                        CircularIconButton(systemImage: "magnifyingglass", accessibilityLabel: "Search") {}
                        CircularIconButtonLabel(systemImage: "arrow.up.arrow.down")
                    }
                }

                section("Section header") {
                    SectionHeader(title: "To do", count: 3)
                    SectionHeader(title: "Completed", count: 1)
                    SectionHeader(title: "2 results")
                    SectionHeader(title: "Recent", trailingAction: (title: "Clear all", action: {}))
                }

                section("Search bar") {
                    SearchBar.PreviewHost(text: "", focused: false)
                    SearchBar.PreviewHost(text: "gro", focused: true)
                }

                section("Recent search row") {
                    VStack(spacing: 0) {
                        RecentSearchRow(term: "groceries", onSelect: {}, onFill: {})
                        RecentSearchRow(term: "dentist", onSelect: {}, onFill: {})
                        RecentSearchRow(term: "report", showsDivider: false, onSelect: {}, onFill: {})
                    }
                }

                section("Destructive text button") {
                    DestructiveTextButton(title: "Delete task", systemImage: "trash") {}
                }

                section("Undo toast") {
                    UndoToast(message: "Task deleted", onUndo: {})
                }

                section("Empty state illustration") {
                    HStack(alignment: .center, spacing: 16) {
                        EmptyStateIllustration(symbol: "list.clipboard", layout: .welcome)
                            .scaleEffect(0.5).frame(width: 120, height: 120)
                        EmptyStateIllustration(symbol: "party.popper", layout: .celebration)
                            .scaleEffect(0.5).frame(width: 100, height: 100)
                        EmptyStateIllustration(symbol: "magnifyingglass", layout: .noResults)
                            .scaleEffect(0.5).frame(width: 70, height: 70)
                    }
                }
            }
            .padding(16)
        }
        .background(DSColor.bg)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).dsFont(.pill).foregroundStyle(DSColor.textMuted)
            content()
        }
    }
}

#if DEBUG
#Preview("Design system gallery") {
    DesignSystemGallery()
}
#endif
