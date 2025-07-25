import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // 헤더
                    VStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("해몽")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("당신의 꿈을 해석해드립니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 메인 버튼들
                    VStack(spacing: 20) {
                        // 오늘의 해몽 버튼
                        NavigationLink(destination: ChatRoomView(
                            store: Store(initialState: ChatRoomFeature.State()) {
                                ChatRoomFeature()
                            }
                        )) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "message.circle.fill")
                                            .font(.title2)
                                        Text("오늘의 해몽")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("오늘 꾼 꿈을 AI가 해석해드려요")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 꿈 일기 (준비중)
                        Button(action: {}) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "book.circle.fill")
                                            .font(.title2)
                                        Text("꿈 일기")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("나의 꿈과 해몽 기록을 확인해보세요")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("준비중")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .disabled(true)
                        .buttonStyle(PlainButtonStyle())
                        
                        // 꿈 해석 가이드 (준비중)
                        Button(action: {}) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "lightbulb.circle.fill")
                                            .font(.title2)
                                        Text("꿈 해석 가이드")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("꿈의 상징과 의미를 알아보세요")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("준비중")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .disabled(true)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("홈")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}