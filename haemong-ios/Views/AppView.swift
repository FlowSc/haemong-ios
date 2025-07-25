import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        WithViewStore(store, observe: \.appLaunchState) { viewStore in
            let _ = print("🔥 AppView: appLaunchState = \(viewStore.state)")
            
            switch viewStore.state {
            case .launching:
                AppLaunchView()
                
            case .authenticated:
                MainTabView(store: store)
                
            case .needsLogin:
                LoginView(
                    store: store.scope(state: \.login, action: \.login)
                )
            }
        }
            .onAppear {
                store.send(.onAppear)
            }
    }
}

struct AppLaunchView: View {
    var body: some View {
        Color.clear
            .overlay(
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 30) {
                    Spacer()
                    // 앱 로고/아이콘
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    // 앱 이름
                    Text("해몽")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                    
                    Text("꿈을 해석해드립니다")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    // 로딩 인디케이터
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("로딩 중...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
            )
            .ignoresSafeArea()
    }
}

struct MainTabView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            HomeView(
                store: Store(initialState: HomeFeature.State()) {
                    HomeFeature()
                }
            )
            .tabItem {
                Image(systemName: AppFeature.State.Tab.home.systemImage)
                Text(AppFeature.State.Tab.home.title)
            }
            .tag(AppFeature.State.Tab.home)
            
            CommunityView()
            .tabItem {
                Image(systemName: AppFeature.State.Tab.community.systemImage)
                Text(AppFeature.State.Tab.community.title)
            }
            .tag(AppFeature.State.Tab.community)
            
            ProfileView(store: store)
            .tabItem {
                Image(systemName: AppFeature.State.Tab.profile.systemImage)
                Text(AppFeature.State.Tab.profile.title)
            }
            .tag(AppFeature.State.Tab.profile)
        }
    }
}

struct ProfileView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // 프로필 이미지
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                // 사용자 정보
                if let user = store.auth.currentUser {
                    VStack(spacing: 8) {
                        Text(user.name ?? "사용자")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("로그인 방식: \(user.provider.rawValue.capitalized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 로그아웃 버튼
                Button("로그아웃") {
                    store.send(.profileLogoutTapped)
                }
                .foregroundColor(.red)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview("AppView") {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}

#Preview("AppLaunchView") {
    AppLaunchView()
}
