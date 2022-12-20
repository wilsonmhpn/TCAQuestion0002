import CasePaths
import ComposableArchitecture
import SwiftUI

struct SheetModifier <ParentState: SceneRouter, ParentAction, ChildState, ChildAction, Destination: View> : ViewModifier {

    let store: Store<ParentState, ParentAction>
    let navigationRoute: ParentState.NavigationRoute
    let presentationAction: (Bool) -> ParentAction
    let childState: (ParentState) -> ChildState?
    let childAction: (ChildAction) -> ParentAction
    let childView: (Store<ChildState, ChildAction>) -> Destination

    public init(
        store: Store<ParentState, ParentAction>,
        navigationRoute: ParentState.NavigationRoute,
        presentationAction: @escaping (Bool) -> ParentAction,
        childState: @escaping (ParentState) -> ChildState?,
        childAction: @escaping (ChildAction) -> ParentAction,
        childView: @escaping (Store<ChildState, ChildAction>) -> Destination
    ) {
        self.store = store
        self.navigationRoute = navigationRoute
        self.presentationAction = presentationAction
        self.childState = childState
        self.childAction = childAction
        self.childView = childView
    }

    public func body(content: Content) -> some View {

        WithViewStore(store.scope(state: \.navRoute)) { (vs: ViewStore<ParentState.NavigationRoute?, ParentAction>) in
            content.sheet(
                isPresented: Binding<Bool>(
                    get: { vs.state == navigationRoute },
                    set: { vs.send(presentationAction($0)) }
                ),
                onDismiss: nil,
                content: {
                    IfLetStore(
                        store.scope(state: childState, action: childAction),
                        then: childView
                    )
                }
            )
        }

    }

}

extension View {
    func sheet <ParentState: SceneRouter, ParentAction, ChildState, ChildAction, Destination: View> (
        store: Store<ParentState, ParentAction>,
        navigationRoute: ParentState.NavigationRoute,
        presentationAction: @escaping (Bool) -> ParentAction,
        childState: @escaping (ParentState) -> ChildState?,
        childAction: @escaping (ChildAction) -> ParentAction,
        childView: @escaping (Store<ChildState, ChildAction>) -> Destination
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: SheetModifier(
                store: store,
                navigationRoute: navigationRoute,
                presentationAction: presentationAction,
                childState: childState,
                childAction: childAction,
                childView: childView
            )
        )
    }
}
