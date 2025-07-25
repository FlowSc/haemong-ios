# 해몽 iOS 앱 🌙

AI를 통한 개인화된 꿈 해석 서비스를 제공하는 iOS 애플리케이션입니다.

## 📱 주요 기능

### 🤖 AI 꿈 해석
- **4가지 봇 페르소나**: 동양/서양 × 남성/여성 조합으로 개성있는 해몽 제공
- **대화형 인터페이스**: 채팅 형태로 자연스러운 꿈 해석 경험
- **실시간 봇 변경**: 언제든 원하는 해몽사 스타일로 변경 가능

### 📅 꿈 기록 관리
- **달력 뷰**: 해몽 기록이 있는 날짜를 한눈에 확인
- **상세 기록**: 과거 해몽 대화 전체를 다시 볼 수 있음
- **일일 채팅방**: 날짜별로 자동 생성되는 해몽 채팅방

### 🔐 안전한 인증
- **다중 로그인**: 이메일/비밀번호, Google, Apple Sign-In 지원
- **자동 로그인**: 토큰 기반 자동 인증으로 편리한 접근
- **보안**: Keychain을 통한 안전한 토큰 저장

## 🏗️ 기술 스택

### 아키텍처
- **The Composable Architecture (TCA)**: 일관된 상태 관리와 비즈니스 로직
- **SwiftUI**: 선언적 UI 프레임워킹
- **Combine**: 반응형 프로그래밍

### 주요 라이브러리
```swift
// Point-Free 생태계
- swift-composable-architecture: 1.20.2
- swift-dependencies: 1.9.2
- swift-navigation: 2.3.2

// Apple 프레임워크
- SwiftUI: 네이티브 UI
- Security: Keychain 접근
- AuthenticationServices: Apple Sign-In
```

## 🎨 봇 페르소나

| 봇 타입 | 특징 | 아이콘 |
|---------|------|--------|
| **동양 남성** | 따뜻하고 지혜로운 동양의 남성 해몽사 | 👨 |
| **동양 여성** | 섬세하고 직관적인 동양의 여성 해몽사 | 👩 |
| **서양 남성** | 논리적이고 체계적인 서양의 남성 해몽사 | 👨‍💼 |
| **서양 여성** | 감성적이고 창의적인 서양의 여성 해몽사 | 👩‍💼 |

## 📁 프로젝트 구조

```
haemong-ios/
├── 📱 haemong_iosApp.swift           # 앱 진입점
├── 🎯 Features/                      # TCA Feature 모듈들  
│   ├── AppFeature.swift              # 최상위 앱 상태 관리
│   ├── AuthFeature.swift             # 인증 및 토큰 관리
│   ├── LoginFeature.swift            # 로그인/회원가입
│   ├── HomeFeature.swift             # 홈화면 (달력 포함)
│   ├── ChatRoomFeature.swift         # 채팅방 로직
│   └── BotSettingsFeature.swift      # 봇 설정
├── 🎨 Views/                         # SwiftUI 뷰 컴포넌트
│   ├── AppView.swift                 # 메인 앱 뷰
│   ├── LoginView.swift               # 로그인 UI
│   ├── HomeView.swift                # 홈 + 달력 UI
│   ├── ChatRoomView.swift            # 채팅방 UI
│   ├── BotSettingsView.swift         # 봇 설정 UI
│   └── DreamRecordDetailView.swift   # 해몽 기록 상세
├── 📊 Models/                        # 데이터 모델
│   └── Models.swift                  # 모든 데이터 타입 정의
└── 🌐 Services/                      # 외부 서비스
    └── APIClient.swift               # REST API 클라이언트
```

## 🚀 시작하기

### 요구사항
- **Xcode**: 15.0 이상
- **iOS**: 17.0 이상
- **Swift**: 5.9 이상

### 설치 및 실행
1. 레포지토리 클론
```bash
git clone https://github.com/FlowSc/haemong-ios.git
cd haemong-ios
```

2. Xcode에서 프로젝트 열기
```bash
open haemong-ios.xcodeproj
```

3. 시뮬레이터에서 실행
- iPhone 15 시뮬레이터 권장
- Cmd+R로 빌드 및 실행

### API 서버 설정
현재 `http://localhost:3000`으로 설정되어 있습니다.
```swift
// APIClient.swift:32
let baseURL = "http://localhost:3000"
```

## 📱 주요 화면

### 1. 홈 화면
- 📅 **월별 해몽 달력**: 해몽 기록이 있는 날짜 표시
- 🌟 **오늘의 해몽**: 새로운 해몽 채팅 시작
- 📚 **꿈 일기** (준비중)
- 💡 **해석 가이드** (준비중)

### 2. 채팅방
- 💬 **실시간 대화**: 사용자와 AI 봇의 자연스러운 대화
- 🎭 **봇 변경**: 상단 버튼으로 해몽사 스타일 변경
- 📜 **무한 스크롤**: 긴 대화도 부드럽게 스크롤
- ⚡ **자동 스크롤**: 새 메시지 시 하단으로 자동 이동

### 3. 해몽 기록
- 📖 **대화 히스토리**: 과거 해몽 대화 전체 보기
- 🕐 **시간 표시**: 각 메시지의 정확한 시간
- 🤖 **봇 정보**: 해당 해몽을 담당한 봇 표시

## 🔧 개발 가이드

### TCA 패턴 활용
```swift
@Reducer
struct SomeFeature {
    @ObservableState
    struct State: Equatable {
        // 상태 정의
    }
    
    enum Action {
        // 가능한 모든 액션
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // 비즈니스 로직
        }
    }
}
```

### API 클라이언트 확장
```swift
// APIClient.swift에 새로운 엔드포인트 추가
var newEndpoint: @Sendable (Parameters) async throws -> Response
```

### 새로운 뷰 추가
1. `Views/` 폴더에 SwiftUI 뷰 생성
2. `Features/` 폴더에 TCA Feature 생성  
3. `AppFeature`에서 네비게이션 연결

## 🧪 테스트

### 빌드 테스트
```bash
# 프로젝트 빌드
xcodebuild -project haemong-ios.xcodeproj -scheme haemong-ios -sdk iphonesimulator build

# 테스트 실행  
xcodebuild -project haemong-ios.xcodeproj -scheme haemong-ios test
```

### 수동 테스트 시나리오
1. ✅ **로그인 플로우**: 이메일 로그인 → 자동 로그인
2. ✅ **해몽 채팅**: 봇과 대화 → 봇 변경 → 메시지 전송
3. ✅ **달력 조회**: 홈 달력 → 날짜 클릭 → 기록 상세보기
4. ✅ **네비게이션**: 탭 전환 → 전체화면 모달 → 뒤로가기

## 🚧 현재 상태 및 개선점

### ✅ 완성된 기능
- [x] 이메일 로그인/회원가입
- [x] 자동 로그인 (토큰 기반)
- [x] AI 봇과의 해몽 채팅
- [x] 4가지 봇 페르소나 전환
- [x] 월별 해몽 달력
- [x] 해몽 기록 상세 조회
- [x] 탭 기반 네비게이션
- [x] 전체화면 채팅 모달

### 🔄 개선이 필요한 부분
- [ ] **OAuth 연동**: Google/Apple Sign-In SDK 실제 구현
- [ ] **환경 설정**: dev/prod 환경 분리
- [ ] **테스트 코드**: Unit/Integration 테스트 추가
- [ ] **에러 처리**: 사용자 친화적 에러 메시지
- [ ] **이미지 캐싱**: AsyncImage 성능 최적화
- [ ] **오프라인 지원**: 네트워크 연결 상태 처리

### 🎯 로드맵
1. **Phase 1**: OAuth 연동 및 환경 설정 완성
2. **Phase 2**: 커뮤니티 기능 구현
3. **Phase 3**: 꿈 일기 및 해석 가이드 추가
4. **Phase 4**: 푸시 알림 및 백그라운드 처리

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이센스

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 개발팀

- **개발자**: [@FlowSc](https://github.com/FlowSc)
- **AI 어시스턴트**: Claude Code

---

**해몽** - AI와 함께하는 꿈 해석 여행 🌙✨