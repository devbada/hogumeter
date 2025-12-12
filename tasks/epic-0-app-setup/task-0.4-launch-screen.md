# Task 0.4: 런치 스크린 및 로딩 애니메이션

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-0.4 |
| Epic | Epic 0: 앱 초기 설정 |
| 우선순위 | P1 (Should) |
| 예상 시간 | 2시간 |
| 상태 | ✅ 완료 |
| 담당 | Claude CLI |
| 생성일 | 2025-12-11 |
| 완료일 | 2025-12-11 |

---

## 🎯 목표

앱 시작 시 재미있고 인상적인 첫인상을 주는 런치 스크린과 로딩 애니메이션을 구현합니다.

---

## 🎨 디자인 컨셉

### 1단계: Launch Screen (정적, iOS 시스템)
- 앱 아이콘 표시
- 앱 이름 "호구미터"
- 그라데이션 배경 (오렌지 → 레드)
- 간단하고 깔끔한 디자인

### 2단계: Loading Animation (동적, SwiftUI)
앱 로드가 완료될 때까지 보여지는 재미있는 애니메이션:

**Option 1: 말이 달리는 애니메이션 (추천)**
```
🐴 → 🐎 → 🏇 → 💨
말이 미터기를 들고 화면을 가로질러 달립니다
- 좌에서 우로 이동
- 속도가 점점 빨라짐
- 미터기 숫자가 올라감
- 마지막에 "준비 완료!" 메시지
```

**Option 2: 미터기 카운트업 애니메이션**
```
택시 미터기가 0원에서 시작하여
빠르게 숫자가 올라가다가
"무료!" 또는 "출발!" 로 변경
```

**Option 3: 말 점프 애니메이션**
```
말 캐릭터가 위아래로 통통 뛰면서
"로딩중..." → "거의 다 됐어요!" → "출발!"
```

---

## 📝 상세 요구사항

### 1. Launch Screen (LaunchScreen.storyboard 또는 SwiftUI)

#### 방법 A: Storyboard (전통적)
```swift
// LaunchScreen.storyboard
- ImageView: 앱 아이콘 (중앙)
- Label: "호구미터" (아이콘 아래)
- Background: 그라데이션 (CAGradientLayer)
```

#### 방법 B: SwiftUI Launch Screen (iOS 14+, 권장)
```swift
// LaunchScreenView.swift
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // 그라데이션 배경
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 앱 아이콘
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(26.67) // iOS 아이콘 라운드
                    .shadow(radius: 10)

                // 앱 이름
                Text("호구미터")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                // 슬로건
                Text("🚖 내 차 탔으면 내놔")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
```

### 2. Loading Animation View

```swift
// LoadingAnimationView.swift
struct LoadingAnimationView: View {
    @State private var horsePosition: CGFloat = -100
    @State private var horseSpeed: HorseSpeed = .walk
    @State private var meterValue: Int = 0
    @State private var isAnimating = false
    @State private var showMessage = false

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 말 애니메이션
            VStack(spacing: 40) {
                Spacer()

                // 말 캐릭터 + 미터기
                HStack(spacing: 10) {
                    Text(horseSpeed.emoji)
                        .font(.system(size: 80))

                    // 미터기
                    VStack {
                        Text("🚖")
                            .font(.system(size: 40))
                        Text("\(meterValue)원")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: horsePosition)

                Spacer()

                // 로딩 메시지
                if showMessage {
                    Text("준비 완료! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("로딩중...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // 말이 화면을 가로질러 달리기
        withAnimation(.easeInOut(duration: 2.0)) {
            horsePosition = UIScreen.main.bounds.width + 100
            horseSpeed = .gallop
        }

        // 미터기 카운트업
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if meterValue < 9999 {
                meterValue += Int.random(in: 100...500)
            } else {
                timer.invalidate()
                withAnimation {
                    showMessage = true
                }
            }
        }
    }
}
```

### 3. App Entry Point 수정

```swift
// HoguMeterApp.swift
@main
struct HoguMeterApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var disclaimerViewModel = DisclaimerViewModel()
    @State private var showDisclaimer = false
    @State private var showLoadingAnimation = true  // 추가
    @State private var isAppReady = false           // 추가

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLoadingAnimation {
                    // 로딩 애니메이션 표시
                    LoadingAnimationView()
                        .transition(.opacity)
                } else {
                    // 메인 콘텐츠
                    ContentView()
                        .environmentObject(appState)

                    // 면책 동의 다이얼로그
                    if showDisclaimer {
                        DisclaimerDialogView(isPresented: $showDisclaimer)
                            .transition(.opacity)
                    }
                }
            }
            .onAppear {
                // 앱 초기화
                initializeApp()

                // 로딩 애니메이션 (2초)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLoadingAnimation = false
                        showDisclaimer = true
                    }
                }
            }
        }
    }

    private func initializeApp() {
        // 필요한 초기화 작업
        // 예: 데이터 로드, 설정 확인 등
    }
}
```

---

## 🔧 구현 계획

### Phase 1: Launch Screen (정적)
- [ ] `LaunchScreen.storyboard` 또는 SwiftUI View 생성
- [ ] 앱 아이콘 이미지 추가
- [ ] 그라데이션 배경 설정
- [ ] 앱 이름 라벨 추가

### Phase 2: Loading Animation (동적)
- [ ] `LoadingAnimationView.swift` 생성
- [ ] 말 달리기 애니메이션 구현
- [ ] 미터기 카운트업 애니메이션 구현
- [ ] 로딩 메시지 표시
- [ ] 완료 후 페이드아웃 전환

### Phase 3: App Entry Point 통합
- [ ] `HoguMeterApp.swift` 수정
- [ ] 로딩 상태 관리
- [ ] 애니메이션 → 면책 동의 → 메인 화면 순서 구현
- [ ] 타이밍 조정 (2-3초)

---

## ✅ 체크리스트

### Launch Screen
- [ ] Launch Screen 파일 생성
- [ ] 배경 그라데이션 적용
- [ ] 앱 아이콘 중앙 배치
- [ ] 앱 이름 표시
- [ ] 다크모드 대응

### Loading Animation
- [ ] LoadingAnimationView 구현
- [ ] 말 애니메이션 구현
- [ ] 미터기 애니메이션 구현
- [ ] 효과음 추가 (선택)
- [ ] 부드러운 전환 효과

### 통합
- [ ] HoguMeterApp에 통합
- [ ] 타이밍 최적화
- [ ] 메모리 효율성 확인
- [ ] 다양한 기기 테스트

---

## 🧪 테스트 시나리오

### 시나리오 1: 앱 최초 실행
1. 앱 아이콘 탭
2. ✅ Launch Screen 표시 (0.5초)
3. ✅ Loading Animation 시작 (말이 달림, 2초)
4. ✅ 면책 동의 다이얼로그 표시
5. ✅ 동의 후 메인 화면 진입

### 시나리오 2: 앱 재실행
1. 앱 종료 후 다시 시작
2. ✅ Launch Screen 표시
3. ✅ Loading Animation 표시
4. ✅ 부드러운 전환

### 시나리오 3: 다양한 기기
1. iPhone SE (작은 화면) 테스트
2. iPhone 15 Pro Max (큰 화면) 테스트
3. ✅ 모든 기기에서 올바른 레이아웃
4. ✅ 애니메이션이 자연스러움

---

## 🎨 디자인 옵션

### 옵션 1: 심플 + 귀여움 (추천)
- 말 이모지 🐴가 좌→우로 달림
- 미터기 숫자 카운트업
- "로딩중..." → "준비 완료! 🎉"

### 옵션 2: 프로페셔널
- 앱 아이콘만 표시
- 서클 프로그레스 바
- "호구미터 로딩 중..."

### 옵션 3: 유머러스
- 말이 점점 빨라짐 (걷기→달리기→로켓)
- 미터기가 폭발하듯 카운트업
- "빨리빨리! 호구 잡으러 가자! 🚀"

---

## 📝 구현 노트

### iOS Launch Screen 제약사항
- **정적 콘텐츠만 가능**: Storyboard는 애니메이션 불가
- **SwiftUI는 iOS 14+**: 최신 방식 사용 가능
- **빠른 로딩**: 0.5-1초 이내 표시되어야 함

### Loading Animation 최적화
```swift
// 애니메이션 성능 최적화
.drawingGroup()  // 복잡한 애니메이션에 사용
.animation(.easeInOut, value: horsePosition)  // 특정 값만 애니메이션
```

### 타이밍 가이드
```swift
// 추천 타이밍
Launch Screen:       0.5초 (시스템 자동)
Loading Animation:   2.0초 (사용자 정의)
Fade Transition:     0.5초
Total:              약 3초
```

---

## 🐛 예상 이슈

1. **Launch Screen이 표시되지 않음**
   - Info.plist에서 UILaunchStoryboardName 확인
   - 빌드 후 시뮬레이터 재시작 필요

2. **애니메이션이 버벅임**
   - `.drawingGroup()` 추가
   - 애니메이션 복잡도 줄이기

3. **전환이 부자연스러움**
   - `.transition()` 모디파이어 조정
   - 타이밍 미세 조정

---

## 🎬 구현 예시 코드

### 간단한 로딩 뷰 (최소 버전)
```swift
struct SimpleLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("🐴")
                    .font(.system(size: 100))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(), value: isAnimating)

                Text("호구미터")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
```

---

## 📘 개발 가이드

**중요:** 이 Task를 구현하기 전에 반드시 아래 문서를 먼저 읽고 가이드를 준수해야 합니다.

- [DEVELOPMENT_GUIDE-FOR-AI.md](../../docs/DEVELOPMENT_GUIDE-FOR-AI.md)

위 가이드는 다음 내용을 포함합니다:
- Swift 코딩 컨벤션 (네이밍, 옵셔널 처리 등)
- 파일 구조 및 아키텍처 가이드
- AI 개발 워크플로우
- 커밋 메시지 규칙
- 테스트 작성 규칙
- 배포 전 체크리스트

## 📎 참고 자료

- [Apple HIG - Launch Screens](https://developer.apple.com/design/human-interface-guidelines/launching)
- [SwiftUI Animation](https://developer.apple.com/documentation/swiftui/animation)
- [Custom Launch Screen Tutorial](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-splash-screen)
- Task 2.1: 말 속도별 애니메이션 (HorseSpeed enum 활용)
