import SwiftUI

struct ChatRecordDetailView: View {
    let chatRoom: ChatRoom
    let messages: [Message]
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            if messages.isEmpty {
                ContentUnavailableView(
                    "해몽 기록이 없습니다",
                    systemImage: "moon.stars",
                    description: Text("이 날에는 해몽 기록이 없어요")
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 채팅룸 정보 헤더
                        ChatRoomInfoCard(chatRoom: chatRoom)
                        
                        // 메시지들
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatMessageCard(message: message)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(dateString)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("닫기") {
                    dismiss()
                }
            }
        }
    }
}

struct ChatRoomInfoCard: View {
    let chatRoom: ChatRoom
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
//                Image(systemName: chatRoom.botSettings.botType.iconName)
//                    .foregroundColor(.blue)
//                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chatRoom.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
//                    Text(chatRoom.botSettings.botType.displayName)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ChatMessageCard: View {
    let message: Message
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: message.createdAt) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        return ""
    }
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    if !formattedTime.isEmpty {
                        Text(formattedTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity * 0.7, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    if !formattedTime.isEmpty {
                        Text(formattedTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity * 0.7, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ChatRecordDetailView(
        chatRoom: ChatRoom(
            id: "1",
            userId: "user1", 
            title: "2025-07-25 꿈 해몽",
            date: "2025-07-25",
//            botSettings: BotSettings(gender: "female", style: "eastern"),
            isActive: true,
            createdAt: "2025-07-25T10:30:00.000Z",
            updatedAt: "2025-07-25T10:30:00.000Z"
        ),
        messages: [
            Message(
                id: "1",
                chatRoomId: "1",
                type: .user,
                content: "높은 산을 오르는 꿈을 꾸었습니다.",
                createdAt: "2025-07-25T10:30:00.000Z",
                imageUrl: nil, interpretation: false
            ),
            Message(
                id: "2", 
                chatRoomId: "1",
                type: .bot,
                content: "산을 오르는 꿈은 목표 달성과 성공을 의미합니다.",
                createdAt: "2025-07-25T10:31:00.000Z",
                imageUrl: nil, interpretation: false
            )
        ],
        selectedDate: Date()
    )
}
