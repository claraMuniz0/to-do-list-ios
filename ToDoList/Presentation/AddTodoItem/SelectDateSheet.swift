import SwiftUI

/// Bottom sheet to pick the due date: quick pills, the system graphical picker and a confirm button.
struct SelectDateSheet: View {
    @Bindable var viewModel: AddTodoItemViewModel
    var calendar: Calendar = .current
    var today: Date = .now

    @Environment(\.dismiss) private var dismiss

    private var adapter: DueDatePickerAdapter { DueDatePickerAdapter(calendar: calendar, fallback: today) }

    private var pickedDate: Binding<Date> {
        Binding(
            get: { adapter.date(for: viewModel.dueDate) },
            set: { viewModel.dueDate = adapter.dueDate(from: $0) }
        )
    }

    /// New dates start today; an already-chosen earlier date stays selectable so it is not silently moved.
    private var allowedRange: PartialRangeFrom<Date> {
        min(calendar.startOfDay(for: today), pickedDate.wrappedValue)...
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Due date")
                        .dsFont(.emptyTitle)
                        .foregroundStyle(DSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button { viewModel.clearDueDate() } label: {
                        Text("Clear")
                            .dsFont(.pill)
                            .foregroundStyle(DSColor.accent)
                            .frame(minWidth: DSTouchTarget.minimum, minHeight: DSTouchTarget.minimum)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear due date")
                }
                quickPills
                DatePicker("Due date", selection: pickedDate, in: allowedRange, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(DSColor.accent)
                    .environment(\.calendar, calendar)
                PrimaryButton(title: "Done", systemImage: "checkmark", fullWidth: true) { dismiss() }
            }
            .padding(20)
        }
        .background(DSColor.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
    SelectDateSheet(
        viewModel: .preview(),
        calendar: Calendar(identifier: .gregorian),
        today: Date(timeIntervalSince1970: 1_791_460_800)
    )
}
#Preview("Date sheet - accessibility3") {
    SelectDateSheet(viewModel: .preview(), today: Date(timeIntervalSince1970: 1_791_460_800))
        .dynamicTypeSize(.accessibility3)
}
#endif
