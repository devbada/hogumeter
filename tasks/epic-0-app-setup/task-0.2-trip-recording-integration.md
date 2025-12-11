# Task 0.2: 주행 기록 및 영수증 통합

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-0.2 |
| Epic | Epic 0: 앱 초기 설정 |
| 우선순위 | P0 (Must) |
| 예상 시간 | 2시간 |
| 상태 | ✅ 완료 |
| 담당 | Claude CLI |
| 생성일 | 2025-12-11 |
| 완료일 | 2025-12-11 |

---

## 🎯 목표

주행 종료 시 자동으로 Trip을 저장하고 영수증을 표시하며, 탭바에 히스토리 화면을 추가하여 저장된 기록을 조회할 수 있도록 통합합니다.

---

## 📌 관련 Task

- Task 4.1: 영수증 생성 (완료 - 파일만 존재)
- Task 6.1: 주행 기록 저장 (완료 - 파일만 존재)
- Task 6.2: 주행 기록 조회 (완료 - 파일만 존재)

**문제**: 위 Task들의 파일은 구현되었으나 메인 화면과 연동되지 않음

---

## 📝 상세 요구사항

### 1. 주행 종료 시 Trip 저장 및 영수증 표시

#### MeterViewModel 수정
```swift
// MARK: - Published Properties 추가
private(set) var completedTrip: Trip?  // 완료된 주행 정보

// MARK: - stopMeter() 수정
func stopMeter() {
    state = .stopped
    locationService.stopTracking()
    stopTimer()
    calculateFinalFare()
    soundManager.play(.meterStop)

    // Trip 생성 및 저장
    saveTrip()
}

private func saveTrip() {
    guard let startTime = tripStartTime,
          let breakdown = fareBreakdown else { return }

    let trip = Trip(
        id: UUID(),
        startTime: startTime,
        endTime: Date(),
        totalFare: breakdown.totalFare,
        distance: locationService.totalDistance,
        duration: duration,
        startRegion: regionDetector.startRegion ?? "알 수 없음",
        endRegion: currentRegion.isEmpty ? "알 수 없음" : currentRegion,
        regionChangeCount: regionDetector.regionChangeCount,
        isNightTime: isNightTime,
        fareBreakdown: breakdown
    )

    tripRepository.save(trip)
    completedTrip = trip  // 영수증 표시용
}

func clearCompletedTrip() {
    completedTrip = nil
}
```

#### MainMeterView 수정
```swift
struct MainMeterView: View {
    @State var viewModel: MeterViewModel
    @State private var showReceipt = false  // 영수증 표시 상태

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 기존 UI...
            }
            .navigationTitle("🐴 호구미터")
            // 영수증 Sheet 추가
            .sheet(isPresented: $showReceipt) {
                if let trip = viewModel.completedTrip {
                    NavigationStack {
                        ReceiptView(trip: trip)
                    }
                }
            }
            .onChange(of: viewModel.completedTrip) { _, newTrip in
                showReceipt = (newTrip != nil)
            }
        }
    }
}
```

### 2. TabView 추가하여 히스토리 화면 통합

#### ContentView 수정
```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 메인 미터 탭
            MainMeterView(
                viewModel: MeterViewModel(
                    locationService: appState.locationService,
                    fareCalculator: appState.fareCalculator,
                    regionDetector: appState.regionDetector,
                    soundManager: appState.soundManager,
                    tripRepository: appState.tripRepository
                )
            )
            .tabItem {
                Label("미터기", systemImage: "speedometer")
            }
            .tag(0)

            // 히스토리 탭
            TripHistoryView(repository: appState.tripRepository)
                .tabItem {
                    Label("기록", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            // 설정 탭
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
                .tag(2)
        }
    }
}
```

### 3. RegionDetector에 시작 지역 추적 추가

```swift
final class RegionDetector {
    private(set) var regionChangeCount = 0
    private(set) var startRegion: String?  // 추가
    private var currentRegion: String?

    func reset() {
        regionChangeCount = 0
        currentRegion = nil
        startRegion = nil  // 추가
    }

    func update(region: String) {
        // 시작 지역 저장
        if startRegion == nil {
            startRegion = region
        }

        // 기존 로직...
        if let current = currentRegion, current != region {
            regionChangeCount += 1
        }
        currentRegion = region
    }
}
```

---

## ✅ 체크리스트

### ViewModel 수정
- [ ] MeterViewModel에 `completedTrip` 프로퍼티 추가
- [ ] MeterViewModel에 `saveTrip()` 메서드 구현
- [ ] `stopMeter()` 호출 시 `saveTrip()` 자동 호출
- [ ] `clearCompletedTrip()` 메서드 추가

### View 수정
- [ ] MainMeterView에 영수증 Sheet 추가
- [ ] `completedTrip` 변경 감지하여 Sheet 표시
- [ ] ContentView를 TabView로 변경
- [ ] 미터기/기록/설정 3개 탭 구성

### RegionDetector 수정
- [ ] `startRegion` 프로퍼티 추가
- [ ] `reset()` 시 startRegion 초기화
- [ ] 첫 위치 업데이트 시 startRegion 저장

### 통합 테스트
- [ ] 빌드 성공
- [ ] 주행 시작 → 종료 시 영수증 자동 표시
- [ ] 영수증 닫기 후 히스토리 탭에서 기록 확인
- [ ] 히스토리에서 기록 탭 → 상세 보기
- [ ] 히스토리에서 스와이프 삭제

---

## 🧪 테스트 시나리오

### 시나리오 1: 주행 완료 후 영수증 표시
1. 미터기 탭에서 "시작" 버튼 탭
2. 몇 초 대기
3. "정지" 버튼 탭
4. ✅ 영수증 Sheet가 자동으로 표시됨
5. ✅ 주행 정보 및 요금 내역 확인
6. 닫기 버튼으로 Sheet 닫기

### 시나리오 2: 히스토리 탭에서 기록 확인
1. 하단 탭바에서 "기록" 탭 선택
2. ✅ 방금 완료한 주행 기록이 목록 최상단에 표시됨
3. 기록 탭하여 상세 보기
4. ✅ 상세 정보 확인

### 시나리오 3: 여러 번 주행 후 기록 확인
1. 주행 3회 반복 (시작 → 정지)
2. 히스토리 탭으로 이동
3. ✅ 3개의 기록이 최신순으로 정렬됨
4. 스와이프하여 하나 삭제
5. ✅ 목록에서 제거됨

### 시나리오 4: 빈 히스토리 상태
1. 히스토리 탭에서 모든 기록 삭제
2. ✅ ContentUnavailableView 표시
3. "주행 기록이 없습니다" 메시지 확인

---

## 📝 구현 노트

### 수정할 파일
- `HoguMeter/Presentation/ViewModels/MeterViewModel.swift`
- `HoguMeter/Presentation/Views/Main/MainMeterView.swift`
- `HoguMeter/Presentation/Views/ContentView.swift`
- `HoguMeter/Domain/Services/RegionDetector.swift`

### 새로 추가할 파일
없음 (기존 파일들 활용)

---

## 🐛 예상 이슈

1. **Trip 생성 시 nil 값 처리**
   - tripStartTime이 nil일 수 있음 → guard let으로 안전 처리
   - fareBreakdown이 nil일 수 있음 → guard let으로 안전 처리

2. **TabView 전환 시 상태 유지**
   - MeterViewModel이 재생성되지 않도록 주의
   - @State가 아닌 @StateObject 사용 필요 시 고려

3. **영수증 Sheet 중복 표시**
   - completedTrip을 Sheet 닫을 때 초기화 필요
   - onDismiss 콜백 활용

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

- Task 4.1: 영수증 생성 (ReceiptView)
- Task 6.1: 주행 기록 저장 (TripRepository)
- Task 6.2: 주행 기록 조회 (TripHistoryView)
- [SwiftUI TabView](https://developer.apple.com/documentation/swiftui/tabview)
- [SwiftUI Sheet](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:))
