import SwiftUI

/// Copy and sizes of the search bar, kept apart from the views so they are unit tested.
enum SearchFieldRules {
    static let placeholder = "Search tasks..."
    static let accessibilityLabel = "Search tasks"
    static let clearAccessibilityLabel = "Clear text"
    static let cancelTitle = "Cancel"
    static let height: CGFloat = 48
    static let minimumTapTarget: CGFloat = DSTouchTarget.minimum

    /// Whitespace counts as text: the user can still wipe it with one tap.
    static func showsClear(for text: String) -> Bool { !text.isEmpty }
}

/// 48pt pill field with the accent search icon and a clear button. The host owns focus so the clear
/// button can keep the keyboard open: pass a `@FocusState` binding.
/// The accent stroke is always drawn while focused (as in all three designed frames).
struct SearchField: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    init(text: Binding<String>, isFocused: FocusState<Bool>.Binding, onSubmit: @escaping () -> Void = {}) {
        self._text = text
        self.isFocused = isFocused
        self.onSubmit = onSubmit
    }

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: iconSize))
                .foregroundStyle(DSColor.accent)
                .accessibilityHidden(true)
            TextField(
                SearchFieldRules.accessibilityLabel,
                text: $text,
                prompt: Text(SearchFieldRules.placeholder).foregroundStyle(DSColor.textMuted)
            )
            .dsFont(.inputText)
            .foregroundStyle(DSColor.textPrimary)
            .tint(DSColor.accent)
            .focused(isFocused)
            .submitLabel(.search)
            .onSubmit(onSubmit)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .accessibilityLabel(SearchFieldRules.accessibilityLabel)
            if SearchFieldRules.showsClear(for: text) {
                clearButton
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, SearchFieldRules.showsClear(for: text) ? 2 : 16)
        .frame(minHeight: SearchFieldRules.height)
        .dsBackground(DSColor.surface, in: Capsule())
        .overlay {
            Capsule().strokeBorder(
                isFocused.wrappedValue ? DSColor.accent : DSColor.borderControl,
                lineWidth: isFocused.wrappedValue ? 2 : 1
            )
        }
    }

    private var clearButton: some View {
        Button {
            text = ""
            isFocused.wrappedValue = true
        } label: {
            Image(systemName: "xmark.circle")
                .font(.system(size: iconSize))
                .foregroundStyle(DSColor.textMuted)
                .frame(minWidth: SearchFieldRules.minimumTapTarget, minHeight: SearchFieldRules.minimumTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SearchFieldRules.clearAccessibilityLabel)
    }
}

/// The search field plus the trailing accent "Cancel" text button (44pt tall).
/// At accessibility sizes Cancel moves under the field so the text keeps its width.
struct SearchBar: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onCancel: () -> Void

    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        onSubmit: @escaping () -> Void = {},
        onCancel: @escaping () -> Void
    ) {
        self._text = text
        self.isFocused = isFocused
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .trailing, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            SearchField(text: $text, isFocused: isFocused, onSubmit: onSubmit)
            Button(action: onCancel) {
                Text(SearchFieldRules.cancelTitle)
                    .dsFont(.softButton)
                    .foregroundStyle(DSColor.accent)
                    .frame(minHeight: SearchFieldRules.minimumTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

extension SearchBar {
    /// Deterministic sample host: the focus state lives in the preview, never in the component.
    struct PreviewHost: View {
        @State var text: String
        @FocusState private var focused: Bool
        let startsFocused: Bool

        init(text: String = "", focused: Bool = true) {
            _text = State(initialValue: text)
            startsFocused = focused
        }

        var body: some View {
            SearchBar(text: $text, isFocused: $focused, onCancel: {})
                .padding()
                .background(DSColor.bg)
                .task { focused = startsFocused }
        }
    }
}

#if DEBUG
#Preview("Empty, focused") { SearchBar.PreviewHost() }
#Preview("With text") { SearchBar.PreviewHost(text: "gro") }
#Preview("Not focused") { SearchBar.PreviewHost(text: "gym", focused: false) }
#Preview("Long text") {
    SearchBar.PreviewHost(text: "Buy groceries for the week and plan the dentist visit")
}
#Preview("Accessibility3") { SearchBar.PreviewHost(text: "gro").dynamicTypeSize(.accessibility3) }
#endif
