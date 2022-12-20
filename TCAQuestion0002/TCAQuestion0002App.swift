import ComposableArchitecture
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {

    let store: Store<AppScene.State, AppScene.Action>

    override init() {

        let state = AppScene.State()

        self.store = Store(
            initialState: state,
            reducer: AppScene()
        )

        super.init()

    }
}

@main
struct TCAQuestion0002: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppScene.View(store: appDelegate.store)
        }
    }

}
