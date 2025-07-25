import Foundation

// MARK: - User Models
struct User: Codable, Equatable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let profileImage: String?
    let provider: AuthProvider
    let isPremium: Bool?
    let createdAt: String
    let updatedAt: String
}

enum AuthProvider: String, Codable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}

// MARK: - Chat Models
struct ChatRoom: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let date: String
    let botSettings: BotSettings
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
}

struct BotSettings: Codable, Equatable {
    let gender: String
    let style: String
    
    var botType: BotType {
        switch (style, gender) {
        case ("eastern", "male"): return .easternMale
        case ("eastern", "female"): return .easternFemale
        case ("western", "male"): return .westernMale
        case ("western", "female"): return .westernFemale
        default: return .easternFemale
        }
    }
}

// Legacy support
struct BotPersonality: Codable, Equatable {
    let type: BotType
    let name: String
    let description: String
}

enum BotType: String, Codable, CaseIterable, Equatable {
    case easternMale = "eastern_male"
    case easternFemale = "eastern_female"
    case westernMale = "western_male"
    case westernFemale = "western_female"
    
    var displayName: String {
        switch self {
        case .easternMale: return "동양 남성"
        case .easternFemale: return "동양 여성"
        case .westernMale: return "서양 남성"
        case .westernFemale: return "서양 여성"
        }
    }
    
    var description: String {
        switch self {
        case .easternMale: return "따뜻하고 지혜로운 동양의 남성 해몽사"
        case .easternFemale: return "섬세하고 직관적인 동양의 여성 해몽사"
        case .westernMale: return "논리적이고 체계적인 서양의 남성 해몽사"
        case .westernFemale: return "감성적이고 창의적인 서양의 여성 해몽사"
        }
    }
    
    var iconName: String {
        switch self {
        case .easternMale: return "person.fill"
        case .easternFemale: return "person.fill"
        case .westernMale: return "person.crop.circle"
        case .westernFemale: return "person.crop.circle"
        }
    }
    
    var gender: String {
        switch self {
        case .easternMale, .westernMale:
            return "male"
        case .easternFemale, .westernFemale:
            return "female"
        }
    }
    
    var style: String {
        switch self {
        case .easternMale, .easternFemale:
            return "eastern"
        case .westernMale, .westernFemale:
            return "western"
        }
    }
}

struct Message: Codable, Equatable, Identifiable {
    let id: String
    let chatRoomId: String
    let type: MessageSender
    let content: String
    let createdAt: String
    
    // Legacy support
    var sender: MessageSender { type }
    var messageType: MessageType { .text }
    var imageUrl: String? { nil }
    var videoUrl: String? { nil }
    
    // 타이핑 애니메이션 관련 (로컬 상태)
    var isTyping: Bool = false
    var displayedContent: String = ""
    var isTypingComplete: Bool = false
    
    // Codable에서 제외할 프로퍼티들
    private enum CodingKeys: String, CodingKey {
        case id, chatRoomId, type, content, createdAt
    }
}

enum MessageSender: String, Codable {
    case user = "user"
    case bot = "bot"
}

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case video = "video"
}

// MARK: - Dream Record Models (using ChatRoom structure)
struct ChatRoomListResponse: Codable, Equatable {
    let chatRooms: [ChatRoom]
}

extension ChatRoom {
    var dateString: String {
        return date // Already in "YYYY-MM-DD" format
    }
    
    var hasRecord: Bool {
        return isActive
    }
}

// MARK: - API Response Models
struct AuthResponse: Codable, Equatable {
    let user: User
    let accessToken: String
}

struct ChatRoomResponse: Codable, Equatable {
    let chatRoom: ChatRoom
    let messages: [Message]
    let totalMessages: Int
}

struct SendMessageResponse: Codable, Equatable {
    let userMessage: Message
    let botMessage: Message
}

struct BotSettingsResponse: Codable, Equatable {
    let botSettings: BotSettings
    let message: String
}

struct ImageGenerationResponse: Codable, Equatable {
    let success: Bool
    let imageUrl: String?
    let message: String
    let isPremium: Bool
}

// Remove old DreamRecord response models since we're using ChatRoom structure

struct APIError: Error, Equatable {
    let message: String
    let code: Int?
    
    static let networkError = APIError(message: "네트워크 오류가 발생했습니다.", code: nil)
    static let unauthorized = APIError(message: "인증이 필요합니다.", code: 401)
    static let serverError = APIError(message: "서버 오류가 발생했습니다.", code: 500)
}
