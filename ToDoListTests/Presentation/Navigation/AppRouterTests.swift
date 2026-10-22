import Testing
@testable import MyApp

@MainActor
struct AppRouterTests {
    @Test func startsWithNothingPresented() {
        #expect(AppRouter().presentedRoute == nil)
    }

    @Test func presentingARouteExposesIt() {
        let router = AppRouter()
        router.present(.addTodoItem(prefill: ""))
        #expect(router.presentedRoute == .addTodoItem(prefill: ""))
    }

    @Test func presentingCarriesThePrefillText() {
        let router = AppRouter()
        router.present(.addTodoItem(prefill: "Call the dentist"))
        #expect(router.presentedRoute == .addTodoItem(prefill: "Call the dentist"))
    }

    @Test func dismissClearsThePresentedRoute() {
        let router = AppRouter()
        router.present(.addTodoItem(prefill: ""))
        router.dismiss()
        #expect(router.presentedRoute == nil)
    }

    @Test func dismissWithNothingPresentedIsANoOp() {
        let router = AppRouter()
        router.dismiss()
        #expect(router.presentedRoute == nil)
    }

    @Test func presentingEditCarriesTheTaskID() {
        let router = AppRouter()
        let id = TodoItemID()
        router.present(.editTodoItem(id: id))
        #expect(router.presentedRoute == .editTodoItem(id: id))
    }

    @Test func editRoutesForDifferentTasksAreDifferent() {
        #expect(AppRoute.editTodoItem(id: TodoItemID()) != AppRoute.editTodoItem(id: TodoItemID()))
    }

    // MARK: Search and cover over cover

    @Test func presentingSearchExposesIt() {
        let router = AppRouter()
        router.present(.search)
        #expect(router.presentedRoute == .search)
        #expect(router.nestedRoute == nil)
    }

    @Test func addPresentedWhileSearchIsOpenCoversSearch() {
        let router = AppRouter()
        router.present(.search)
        router.present(.addTodoItem(prefill: "gym"))
        #expect(router.presentedRoute == .search)
        #expect(router.nestedRoute == .addTodoItem(prefill: "gym"))
    }

    @Test func editPresentedWhileSearchIsOpenCoversSearch() {
        let router = AppRouter()
        let id = TodoItemID()
        router.present(.search)
        router.present(.editTodoItem(id: id))
        #expect(router.presentedRoute == .search)
        #expect(router.nestedRoute == .editTodoItem(id: id))
    }

    @Test func dismissClosesTheNestedCoverFirstAndKeepsSearch() {
        let router = AppRouter()
        router.present(.search)
        router.present(.addTodoItem(prefill: ""))
        router.dismiss()
        #expect(router.presentedRoute == .search)
        #expect(router.nestedRoute == nil)
    }

    @Test func dismissingTwiceClosesSearchToo() {
        let router = AppRouter()
        router.present(.search)
        router.present(.addTodoItem(prefill: ""))
        router.dismiss()
        router.dismiss()
        #expect(router.presentedRoute == nil)
    }

    @Test func dismissAllClosesEveryCover() {
        let router = AppRouter()
        router.present(.search)
        router.present(.addTodoItem(prefill: ""))
        router.dismissAll()
        #expect(router.presentedRoute == nil)
        #expect(router.nestedRoute == nil)
    }

    @Test func addPresentedWithoutSearchHasNoNestedRoute() {
        let router = AppRouter()
        router.present(.addTodoItem(prefill: ""))
        #expect(router.nestedRoute == nil)
    }

    @Test func presentingSearchOverAFormReplacesItAndClearsNesting() {
        let router = AppRouter()
        router.present(.addTodoItem(prefill: ""))
        router.present(.search)
        #expect(router.presentedRoute == .search)
        #expect(router.nestedRoute == nil)
    }

    @Test func presentingSearchAgainKeepsASingleSearchCover() {
        let router = AppRouter()
        router.present(.search)
        router.present(.addTodoItem(prefill: ""))
        router.present(.search)
        #expect(router.presentedRoute == .search)
        #expect(router.nestedRoute == nil)
    }

    @Test func presentingAnotherRouteReplacesTheCurrentOne() {
        let router = AppRouter()
        router.present(.addTodoItem(prefill: ""))
        let id = TodoItemID()
        router.present(.editTodoItem(id: id))
        #expect(router.presentedRoute == .editTodoItem(id: id))
    }
}
