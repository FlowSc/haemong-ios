import SwiftUI
import ComposableArchitecture

struct BotSettingsView: View {
    @Bindable var store: StoreOf<BotSettingsFeature>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if store.isLoading {
                    Spacer()
                    ProgressView("설정을 불러오는 중...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 현재 봇 정보
                            if let chatRoom = store.currentChatRoom {
                                CurrentBotInfoView(botType: chatRoom.botSettings.botType)
                            }
                            
                            // 봇 타입 선택
                            BotTypeSelectionView(
                                selectedBotType: store.selectedBotType,
                                onSelection: { botType in
                                    store.send(.botTypeSelected(botType))
                                }
                            )
                            
                            // 저장 버튼
                            Button(action: {
                                store.send(.saveSettings)
                            }) {
                                HStack {
                                    if store.isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text(store.isSaving ? "저장 중..." : "설정 저장")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(25)
                            }
                            .disabled(store.isSaving)
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("봇 설정")
            .navigationBarTitleDisplayMode(.large)
            .alert("오류", isPresented: .constant(store.errorMessage != nil)) {
                Button("확인") {
                    store.send(.dismissError)
                }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

struct CurrentBotInfoView: View {
    let botType: BotType
    
    var body: some View {
        VStack(spacing: 12) {
            Text("현재 해몽사")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Image(systemName: botType.iconName)
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text(botType.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(botType.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct BotTypeSelectionView: View {
    let selectedBotType: BotType
    let onSelection: (BotType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("해몽사 선택")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(BotType.allCases, id: \.self) { botType in
                    BotTypeCard(
                        botType: botType,
                        isSelected: selectedBotType == botType,
                        onTap: { onSelection(botType) }
                    )
                }
            }
        }
    }
}

struct BotTypeCard: View {
    let botType: BotType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: botType.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)
                
                VStack(spacing: 4) {
                    Text(botType.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(botType.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    BotSettingsView(
        store: Store(initialState: BotSettingsFeature.State()) {
            BotSettingsFeature()
        }
    )
}