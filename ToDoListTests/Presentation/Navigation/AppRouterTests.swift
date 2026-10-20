import Testing
@testable import MyApp

@MainActor
struct AppRouterTests {
    @Test func startsWithNothingPresented() {
        #expect(AppRouter().presentedRoute == nil)
    }

    @Test func presentingARouteExposesIt() {
        let router = AppRouter()
        router.present(.addTodoItem)
        #expect(router.presentedRoute == .addTodoItem)
    }

    @Test func dismissClearsThePresentedRoute() {
        let router = AppRouter()
        router.present(.addTodoItem)
        router.dismiss()
        #expect(router.presentedRoute == nil)
    }

    @Test func dismissWithNothingPresentedIsANoOp() {
        let router = AppRouter()
        router.dismiss()
        #expect(router.presentedRoute == nil)
    }
}
