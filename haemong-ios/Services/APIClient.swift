import Foundation
import ComposableArchitecture

@DependencyClient
struct APIClient {
    var register: @Sendable (String, String, String?) async throws -> AuthResponse
    var login: @Sendable (String, String) async throws -> AuthResponse
    var googleLogin: @Sendable (String) async throws -> AuthResponse
    var appleLogin: @Sendable (String) async throws -> AuthResponse
    var validateToken: @Sendable () async throws -> User
    var getTodaysChatRoom: @Sendable () async throws -> ChatRoomResponse
    var updateBotSettings: @Sendable (String, BotType) async throws -> Void
    var getMessages: @Sendable (String) async throws -> [Message]
    var sendMessage: @Sendable (String, String) async throws -> SendMessageResponse
    var getChatRoomsByMonth: @Sendable (String) async throws -> ChatRoomListResponse
    var getChatRoomById: @Sendable (String) async throws -> ChatRoomResponse
    var generateImage: @Sendable (String) async throws -> ImageGenerationResponse
}

// 현재 토큰을 가져오는 dependency
private enum CurrentTokenKey: DependencyKey {
    static let liveValue: @Sendable () -> String? = { TokenStorage.shared.currentToken }
    static let testValue: @Sendable () -> String? = { "test-token" }
}

extension DependencyValues {
    var currentToken: @Sendable () -> String? {
        get { self[CurrentTokenKey.self] }
        set { self[CurrentTokenKey.self] = newValue }
    }
}

extension APIClient: DependencyKey {
    static let liveValue: APIClient = {
        let baseURL = "http://localhost:3000" // API URL 설정 필요
        
        return APIClient(
            register: { email, password, name in
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/auth/register",
                    method: "POST",
                    body: [
                        "email": email,
                        "password": password,
                        "name": name ?? "",
                        "provider": "email"
                    ]
                )
                
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(AuthResponse.self, from: data)
            },
            
            login: { email, password in
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/auth/login",
                    method: "POST",
                    body: ["email": email, "password": password]
                )
                
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(AuthResponse.self, from: data)
            },
            
            googleLogin: { token in
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/auth/google",
                    method: "POST",
                    body: ["token": token]
                )
                
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(AuthResponse.self, from: data)
            },
            
            appleLogin: { token in
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/auth/apple",
                    method: "POST",
                    body: ["token": token]
                )
                
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(AuthResponse.self, from: data)
            },
            
            validateToken: {
                @Dependency(\.currentToken) var currentToken
                guard let token = currentToken() else {
                    throw APIError.unauthorized
                }
                
                print("🔥 API Debug: validateToken - 기존 API로 토큰 검증 시작")
                
                // 기존 getTodaysChatRoom API를 사용해서 토큰 유효성 검증
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms/today",
                    method: "GET",
                    token: token
                )
                
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔥 API Debug: validateToken - status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                }
                
                // 토큰이 유효하면 저장된 사용자 정보 반환
                guard let savedUser = TokenStorage.shared.currentUser else {
                    print("🔥 API Debug: validateToken - 저장된 사용자 정보 없음")
                    throw APIError.unauthorized
                }
                
                print("🔥 API Debug: validateToken - 토큰 유효, 저장된 사용자 반환: \(savedUser.email)")
                return savedUser
            },
            
            getTodaysChatRoom: {
                @Dependency(\.currentToken) var currentToken
                let token = currentToken()
                print("🔥 API Debug: getTodaysChatRoom - token: \(token ?? "nil")")
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms/today",
                    method: "GET",
                    token: token
                )
                
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔥 API Debug: getTodaysChatRoom - status: \(httpResponse.statusCode)")
                }
                return try JSONDecoder().decode(ChatRoomResponse.self, from: data)
            },
            
            updateBotSettings: { roomId, botType in
                @Dependency(\.currentToken) var currentToken
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms/\(roomId)/bot-settings",
                    method: "PUT",
                    body: ["gender": botType.gender, "style": botType.style],
                    token: currentToken()
                )
                
                let (_, _) = try await URLSession.shared.data(for: request)
            },
            
            getMessages: { roomId in
                @Dependency(\.currentToken) var currentToken
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms/\(roomId)/messages",
                    method: "GET",
                    token: currentToken()
                )
                
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode([Message].self, from: data)
            },
            
            sendMessage: { roomId, content in
                @Dependency(\.currentToken) var currentToken
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms/\(roomId)/messages",
                    method: "POST",
                    body: ["content": content],
                    token: currentToken()
                )
                
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(SendMessageResponse.self, from: data)
            },
            
            getChatRoomsByMonth: { monthString in
                @Dependency(\.currentToken) var currentToken
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms?month=\(monthString)",
                    method: "GET",
                    token: currentToken()
                )
                
                let (data, _) = try await URLSession.shared.data(for: request)
                return try JSONDecoder().decode(ChatRoomListResponse.self, from: data)
            },
            
            getChatRoomById: { roomId in
                @Dependency(\.currentToken) var currentToken
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms/\(roomId)",
                    method: "GET",
                    token: currentToken()
                )
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        return try JSONDecoder().decode(ChatRoomResponse.self, from: data)
                    case 404:
                        throw APIError(message: "해당 채팅룸을 찾을 수 없습니다.", code: 404)
                    case 401:
                        throw APIError.unauthorized
                    default:
                        throw APIError(message: "서버 오류가 발생했습니다.", code: httpResponse.statusCode)
                    }
                }
                
                return try JSONDecoder().decode(ChatRoomResponse.self, from: data)
            },
            
            generateImage: { roomId in
                @Dependency(\.currentToken) var currentToken
                let request = try createRequest(
                    baseURL: baseURL,
                    endpoint: "/chat/rooms/today/messages/generate-image",
                    method: "POST",
                    token: currentToken()
                )
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200, 201:
                        return try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
                    case 404:
                        throw APIError(message: "채팅룸을 찾을 수 없습니다.", code: 404)
                    case 401:
                        throw APIError.unauthorized
                    case 403:
                        throw APIError(message: "프리미엄 사용자만 이용 가능합니다.", code: 403)
                    default:
                        throw APIError(message: "이미지 생성에 실패했습니다.", code: httpResponse.statusCode)
                    }
                }
                
                return try JSONDecoder().decode(ImageGenerationResponse.self, from: data)
            }
        )
    }()
    
//    static let testValue = APIClient(
//        register: { email, password, name in
//            // 간단한 딜레이를 추가하여 실제 API 호출을 시뮬레이션
//            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
//            return AuthResponse(
//                user: User(
//                    id: "test-user",
//                    email: email,
//                    name: name,
//                    profileImage: nil,
//                    provider: .google,
//                    createdAt: Date(),
//                    updatedAt: Date()
//                ),
//                accessToken: "test-token"
//            )
//        },
//        login: { email, password in
//            // 간단한 딜레이를 추가하여 실제 API 호출을 시뮬레이션
//            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
//            return AuthResponse(
//                user: User(
//                    id: "test-user",
//                    email: email,
//                    name: "Test User",
//                    profileImage: nil,
//                    provider: .google,
//                    createdAt: Date(),
//                    updatedAt: Date()
//                ),
//                accessToken: "test-token"
//            )
//        },
//        googleLogin: { _ in
//            AuthResponse(
//                user: User(
//                    id: "test-user",
//                    email: "test@example.com",
//                    name: "Test User",
//                    profileImage: nil,
//                    provider: .google,
//                    createdAt: Date(),
//                    updatedAt: Date()
//                ),
//                accessToken: "test-token"
//            )
//        },
//        appleLogin: { _ in
//            AuthResponse(
//                user: User(
//                    id: "test-user",
//                    email: "test@example.com",
//                    name: "Test User",
//                    profileImage: nil,
//                    provider: .apple,
//                    createdAt: Date(),
//                    updatedAt: Date()
//                ),
//                accessToken: "test-token"
//            )
//        },
//        getTodaysChatRoom: {
//            ChatRoom(
//                id: "test-room",
//                userId: "test-user",
//                date: Date(),
//                botPersonality: BotPersonality(
//                    type: .easternFemale,
//                    name: "해몽이",
//                    description: "친근한 해몽사"
//                ),
//                createdAt: Date(),
//                updatedAt: Date()
//            )
//        },
//        updateBotSettings: { _, _ in },
//        getMessages: { _ in [] },
//        sendMessage: { _, content in
//            Message(
//                id: UUID().uuidString,
//                chatRoomId: "test-room",
//                sender: .user,
//                content: content,
//                messageType: .text,
//                imageUrl: nil,
//                videoUrl: nil,
//                createdAt: Date()
//            )
//        }
//    )
}

extension DependencyValues {
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// MARK: - Helper Functions
private func createRequest(
    baseURL: String,
    endpoint: String,
    method: String,
    body: [String: Any]? = nil,
    token: String? = nil
) throws -> URLRequest {
    guard let url = URL(string: baseURL + endpoint) else {
        throw APIError.networkError
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if let token = token {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    if let body = body {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }
    
    return request
}
