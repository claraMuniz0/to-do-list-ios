import SwiftUI

/// Bottom sheet to pick the due date: quick pills, the system graphical picker and a confirm button.
struct SelectDateView: View {
    @Bindable var viewModel: TodoItemFormViewModel

    @Environment(\.dismiss) private var dismiss

    private var calendar: Calendar { viewModel.calendar }

    private var adapter: DueDatePickerAdapter { DueDatePickerAdapter(calendar: calendar, fallback: viewModel.now) }

    private var pickedDate: Binding<Date> {
        Binding(
            get: { adapter.date(for: viewModel.dueDate) },
            set: { viewModel.dueDate = adapter.dueDate(from: $0) }
        )
    }

    private var allowedRange: PartialRangeFrom<Date> {
        adapter.date(for: viewModel.earliestSelectableDueDate)...
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                quickPills
                DatePicker("Due date", selection: pickedDate, in: allowedRange, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(DSColor.accent)
                    .environment(\.calendar, calendar)
                PrimaryButton(title: "Set date", systemImage: "checkmark", fullWidth: true) { dismiss() }
            }
            .padding(20)
        }
        .background(DSColor.surface.ignoresSafeArea())
        .presentationBackground(DSColor.surface)
        .presentationCornerRadius(28)
        // Designed as a partial sheet; `.large` stays available for accessibility text sizes.
        .presentationDetents([.height(580), .large])
        .presentationDragIndicator(.visible)
    }

    /// Stacks the title above "Clear" when they do not fit on one line (large text sizes).
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack { title; Spacer(); clearButton }
            VStack(alignment: .leading, spacing: 4) { title; clearButton }
        }
    }

    private var title: some View {
        Text("Due date")
            .dsFont(.emptyTitle)
            .foregroundStyle(DSColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var clearButton: some View {
        Button {
            viewModel.clearDueDate()
            AccessibilityNotification.Announcement("Due date cleared").post()
        } label: {
            Text("Clear")
                .dsFont(.pill)
                .foregroundStyle(DSColor.accent)
                .frame(minWidth: DSTouchTarget.minimum, minHeight: DSTouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Clear due date")
    }

    private var quickPills: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { pills }
            VStack(alignment: .leading, spacing: 8) { pills }
        }
    }

    @ViewBuilder private var pills: some View {
        FilterPill(title: "Today", isSelected: viewModel.selectedQuickDate == .today) { viewModel.selectToday() }
        FilterPill(title: "Tomorrow", isSelected: viewModel.selectedQuickDate == .tomorrow) { viewModel.selectTomorrow() }
        FilterPill(title: "Next week", isSelected: viewModel.selectedQuickDate == .nextWeek) { viewModel.selectNextWeek() }
    }
}

#if DEBUG
#Preview("Date sheet") {
    SelectDateView(viewModel: .preview())
}
#Preview("Date sheet - accessibility3") {
    SelectDateView(viewModel: .preview())
        .dynamicTypeSize(.accessibility3)
}
#endif
