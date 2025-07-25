import Foundation
import ComposableArchitecture
import Security

// 키체인에 안전하게 토큰을 저장하는 클래스
class TokenStorage {
    static let shared = TokenStorage()
    private init() {}
    
    private let service = "com.haemong.app"
    private let tokenKey = "access_token"
    private let userKey = "current_user"
    
    var currentToken: String? {
        get {
            return getFromKeychain(key: tokenKey)
        }
        set {
            if let token = newValue {
                saveToKeychain(key: tokenKey, value: token)
            } else {
                deleteFromKeychain(key: tokenKey)
            }
        }
    }
    
    var currentUser: User? {
        get {
            guard let data = getDataFromKeychain(key: userKey),
                  let user = try? JSONDecoder().decode(User.self, from: data) else {
                return nil
            }
            return user
        }
        set {
            if let user = newValue {
                if let data = try? JSONEncoder().encode(user) {
                    saveDataToKeychain(key: userKey, data: data)
                }
            } else {
                deleteFromKeychain(key: userKey)
            }
        }
    }
    
    // MARK: - Keychain 헬퍼 메서드
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        saveDataToKeychain(key: key, data: data)
    }
    
    private func saveDataToKeychain(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 기존 항목 삭제
        SecItemDelete(query as CFDictionary)
        
        // 새 항목 추가
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("키체인 저장 실패: \(status)")
        }
    }
    
    private func getFromKeychain(key: String) -> String? {
        guard let data = getDataFromKeychain(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func getDataFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("키체인 삭제 실패: \(status)")
        }
    }
    
    func clearAll() {
        currentToken = nil
        currentUser = nil
    }
}

@Reducer
struct AuthFeature {
    @ObservableState
    struct State: Equatable {
        var currentUser: User?
        var accessToken: String?
        var isAuthenticated: Bool {
            currentUser != nil && accessToken != nil
        }
    }
    
    enum Action {
        case loginSuccess(AuthResponse)
        case logout
        case checkAuthenticationStatus
        case autoLoginCompleted(Result<User, Error>)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .loginSuccess(response):
                print("🔥 AuthFeature: 로그인 성공! User: \(response.user.email)")
                state.currentUser = response.user
                state.accessToken = response.accessToken
                // 키체인에 안전하게 저장
                TokenStorage.shared.currentToken = response.accessToken
                TokenStorage.shared.currentUser = response.user
                print("🔥 AuthFeature: isAuthenticated = \(state.isAuthenticated)")
                return .none
                
            case .logout:
                print("🔥 AuthFeature: 로그아웃 처리")
                state.currentUser = nil
                state.accessToken = nil
                // 키체인에서 모든 인증 정보 삭제
                TokenStorage.shared.clearAll()
                return .none
                
            case .checkAuthenticationStatus:
                print("🔥 AuthFeature: 자동 로그인 확인 중...")
                // 키체인에서 저장된 토큰과 사용자 정보 확인
                if let savedToken = TokenStorage.shared.currentToken,
                   let savedUser = TokenStorage.shared.currentUser {
                    print("🔥 AuthFeature: 저장된 토큰 발견, 검증 중...")
                    return .run { send in
                        do {
                            // 토큰 유효성 검증을 위해 사용자 정보 요청
                            @Dependency(\.apiClient) var apiClient
                            let validatedUser = try await apiClient.validateToken()
                            await send(.autoLoginCompleted(.success(validatedUser)))
                        } catch {
                            print("🔥 AuthFeature: 토큰 검증 실패: \(error)")
                            await send(.autoLoginCompleted(.failure(error)))
                        }
                    }
                } else {
                    print("🔥 AuthFeature: 저장된 토큰 없음, 로그인 화면으로 이동")
                    return .send(.autoLoginCompleted(.failure(APIError.unauthorized)))
                }
                
            case let .autoLoginCompleted(.success(user)):
                print("🔥 AuthFeature: 자동 로그인 성공! User: \(user.email)")
                state.currentUser = user
                state.accessToken = TokenStorage.shared.currentToken
                // 사용자 정보 업데이트 (토큰은 이미 키체인에 있음)
                TokenStorage.shared.currentUser = user
                return .none
                
            case let .autoLoginCompleted(.failure(error)):
                print("🔥 AuthFeature: 자동 로그인 실패: \(error)")
                // 토큰이 만료되었거나 유효하지 않으므로 삭제
                TokenStorage.shared.clearAll()
                state.currentUser = nil
                state.accessToken = nil
                return .none
            }
        }
    }
}