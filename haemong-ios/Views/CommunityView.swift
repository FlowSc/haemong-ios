import SwiftUI

struct CommunityView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue.opacity(0.6))
                
                VStack(spacing: 12) {
                    Text("커뮤니티")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("다른 사용자들과 꿈 이야기를 나누는\n커뮤니티 기능이 준비 중입니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                Spacer()
            }
            .navigationTitle("커뮤니티")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    CommunityView()
}