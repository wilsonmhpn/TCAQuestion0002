import ComposableArchitecture
import SwiftUI

struct AppScene: ReducerProtocol {
    struct State: Equatable {
        var route: Route? = nil
        var navRoute: NavigationRoute? { route?.navRoute }
    }

    enum Action: Equatable {
        case presentSheet(Bool)
        public enum ActionRoute: Equatable {
            case actionRouteSheet(SheetScene.Action)
        }
        case actionRoute(ActionRoute)
    }
}

extension AppScene.State: SceneRouter {

    enum Route: Equatable {

        case routeSheet(SheetScene.State)

        var navRoute: NavigationRoute {
            switch self {

                case .routeSheet:
                    return .routeSheet

            }
        }
    }

    enum NavigationRoute: Equatable {
        case routeSheet
    }

    var stateSheet: SheetScene.State? {
        routeStateFor(/Route.routeSheet)
    }

}

extension AppScene {
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
                case .presentSheet(true):
                    state.route = .routeSheet(SheetScene.State())
                    return .none

                case .presentSheet(false):
                    state.route = nil
                    return .none

                case .actionRoute(.actionRouteSheet(.dismiss)):
                    return Effect(value: .presentSheet(false))

                case .actionRoute:
                    return .none
            }
        }
        .ifLet(\.route, action: /Action.actionRoute) {
            EmptyReducer()
                .ifCaseLet(/State.Route.routeSheet, action: /Action.ActionRoute.actionRouteSheet) {
                    SheetScene()
                }
        }
    }
}

extension AppScene {

    public struct View: SwiftUI.View {

        private let store: Store<State, Action>

        public init(store: Store<State, Action>) {
            self.store = store
        }

        var body: some SwiftUI.View {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                VStack {
                    Text("AppScene")
                    Button(action: { viewStore.send(.presentSheet(true)) }) {
                        Text("Show Sheet")
                    }
                }
            }
            .sheet(
                store: store,
                navigationRoute: .routeSheet,
                presentationAction: Action.presentSheet,
                childState: \.stateSheet,
                childAction: { Action.actionRoute(.actionRouteSheet($0)) },
                childView: SheetScene.View.init(store:)
            )
        }
    }
}
