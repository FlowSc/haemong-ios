import SwiftUI
import ComposableArchitecture
import Kingfisher

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
//        .navigationTitle(store.chatRoom?.botSettings.botType.displayName ?? "해몽")
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
//        .sheet(isPresented: Binding(
//            get: { store.showingBotSelection },
//            set: { _ in store.send(.dismissBotSelection) }
//        )) {
//            BotSelectionView(store: store)
//        }
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
                    let _ = print("🔄 MessagesScrollView: Rendering \(store.messages.count) messages")
                    ForEach(Array(store.messages.enumerated()), id: \.element.id) { index, message in
                        VStack(spacing: 8) {
                            MessageBubbleView(message: message)
                            
                            // 가장 최근 봇 메시지 하단에 이미지 생성 버튼 표시 (타이핑 완료 후, 이미지가 없는 메시지만)
                            if index == store.messages.count - 1 && 
                               message.sender == .bot && 
                               message.imageUrl == nil &&
                               store.isUserPremium &&
                               !store.isSendingMessage &&
                                (!message.isTyping || message.isTypingComplete) && message.interpretation {
                                imageGenerationButton
                            }
                        }
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
            .defaultScrollAnchor(.bottom)
            .onAppear {
                scrollToBottomAsync(proxy: proxy, delay: 0.3)
            }
            .onChange(of: store.messages.count) { _, _ in
                // 타이핑 중이 아닐 때만 스크롤 (새 메시지 추가 시)
                if !store.messages.contains(where: { $0.isTyping && !$0.isTypingComplete }) {
                    scrollToBottomAsync(proxy: proxy, delay: 0.2, animated: true)
                }
            }
            .onChange(of: store.chatRoom) { _, chatRoom in
                if chatRoom != nil && !store.messages.isEmpty {
                    scrollToBottomAsync(proxy: proxy, delay: 0.4)
                }
            }
            .onChange(of: store.isSendingMessage) { _, isSending in
                if isSending {
                    scrollToBottomAsync(proxy: proxy, delay: 0.1, animated: true)
                }
            }
            .onChange(of: store.isGeneratingImage) { _, isGenerating in
                if !isGenerating {
                    // 이미지 생성 완료 후 스크롤
                    scrollToBottomAsync(proxy: proxy, delay: 0.3, animated: true)
                }
            }
            .onChange(of: store.messages.map { $0.isTypingComplete }) { oldValues, newValues in
                // 타이핑이 방금 완료된 경우에만 스크롤 (false -> true 변화)
                let wasTypingComplete = oldValues
                let isTypingComplete = newValues
                
                for (index, (wasComplete, isComplete)) in zip(wasTypingComplete, isTypingComplete).enumerated() {
                    if !wasComplete && isComplete && store.messages[index].sender == .bot {
                        // 봇 메시지의 타이핑이 방금 완료됨
                        scrollToBottomAsync(proxy: proxy, delay: 0.2, animated: true)
                        break
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
            onSend: { 
                store.send(.sendMessageTapped)
            },
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
    
    private func scrollToBottomAsync(proxy: ScrollViewProxy, delay: TimeInterval, animated: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // 여러 번 시도하여 확실하게 스크롤
            if animated {
                withAnimation(.easeOut(duration: 0.4)) {
                    proxy.scrollTo("bottom-spacer", anchor: .bottom)
                }
                // 애니메이션 후 한 번 더 확인
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    proxy.scrollTo("bottom-spacer", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("bottom-spacer", anchor: .bottom)
                // 즉시 한 번 더 확인
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo("bottom-spacer", anchor: .bottom)
                }
            }
        }
    }
    
    private var imageGenerationButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                store.send(.generateImageTapped)
            }) {
                HStack(spacing: 8) {
                    if store.isGeneratingImage {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 14))
                    }
                    
                    Text(store.isGeneratingImage ? "이미지 생성 중..." : "꿈 이미지 생성")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(store.isGeneratingImage)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal)
    }
    
}

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        let _ = print("📩 MessageBubbleView: Rendering message \(message.id), sender: \(message.sender), hasImage: \(message.imageUrl != nil)")
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
                    // 봇 메시지 버블
                    HStack {
                        Text(displayedText)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .animation(.none, value: displayedText) // 텍스트 변화 애니메이션 제거
                            .id(message.id + "_text") // 고유 ID로 불필요한 리렌더링 방지
                        
                        // 타이핑 인디케이터
                        if message.isTyping && !message.isTypingComplete {
                            typingIndicator
                        }
                    }
                    
                    if let imageUrl = message.imageUrl, !imageUrl.isEmpty {
                        let _ = print("🖼️ MessageBubbleView: Rendering image for message \(message.id)")
                        let _ = print("🖼️ Image URL: \(imageUrl)")
                        
                        // 이미지 컨테이너 - 고정 크기로 레이아웃 안정성 확보
                        VStack(alignment: .leading, spacing: 0) {
                            // Kingfisher를 사용한 이미지 로딩
                            KFImage(URL(string: imageUrl))
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            VStack(spacing: 8) {
                                                ProgressView()
                                                Text("이미지 로딩 중...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        )
                                }
                                .retry(maxCount: 3)
                                .onFailure { error in
                                    print("🚫 Kingfisher image loading failed: \(error)")
                                }
                                .onSuccess { result in
                                    print("✅ Kingfisher image loaded successfully: \(result.source.url?.absoluteString ?? "")")
                                }
                                .fade(duration: 0.25)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .onTapGesture {
                                    // 이미지를 탭하면 브라우저에서 열기 (디버깅용)
                                    if let url = URL(string: imageUrl), UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                        }
                        .frame(width: 250, height: 250) // 고정 크기
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(maxWidth: .infinity * 0.7, alignment: .leading)
                Spacer()
            }
        }
    }
    
    private var displayedText: String {
        if message.sender == .bot && message.isTyping {
            return message.displayedContent
        } else {
            return message.content
        }
    }
    
    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .scaleEffect(typingScale)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: typingScale
                    )
            }
        }
        .padding(.horizontal, 8)
        .onAppear {
            startTypingAnimation()
        }
    }
    
    @State private var typingScale: CGFloat = 0.5
    
    private func startTypingAnimation() {
        typingScale = 1.0
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    let isDisabled: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("꿈 이야기를 들려주세요...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
                .disabled(isDisabled)
                .focused($isTextFieldFocused)
                .onSubmit {
                    if canSend && !isDisabled {
                        onSend()
                    }
                }
            
            Button(action: {
                onSend()
                isTextFieldFocused = false
            }) {
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

//struct BotSelectionView: View {
//    @Bindable var store: StoreOf<ChatRoomFeature>
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                LazyVGrid(columns: [
//                    GridItem(.flexible()),
//                    GridItem(.flexible())
//                ], spacing: 16) {
//                    ForEach(store.availableBotTypes, id: \.self) { botType in
//                        Button(action: {
//                            store.send(.botTypeSelected(botType))
//                        }) {
//                            VStack(spacing: 12) {
//                                Image(systemName: botType.iconName)
//                                    .font(.system(size: 40))
//                                    .foregroundColor(.blue)
//                                
//                                Text(botType.displayName)
//                                    .font(.headline)
//                                    .foregroundColor(.primary)
//                                
//                                Text(botType.description)
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                                    .multilineTextAlignment(.center)
//                                    .lineLimit(2)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(20)
//                            .background(
//                                RoundedRectangle(cornerRadius: 16)
//                                    .fill(Color.gray.opacity(0.1))
//                                    .overlay(
//                                        RoundedRectangle(cornerRadius: 16)
//                                            .stroke(
//                                                store.chatRoom?.botSettings.botType == botType 
//                                                ? Color.blue 
//                                                : Color.clear,
//                                                lineWidth: 2
//                                            )
//                                    )
//                            )
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("봇 선택")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("완료") {
//                        store.send(.dismissBotSelection)
//                    }
//                }
//            }
//        }
//        .presentationDetents([.medium, .large])
//    }
//}

#Preview {
    ChatRoomView(
        store: Store(initialState: ChatRoomFeature.State()) {
            ChatRoomFeature()
        }
    )
}
