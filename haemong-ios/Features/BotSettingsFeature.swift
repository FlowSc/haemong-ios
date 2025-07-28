import Foundation
import ComposableArchitecture

@Reducer
struct BotSettingsFeature {
    @ObservableState
    struct State: Equatable {
        var currentChatRoom: ChatRoom?
        var selectedBotType: BotType = .easternFemale
        var isLoading = false
        var isSaving = false
        var errorMessage: String?
    }
    
    enum Action {
        case onAppear
        case loadCurrentChatRoom
        case chatRoomResponse(Result<ChatRoomResponse, Error>)
        case botTypeSelected(BotType)
        case saveSettings
        case saveResponse(Result<Void, Error>)
        case dismissError
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadCurrentChatRoom)
                
            case .loadCurrentChatRoom:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let response = try await apiClient.getTodaysChatRoom()
                        await send(.chatRoomResponse(.success(response)))
                    } catch {
                        await send(.chatRoomResponse(.failure(error)))
                    }
                }
                
            case let .chatRoomResponse(.success(response)):
                state.isLoading = false
                state.currentChatRoom = response.chatRoom
//                state.selectedBotType = response.chatRoom.botSettings.botType
                return .none
                
            case let .chatRoomResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .botTypeSelected(botType):
                state.selectedBotType = botType
                return .none
                
            case .saveSettings:
                guard let chatRoom = state.currentChatRoom else { return .none }
                
                state.isSaving = true
                state.errorMessage = nil
                
                return .run { [selectedBotType = state.selectedBotType] send in
                    do {
                        try await apiClient.updateBotSettings(chatRoom.id, selectedBotType)
                        await send(.saveResponse(.success(())))
                    } catch {
                        await send(.saveResponse(.failure(error)))
                    }
                }
                
            case .saveResponse(.success):
                state.isSaving = false
                // 봇 설정이 성공적으로 저장되었음을 표시
                return .none
                
            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}
