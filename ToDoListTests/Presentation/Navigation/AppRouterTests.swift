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
}
