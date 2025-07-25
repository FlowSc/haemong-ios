import Foundation
import ComposableArchitecture

@Reducer
struct ChatRoomFeature {
    @ObservableState
    struct State: Equatable {
        var chatRoom: ChatRoom?
        var messages: [Message] = []
        var messageInput: String = ""
        var isLoading = false
        var isSendingMessage = false
        var isGeneratingImage = false
        var errorMessage: String?
        var showingBotSelection = false
        var availableBotTypes: [BotType] = BotType.allCases
        var generatedImageUrl: String?
        
        var isUserPremium: Bool {
            // AuthFeature에서 사용자 정보 확인 필요, 임시로 true
            return true
        }
    }
    
    enum Action {
        case onAppear
        case loadChatRoom
        case loadMessages
        case chatRoomResponse(Result<ChatRoomResponse, Error>)
        case messagesResponse(Result<[Message], Error>)
        case messageInputChanged(String)
        case sendMessageTapped
        case sendMessageResponse(Result<SendMessageResponse, Error>)
        case dismissError
        case botSelectionTapped
        case botTypeSelected(BotType)
        case botUpdateResponse(Result<BotSettingsResponse, Error>)
        case dismissBotSelection
        case generateImageTapped
        case imageGenerationResponse(Result<ImageGenerationResponse, Error>)
        case startTypingAnimation(String) // messageId
        case typingAnimationTick(String)  // messageId
        case completeTypingAnimation(String) // messageId
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadChatRoom)
                
            case .loadChatRoom:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        print("🔥 ChatRoomFeature: Calling getTodaysChatRoom...")
                        let response = try await apiClient.getTodaysChatRoom()
                        print("🔥 ChatRoomFeature: getTodaysChatRoom success")
                        await send(.chatRoomResponse(.success(response)))
                    } catch {
                        print("🔥 ChatRoomFeature: getTodaysChatRoom error: \(error)")
                        await send(.chatRoomResponse(.failure(error)))
                    }
                }
                
            case let .chatRoomResponse(.success(response)):
                state.isLoading = false
                state.chatRoom = response.chatRoom
                state.messages = response.messages.sorted { $0.createdAt < $1.createdAt }
                return .none
                
            case let .chatRoomResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .loadMessages:
                guard let chatRoom = state.chatRoom else { return .none }
                
                return .run { send in
                    do {
                        let messages = try await apiClient.getMessages(chatRoom.id)
                        await send(.messagesResponse(.success(messages)))
                    } catch {
                        await send(.messagesResponse(.failure(error)))
                    }
                }
                
            case let .messagesResponse(.success(messages)):
                state.messages = messages.sorted { $0.createdAt < $1.createdAt }
                return .none
                
            case let .messagesResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .messageInputChanged(input):
                state.messageInput = input
                return .none
                
            case .sendMessageTapped:
                guard let chatRoom = state.chatRoom,
                      !state.messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .none
                }
                
                let messageContent = state.messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
                state.messageInput = ""
                state.isSendingMessage = true
                
                // 사용자 메시지를 즉시 화면에 추가 (임시 ID와 현재 시간 사용)
                let tempUserMessage = Message(
                    id: "temp-\(UUID().uuidString)", // 임시 ID
                    chatRoomId: chatRoom.id,
                    type: .user,
                    content: messageContent,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
                state.messages.append(tempUserMessage)
                
                return .run { [chatRoomId = chatRoom.id] send in
                    do {
                        let response = try await apiClient.sendMessage(chatRoomId, messageContent)
                        await send(.sendMessageResponse(.success(response)))
                    } catch {
                        await send(.sendMessageResponse(.failure(error)))
                    }
                }
                
            case let .sendMessageResponse(.success(response)):
                state.isSendingMessage = false
                
                // 임시 사용자 메시지를 서버에서 온 정확한 메시지로 교체
                if let tempIndex = state.messages.firstIndex(where: { $0.id.hasPrefix("temp-") && $0.type == .user }) {
                    state.messages[tempIndex] = response.userMessage
                }
                
                // 봇 메시지를 타이핑 상태로 추가
                var botMessage = response.botMessage
                botMessage.isTyping = true
                botMessage.displayedContent = ""
                botMessage.isTypingComplete = false
                state.messages.append(botMessage)
                
                // 메시지를 시간순으로 정렬
                state.messages.sort { $0.createdAt < $1.createdAt }
                
                // 타이핑 애니메이션 시작
                return .send(.startTypingAnimation(response.botMessage.id))
                
            case let .sendMessageResponse(.failure(error)):
                state.isSendingMessage = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .botSelectionTapped:
                state.showingBotSelection = true
                return .none
                
            case let .botTypeSelected(botType):
                state.showingBotSelection = false
                guard let chatRoomId = state.chatRoom?.id else {
                    state.errorMessage = "채팅방 정보를 찾을 수 없습니다."
                    return .none
                }
                
                return .run { send in
                    do {
                        let response = try await apiClient.updateBotSettings(chatRoomId, botType)
                        await send(.botUpdateResponse(.success(BotSettingsResponse(botSettings: BotSettings.init(gender: botType.gender, style: botType.style), message: ""))))
                    } catch {
                        await send(.botUpdateResponse(.failure(error)))
                    }
                }
                
            case let .botUpdateResponse(.success(response)):
                // 봇 설정이 성공적으로 변경되면 채팅방을 다시 로드
                return .send(.loadChatRoom)
                
            case let .botUpdateResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none
                
            case .dismissBotSelection:
                state.showingBotSelection = false
                return .none
                
            case .generateImageTapped:
                guard let chatRoomId = state.chatRoom?.id else {
                    state.errorMessage = "채팅방 정보를 찾을 수 없습니다."
                    return .none
                }
                
                state.isGeneratingImage = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let response = try await apiClient.generateImage(chatRoomId)
                        await send(.imageGenerationResponse(.success(response)))
                    } catch {
                        await send(.imageGenerationResponse(.failure(error)))
                    }
                }
                
            case let .imageGenerationResponse(.success(response)):
                state.isGeneratingImage = false
                if response.success, let imageUrl = response.imageUrl, !imageUrl.isEmpty {
                    state.generatedImageUrl = imageUrl
                } else if !response.success {
                    state.errorMessage = response.message
                }
                return .none
                
            case let .imageGenerationResponse(.failure(error)):
                state.isGeneratingImage = false
                if let apiError = error as? APIError {
                    switch apiError.code {
                    case 403:
                        state.errorMessage = "프리미엄 사용자만 이용 가능합니다."
                    default:
                        state.errorMessage = apiError.message
                    }
                } else {
                    state.errorMessage = "이미지 생성에 실패했습니다."
                }
                return .none
                
            case let .startTypingAnimation(messageId):
                guard let messageIndex = state.messages.firstIndex(where: { $0.id == messageId }) else {
                    return .none
                }
                
                state.messages[messageIndex].isTyping = true
                state.messages[messageIndex].displayedContent = ""
                
                return .run { send in
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.5초 대기
                    await send(.typingAnimationTick(messageId))
                }
                
            case let .typingAnimationTick(messageId):
                guard let messageIndex = state.messages.firstIndex(where: { $0.id == messageId }) else {
                    return .none
                }
                
                let message = state.messages[messageIndex]
                let fullContent = message.content
                let currentDisplayed = message.displayedContent
                
                if currentDisplayed.count >= fullContent.count {
                    // 타이핑 완료
                    return .send(.completeTypingAnimation(messageId))
                }
                
                // 다음 문자 추가
                let nextIndex = fullContent.index(fullContent.startIndex, offsetBy: currentDisplayed.count + 1)
                state.messages[messageIndex].displayedContent = String(fullContent[..<nextIndex])
                
                return .run { send in
                    // 한글은 느리게, 영어/특수문자는 빠르게
                    let nextChar = fullContent[fullContent.index(fullContent.startIndex, offsetBy: currentDisplayed.count)]
                    let delay: UInt64 = nextChar.isKorean ? 100_000_000 : 50_000_000 // 0.1초 or 0.05초
                    
                    try await Task.sleep(nanoseconds: delay)
                    await send(.typingAnimationTick(messageId))
                }
                
            case let .completeTypingAnimation(messageId):
                guard let messageIndex = state.messages.firstIndex(where: { $0.id == messageId }) else {
                    return .none
                }
                
                state.messages[messageIndex].isTyping = false
                state.messages[messageIndex].isTypingComplete = true
                state.messages[messageIndex].displayedContent = state.messages[messageIndex].content
                
                return .none
            }
        }
    }
}

// Character 확장으로 한글 판별
extension Character {
    var isKorean: Bool {
        guard let unicodeScalar = self.unicodeScalars.first else { return false }
        let value = unicodeScalar.value
        return (0xAC00...0xD7AF).contains(value) || // 한글 완성형
               (0x1100...0x11FF).contains(value) || // 한글 자음
               (0x3130...0x318F).contains(value) || // 한글 호환 자모
               (0xA960...0xA97F).contains(value)    // 한글 확장 자모
    }
}
