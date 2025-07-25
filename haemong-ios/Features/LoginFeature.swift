import Foundation
import ComposableArchitecture
import AuthenticationServices

@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var errorMessage: String?
        var showingSignUp = false
        
        // 로그인 폼
        var loginEmail = ""
        var loginPassword = ""
        
        // 회원가입 폼
        var signUpEmail = ""
        var signUpPassword = ""
        var signUpConfirmPassword = ""
        var signUpName = ""
    }
    
    enum Action {
        // UI Actions
        case toggleSignUpMode
        case dismissError
        
        // 로그인 폼
        case loginEmailChanged(String)
        case loginPasswordChanged(String)
        case emailLoginTapped
        
        // 회원가입 폼
        case signUpEmailChanged(String)
        case signUpPasswordChanged(String)
        case signUpConfirmPasswordChanged(String)
        case signUpNameChanged(String)
        case emailSignUpTapped
        
        // OAuth
        case googleSignInTapped
        case appleSignInTapped
        case appleSignInCompleted(Result<ASAuthorization, Error>)
        
        // Responses
        case loginResponse(Result<AuthResponse, Error>)
        case signUpResponse(Result<AuthResponse, Error>)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // UI Actions
            case .toggleSignUpMode:
                state.showingSignUp.toggle()
                state.errorMessage = nil
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            // 로그인 폼
            case let .loginEmailChanged(email):
                state.loginEmail = email
                return .none
                
            case let .loginPasswordChanged(password):
                state.loginPassword = password
                return .none
                
            case .emailLoginTapped:
                guard !state.loginEmail.isEmpty, !state.loginPassword.isEmpty else {
                    state.errorMessage = "이메일과 비밀번호를 입력해주세요."
                    return .none
                }
                
                state.isLoading = true
                state.errorMessage = nil
                print("🔥 LoginFeature: 이메일 로그인 시도...")
                
                return .run { [email = state.loginEmail, password = state.loginPassword] send in
                    do {
                        print("🔥 LoginFeature: API 호출 중...")
                        let response = try await apiClient.login(email, password)
                        print("🔥 LoginFeature: 로그인 성공, 응답 전송 중...")
                        await send(.loginResponse(.success(response)))
                    } catch {
                        print("🔥 LoginFeature: 로그인 실패: \(error)")
                        await send(.loginResponse(.failure(error)))
                    }
                }
                
            // 회원가입 폼
            case let .signUpEmailChanged(email):
                state.signUpEmail = email
                return .none
                
            case let .signUpPasswordChanged(password):
                state.signUpPassword = password
                return .none
                
            case let .signUpConfirmPasswordChanged(confirmPassword):
                state.signUpConfirmPassword = confirmPassword
                return .none
                
            case let .signUpNameChanged(name):
                state.signUpName = name
                return .none
                
            case .emailSignUpTapped:
                guard !state.signUpEmail.isEmpty, !state.signUpPassword.isEmpty else {
                    state.errorMessage = "모든 필드를 입력해주세요."
                    return .none
                }
                
                guard state.signUpPassword == state.signUpConfirmPassword else {
                    state.errorMessage = "비밀번호가 일치하지 않습니다."
                    return .none
                }
                
                guard state.signUpPassword.count >= 6 else {
                    state.errorMessage = "비밀번호는 6자 이상이어야 합니다."
                    return .none
                }
                
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { [email = state.signUpEmail, password = state.signUpPassword, name = state.signUpName] send in
                    do {
                        let response = try await apiClient.register(email, password, name.isEmpty ? nil : name)
                        await send(.signUpResponse(.success(response)))
                    } catch {
                        await send(.signUpResponse(.failure(error)))
                    }
                }
                
            // OAuth
            case .googleSignInTapped:
                state.isLoading = true
                state.errorMessage = nil
                
                // Google Sign-In 구현 필요
                // 실제로는 Google Sign-In SDK를 사용해야 합니다
                return .run { send in
                    do {
                        let response = try await apiClient.googleLogin("google_token")
                        await send(.loginResponse(.success(response)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }
                
            case .appleSignInTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .none
                
            case let .appleSignInCompleted(result):
                switch result {
                case .success(let authorization):
                    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        // Apple 토큰 처리
                        return .run { send in
                            do {
                                let tokenString = String(data: appleIDCredential.identityToken ?? Data(), encoding: .utf8) ?? ""
                                let response = try await apiClient.appleLogin(tokenString)
                                await send(.loginResponse(.success(response)))
                            } catch {
                                await send(.loginResponse(.failure(error)))
                            }
                        }
                    }
                    return .send(.loginResponse(.failure(APIError.networkError)))
                    
                case .failure(let error):
                    return .send(.loginResponse(.failure(error)))
                }
                
            case let .loginResponse(.success(response)):
                print("🔥 LoginFeature: 로그인 응답 성공 처리")
                state.isLoading = false
                state.errorMessage = nil
                return .none
                
            case let .loginResponse(.failure(error)):
                print("🔥 LoginFeature: 로그인 응답 실패 처리: \(error)")
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .signUpResponse(.success(response)):
                print("🔥 LoginFeature: 회원가입 응답 성공 처리")
                state.isLoading = false
                state.errorMessage = nil
                return .none
                
            case let .signUpResponse(.failure(error)):
                print("🔥 LoginFeature: 회원가입 응답 실패 처리: \(error)")
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}