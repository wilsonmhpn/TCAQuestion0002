import ComposableArchitecture
import SwiftUI

public struct ThingWithManyResults {

    private var timer: Timer

    init(name: String, timeInterval: TimeInterval, _ resultHandler: @escaping (String) -> ()) {
        var count = 0
        timer = Timer(timeInterval: timeInterval, repeats: true) { _ in
            resultHandler("\(name): \(count)")
            count += 1
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    func cancel() {
        timer.invalidate()
    }

    static func asyncStream(name: String, timeInterval: TimeInterval) async -> AsyncStream<String> {
        return AsyncStream<String>() { continuation in
            let sub = ThingWithManyResults(name: name, timeInterval: timeInterval) { result in
                continuation.yield(result)
            }

            continuation.onTermination = { _ in
                print("\(name) cleanup onTermination")
                sub.cancel()
            }
        }
    }

}

struct SheetScene: ReducerProtocol {

    struct State: Equatable {
        var latestOfManyAsyncResults = "N/A"
    }

    enum Action: Equatable {
        case begin
        case dismiss
        case latestOfManyAsyncResults(String)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {

        switch action {

            case .begin:
                // Sufficiently fast updates on this results in parent receiving a child action when child state was "nil" via this send..
                return .run { send in
                    for await result in await ThingWithManyResults.asyncStream(name: "Sheet Scene", timeInterval: 0.1) {
                        await send(.latestOfManyAsyncResults(result))
                    }
                }

            case let .latestOfManyAsyncResults(result):
                state.latestOfManyAsyncResults = result
                return .none

            case .dismiss:
                // Parent takes care of this
                return .none

        }
    }

    public struct View: SwiftUI.View {

        private let store: Store<State, Action>

        public init(store: Store<State, Action>) {
            self.store = store
        }

        var body: some SwiftUI.View {
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                VStack {
                    Text(viewStore.latestOfManyAsyncResults)
                    Button(action: { viewStore.send(.dismiss) }) {
                        Text("Dismiss")
                    }
                }
                .task { await viewStore.send(.begin).finish() }
            }
        }
    }
}
