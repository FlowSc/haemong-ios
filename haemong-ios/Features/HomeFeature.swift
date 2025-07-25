import Foundation
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var isNavigatingToChat = false
    }
    
    enum Action {
        case todaysDreamButtonTapped
        case navigateToChat
        case chatNavigationCompleted
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .todaysDreamButtonTapped:
                state.isNavigatingToChat = true
                return .send(.navigateToChat)
                
            case .navigateToChat:
                return .none
                
            case .chatNavigationCompleted:
                state.isNavigatingToChat = false
                return .none
            }
        }
    }
}