import SwiftUI
import ComposableArchitecture

struct ChatRoomView: View {
    @Bindable var store: StoreOf<ChatRoomFeature>
    
    var body: some View {
        VStack(spacing: 0) {
            if store.isLoading {
                loadingView
            } else if store.chatRoom != nil {
                chatContentView
            } else {
                errorView
            }
        }
        .navigationTitle(store.chatRoom?.botSettings.botType.displayName ?? "해몽")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                botSelectionButton
            }
        }
        .alert("오류", isPresented: .constant(store.errorMessage != nil)) {
            Button("확인") {
                store.send(.dismissError)
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(isPresented: Binding(
            get: { store.showingBotSelection },
            set: { _ in store.send(.dismissBotSelection) }
        )) {
            BotSelectionView(store: store)
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("채팅방을 불러오는 중...")
            Spacer()
        }
    }
    
    private var errorView: some View {
        ContentUnavailableView(
            "채팅방을 불러올 수 없습니다",
            systemImage: "exclamationmark.triangle",
            description: Text("다시 시도해주세요")
        )
    }
    
    private var botSelectionButton: some View {
        Button(action: {
            store.send(.botSelectionTapped)
        }) {
            Image(systemName: "person.crop.circle")
                .foregroundColor(.blue)
        }
    }
    
    private var chatContentView: some View {
        VStack(spacing: 0) {
            messagesScrollView
            messageInputView
        }
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    if store.isSendingMessage {
                        sendingIndicator
                    }
                    
                    bottomSpacer
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    scrollToBottom(proxy: proxy)
                }
            }
            .onChange(of: store.messages.count) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToBottomWithAnimation(proxy: proxy)
                }
            }
            .onChange(of: store.chatRoom) { _, chatRoom in
                if chatRoom != nil && !store.messages.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            .onChange(of: store.isSendingMessage) { _, isSending in
                if isSending {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottomWithAnimation(proxy: proxy)
                    }
                }
            }
        }
    }
    
    private var sendingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("전송 중...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .id("sending-indicator")
    }
    
    private var bottomSpacer: some View {
        Color.clear
            .frame(height: 20)
            .id("bottom-spacer")
    }
    
    private var messageInputView: some View {
        MessageInputView(
            text: $store.messageInput.sending(\.messageInputChanged),
            onSend: { store.send(.sendMessageTapped) },
            isDisabled: store.isSendingMessage
        )
    }
    
    // MARK: - Helper Methods
    private func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo("bottom-spacer", anchor: .bottom)
    }
    
    private func scrollToBottomWithAnimation(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo("bottom-spacer", anchor: .bottom)
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: .infinity * 0.7, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    if let imageUrl = message.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
                                .overlay(
                                    ProgressView()
                                )
                        }
                        .frame(maxWidth: 250, maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(maxWidth: .infinity * 0.7, alignment: .leading)
                Spacer()
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    let isDisabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("꿈 이야기를 들려주세요...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
                .disabled(isDisabled)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend || isDisabled)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct BotSelectionView: View {
    @Bindable var store: StoreOf<ChatRoomFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(store.availableBotTypes, id: \.self) { botType in
                        Button(action: {
                            store.send(.botTypeSelected(botType))
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: botType.iconName)
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                
                                Text(botType.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(botType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                store.chatRoom?.botSettings.botType == botType 
                                                ? Color.blue 
                                                : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("봇 선택")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        store.send(.dismissBotSelection)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ChatRoomView(
        store: Store(initialState: ChatRoomFeature.State()) {
            ChatRoomFeature()
        }
    )
}