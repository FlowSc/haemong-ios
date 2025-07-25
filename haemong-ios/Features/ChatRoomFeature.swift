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
        var errorMessage: String?
        var showingBotSelection = false
        var availableBotTypes: [BotType] = BotType.allCases
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
                
                // 봇 메시지만 추가
                state.messages.append(response.botMessage)
                
                // 메시지를 시간순으로 정렬
                state.messages.sort { $0.createdAt < $1.createdAt }
                return .none
                
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
            }
        }
    }
}
