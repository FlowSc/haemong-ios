import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {
    @Reducer(state: .equatable)
    enum Path {
        case chatRoom(ChatRoomFeature)
        case botSettings(BotSettingsFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        var auth = AuthFeature.State()
        var login = LoginFeature.State()
        var selectedTab: Tab = .home
        var path = StackState<Path.State>()
        var appLaunchState: AppLaunchState = .launching
        
        enum AppLaunchState: Equatable {
            case launching
            case authenticated
            case needsLogin
        }
        
        enum Tab: CaseIterable {
            case home
            case community
            case profile
            
            var title: String {
                switch self {
                case .home: return "홈"
                case .community: return "커뮤니티"
                case .profile: return "프로필"
                }
            }
            
            var systemImage: String {
                switch self {
                case .home: return "house"
                case .community: return "person.3"
                case .profile: return "person"
                }
            }
        }
    }
    
    enum Action {
        case onAppear
        case auth(AuthFeature.Action)
        case login(LoginFeature.Action)
        case tabSelected(State.Tab)
        case path(StackAction<Path.State, Path.Action>)
        case profileLogoutTapped
        case launchCompleted
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("🔥 AppFeature: 앱 시작, Launch View 표시")
                state.appLaunchState = .launching
                return .run { send in
                    // 최소 1초 동안 런치 스크린 표시
                    try await Task.sleep(for: .seconds(1))
                    await send(.auth(.checkAuthenticationStatus))
                }
                
            case .launchCompleted:
                print("🔥 AppFeature: Launch 완료, 상태에 따라 화면 분기")
                if state.auth.isAuthenticated {
                    state.appLaunchState = .authenticated
                } else {
                    state.appLaunchState = .needsLogin
                }
                return .none
                
            case .auth(.logout):
                state.path.removeAll()
                state.selectedTab = .home
                state.appLaunchState = .needsLogin
                return .none
                
            case .auth(.autoLoginCompleted(.success)):
                print("🔥 AppFeature: 자동 로그인 성공")
                return .send(.launchCompleted)
                
            case .auth(.autoLoginCompleted(.failure)):
                print("🔥 AppFeature: 자동 로그인 실패")
                return .send(.launchCompleted)
                
            case let .login(.loginResponse(.success(response))):
                print("🔥 AppFeature: 로그인 성공 감지, AuthFeature로 전달")
                return .send(.auth(.loginSuccess(response)))
                
            case let .login(.signUpResponse(.success(response))):
                print("🔥 AppFeature: 회원가입 성공 감지, AuthFeature로 전달")
                return .send(.auth(.loginSuccess(response)))
                
            case .auth(.loginSuccess):
                print("🔥 AppFeature: 로그인 성공 후 인증 상태로 전환")
                state.appLaunchState = .authenticated
                return .none
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .profileLogoutTapped:
                return .send(.auth(.logout))
                
            case .auth, .login, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}