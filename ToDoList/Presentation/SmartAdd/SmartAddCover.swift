import SwiftUI

/// One full-screen cover for the whole Smart add flow: Describe first, then Review once Claude has answered.
/// Review is the regular form in `.reviewingDraft` mode, so saving and closing report through the same outcomes.
/// Holds both view models in `@State` so they are created once per presentation.
struct SmartAddCover: View {
    @State private var viewModel: SmartAddViewModel
    @State private var reviewViewModel: TodoItemFormViewModel?
    let makeFormViewModel: (TodoItemFormMode) -> TodoItemFormViewModel
    let onManual: () -> Void
    let onFinish: (TodoItemFormOutcome) -> Void

    init(
        makeViewModel: () -> SmartAddViewModel,
        makeFormViewModel: @escaping (TodoItemFormMode) -> TodoItemFormViewModel,
        onManual: @escaping () -> Void,
        onFinish: @escaping (TodoItemFormOutcome) -> Void
    ) {
        _viewModel = State(initialValue: makeViewModel())
        self.makeFormViewModel = makeFormViewModel
        self.onManual = onManual
        self.onFinish = onFinish
    }

    var body: some View {
        if let reviewViewModel {
            TodoItemFormView(viewModel: reviewViewModel, onFinish: onFinish)
        } else {
            SmartAddView(
                viewModel: viewModel,
                onFilled: { reviewViewModel = makeFormViewModel(.reviewingDraft($0)) },
                onManual: onManual,
                onClose: { onFinish(.cancelled) }
            )
        }
    }
}
