import SwiftUI
import ComposableArchitecture
import AuthenticationServices

struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer(minLength: 50)
                
                // 앱 로고와 제목
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("해몽")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AI가 해석하는 당신의 꿈")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 이메일 로그인/회원가입 폼
                if store.showingSignUp {
                    SignUpFormView(store: store)
                } else {
                    LoginFormView(store: store)
                }
                
                // 구분선
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("또는")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal, 40)
                
                // OAuth 로그인 버튼들
                VStack(spacing: 16) {
                    // Google 로그인 버튼
                    Button(action: {
                        store.send(.googleSignInTapped)
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title2)
                            Text("Google로 계속하기")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(25)
                    }
                    .disabled(store.isLoading)
                    
                    // Apple 로그인 버튼
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            store.send(.appleSignInCompleted(result))
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(25)
                    .disabled(store.isLoading)
                }
                .padding(.horizontal, 40)
                
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .onTapGesture {
                            store.send(.dismissError)
                        }
                }
                
                // 로그인/회원가입 전환 버튼
                Button(action: {
                    store.send(.toggleSignUpMode)
                }) {
                    HStack {
                        Text(store.showingSignUp ? "이미 계정이 있으신가요?" : "계정이 없으신가요?")
                            .foregroundColor(.secondary)
                        Text(store.showingSignUp ? "로그인" : "회원가입")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 10)
                
                Spacer(minLength: 50)
            }
        }
        .padding()
        .overlay(
            Group {
                if store.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        )
    }
}

// MARK: - Login Form
struct LoginFormView: View {
    @Bindable var store: StoreOf<LoginFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            Text("로그인")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // 이메일 입력
            TextField("이메일", text: $store.loginEmail.sending(\.loginEmailChanged))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            // 비밀번호 입력
            SecureField("비밀번호", text: $store.loginPassword.sending(\.loginPasswordChanged))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 로그인 버튼
            Button(action: {
                store.send(.emailLoginTapped)
            }) {
                Text("로그인")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(store.isLoading || store.loginEmail.isEmpty || store.loginPassword.isEmpty)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Sign Up Form
struct SignUpFormView: View {
    @Bindable var store: StoreOf<LoginFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            Text("회원가입")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            // 이름 입력 (선택사항)
            TextField("이름 (선택사항)", text: $store.signUpName.sending(\.signUpNameChanged))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
            
            // 이메일 입력
            TextField("이메일", text: $store.signUpEmail.sending(\.signUpEmailChanged))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            // 비밀번호 입력
            SecureField("비밀번호 (6자 이상)", text: $store.signUpPassword.sending(\.signUpPasswordChanged))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 비밀번호 확인
            SecureField("비밀번호 확인", text: $store.signUpConfirmPassword.sending(\.signUpConfirmPasswordChanged))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // 회원가입 버튼
            Button(action: {
                store.send(.emailSignUpTapped)
            }) {
                Text("회원가입")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .disabled(store.isLoading || store.signUpEmail.isEmpty || store.signUpPassword.isEmpty || store.signUpConfirmPassword.isEmpty)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
        }
    )
}