import SwiftUI

/// One scrolling screen that shows every design-system component in every state, for visual review.
struct DesignSystemGallery: View {
    @State private var inputText = ""

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

                section("Add task input") {
                    AddTaskInput(text: $inputText, onOptions: {}, onAdd: {})
                }

                section("Task row") {
                    TaskRow(title: "Prepare slides", description: "Quarterly review", categoryName: "Work", palette: .blue, isDone: false, onToggle: {})
                    TaskRow(title: "Buy milk", description: nil, categoryName: "Shopping", palette: .green, isDone: false, onToggle: {})
                    TaskRow(title: "Call mom", description: nil, categoryName: "Personal", palette: .brick, isDone: true, onToggle: {})
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
