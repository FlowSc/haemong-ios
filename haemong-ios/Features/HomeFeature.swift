import Foundation
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @Dependency(\.apiClient) var apiClient
    
    @ObservableState
    struct State: Equatable {
        var isNavigatingToChat = false
        var selectedDate = Date()
        var currentMonth = Date()
        var chatRooms: [ChatRoom] = []
        var selectedDateChatRoom: ChatRoom?
        var selectedDateMessages: [Message] = []
        var isLoadingCalendar = false
        var isLoadingRecords = false
        var showingRecordDetail = false
        var errorMessage: String?
        
        var datesWithRecords: Set<String> {
            Set(chatRooms.filter(\.hasRecord).map(\.dateString))
        }
    }
    
    enum Action {
        case todaysDreamButtonTapped
        case navigateToChat
        case chatNavigationCompleted
        case onAppear
        case dateSelected(Date)
        case monthChanged(Date)
        case loadCalendarData
        case loadChatRoomById(String)
        case calendarDataResponse(Result<ChatRoomListResponse, Error>)
        case recordsResponse(Result<ChatRoomResponse, Error>)
        case dismissRecordDetail
        case dismissError
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadCalendarData)
                
            case .todaysDreamButtonTapped:
                state.isNavigatingToChat = true
                return .send(.navigateToChat)
                
            case .navigateToChat:
                return .none
                
            case .chatNavigationCompleted:
                state.isNavigatingToChat = false
                return .none
                
            case let .dateSelected(date):
                state.selectedDate = date
                let dateString = DateFormatter.apiDateFormatter.string(from: date)
                // 해당 날짜의 채팅룸 ID 찾기
                if let chatRoom = state.chatRooms.first(where: { $0.dateString == dateString }) {
                    return .send(.loadChatRoomById(chatRoom.id))
                } else {
                    // 해당 날짜에 채팅룸이 없는 경우
                    return .none
                }
                
            case let .monthChanged(month):
                state.currentMonth = month
                return .send(.loadCalendarData)
                
            case .loadCalendarData:
                state.isLoadingCalendar = true
                return .run { [currentMonth = state.currentMonth] send in
                    do {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM"
                        let monthString = formatter.string(from: currentMonth)
                        let response = try await apiClient.getChatRoomsByMonth(monthString)
                        await send(.calendarDataResponse(.success(response)))
                    } catch {
                        await send(.calendarDataResponse(.failure(error)))
                    }
                }
                
            case let .loadChatRoomById(roomId):
                state.isLoadingRecords = true
                return .run { send in
                    do {
                        let response = try await apiClient.getChatRoomById(roomId)
                        await send(.recordsResponse(.success(response)))
                    } catch {
                        await send(.recordsResponse(.failure(error)))
                    }
                }
                
            case let .calendarDataResponse(.success(response)):
                state.isLoadingCalendar = false
                state.chatRooms = response.chatRooms
                return .none
                
            case let .calendarDataResponse(.failure(error)):
                state.isLoadingCalendar = false
                state.errorMessage = (error as? APIError)?.message ?? "달력 데이터를 불러올 수 없습니다."
                return .none
                
            case let .recordsResponse(.success(response)):
                state.isLoadingRecords = false
                if response.messages.isEmpty {
                    // 메시지가 없는 경우 오류 메시지 표시
                    state.errorMessage = "해당 날짜에 해몽 기록이 없습니다."
                    return .none
                } else {
                    state.selectedDateChatRoom = response.chatRoom
                    state.selectedDateMessages = response.messages
                    state.showingRecordDetail = true
                    return .none
                }
                
            case let .recordsResponse(.failure(error)):
                state.isLoadingRecords = false
                if let apiError = error as? APIError {
                    switch apiError.code {
                    case 404:
                        state.errorMessage = "해당 날짜에 해몽 기록이 없습니다."
                    case 401:
                        state.errorMessage = "로그인이 필요합니다."
                    default:
                        state.errorMessage = apiError.message
                    }
                } else {
                    state.errorMessage = "해몽 기록을 불러올 수 없습니다."
                }
                return .none
                
            case .dismissRecordDetail:
                state.showingRecordDetail = false
                state.selectedDateChatRoom = nil
                state.selectedDateMessages = []
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}

extension DateFormatter {
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}