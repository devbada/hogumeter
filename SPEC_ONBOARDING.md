# Coach Mark (Tooltip Guide) System Specification

## Overview

This document describes the implementation of a coach mark (tooltip/spotlight) system that guides first-time users through all major screens of the HoguMeter app.

## Screen Structure

```
Tab Bar
├── 🏠 메인 (Main Meter) ──→ Coach marks on first visit (4 marks)
│   └── 🗺️ 지도 (Map) ──→ Coach marks on first map open during trip (3 marks)
├── 📋 기록 (History) ──→ Coach marks on first visit (2 marks)
├── 📊 통계 (Statistics) ──→ Coach marks on first visit with saved records (3 marks)
└── ⚙️ 설정 (Settings) ──→ Coach marks on first visit (4 marks)
```

**Note**: The Map screen is NOT a separate tab. It is only accessible via a button while the meter is running.

---

## Architecture

### File Structure

```
HoguMeter/
├── Core/
│   └── CoachMark/
│       ├── Models/
│       │   ├── CoachMark.swift           # Single coach mark model
│       │   └── CoachMarkScreen.swift     # Screen with coach marks
│       ├── Manager/
│       │   └── CoachMarkManager.swift    # State management (singleton)
│       ├── Views/
│       │   ├── CoachMarkOverlay.swift    # Full overlay combining spotlight + tooltip
│       │   ├── SpotlightBackground.swift # Semi-transparent background with cutout
│       │   └── TooltipBubble.swift       # Tooltip with buttons
│       ├── Modifiers/
│       │   └── CoachMarkTarget.swift     # View modifier for target elements
│       └── Data/
│           └── CoachMarkData.swift       # Static coach mark data
└── HoguMeterTests/
    └── CoachMarkManagerTests.swift       # Unit tests
```

### Core Models

```swift
// Position for tooltip relative to target element
enum TooltipPosition {
    case top
    case bottom
    case left
    case right
    case auto  // Automatically determine based on screen position
}

// Single coach mark
struct CoachMark: Identifiable, Equatable {
    let id: String
    let targetView: String          // View identifier to highlight
    let title: String               // Short title
    let description: String         // Explanation text
    let position: TooltipPosition   // Where to show tooltip
    let order: Int                  // Display order within screen
}

// Screen with associated coach marks
struct CoachMarkScreen: Identifiable {
    let id: String                  // Screen identifier
    let screenName: String          // Display name
    let coachMarks: [CoachMark]     // Coach marks for this screen
}
```

### State Management

```swift
@MainActor
final class CoachMarkManager: ObservableObject {
    static let shared = CoachMarkManager()

    @Published var isShowingCoachMark: Bool
    @Published var currentScreenId: String?
    @Published var currentMarkIndex: Int

    // Per-screen completion flags (persisted in UserDefaults)
    @AppStorage("hasCompletedOnboarding_main") var completedMain
    @AppStorage("hasCompletedOnboarding_map") var completedMap
    @AppStorage("hasCompletedOnboarding_history") var completedHistory
    @AppStorage("hasCompletedOnboarding_statistics") var completedStatistics
    @AppStorage("hasCompletedOnboarding_settings") var completedSettings

    func shouldShowCoachMarks(for screenId: String) -> Bool
    func startCoachMarks(for screenId: String)
    func nextCoachMark()
    func skipCoachMarks()
    func completeCurrentScreen()
    func resetAllCoachMarks()  // For "가이드 다시 보기"
}
```

---

## Screen-Specific Coach Marks

### Screen 1: Main Meter (메인 미터기)

| Order | Target | Title | Description |
|-------|--------|-------|-------------|
| 1 | fareDisplay | 요금 표시 | 실시간으로 계산되는 택시 요금이 여기에 표시됩니다. |
| 2 | horseAnimation | 말 애니메이션 | 속도에 따라 말이 달리는 속도가 변해요! 80km/h 이상이면 폭주합니다. |
| 3 | statsGrid | 주행 정보 | 거리, 시간, 속도, 현재 지역을 실시간으로 확인하세요. |
| 4 | startButton | 시작 버튼 | 여기를 눌러 미터기를 시작하세요! 정지하면 영수증을 확인할 수 있어요. |

### Screen 2: Map (지도) - During Trip Only

**Trigger**: First time user taps the map button while meter is running.

| Order | Target | Title | Description |
|-------|--------|-------|-------------|
| 1 | routeMap | 경로 표시 | 주행 경로가 지도에 실시간으로 그려집니다. |
| 2 | mapInfoGrid | 주행 정보 | 요금, 속도, 거리, 시간을 한눈에 확인할 수 있어요. |
| 3 | closeButton | 미터기로 돌아가기 | 여기를 누르면 미터기 화면으로 돌아갑니다. |

### Screen 3: History (기록)

| Order | Target | Title | Description |
|-------|--------|-------|-------------|
| 1 | tripList | 주행 기록 | 완료된 주행 기록이 여기에 저장됩니다. 아래로 스크롤하면 더 많은 기록을 볼 수 있어요. |
| 2 | tripItem | 상세 보기 | 기록을 탭하면 영수증과 상세 정보를 다시 볼 수 있어요. |

### Screen 4: Statistics (통계)

**Trigger**: First visit after at least one trip has been saved.

| Order | Target | Title | Description |
|-------|--------|-------|-------------|
| 1 | statisticsOverview | 전체 이용 통계 | 전체 이용기간의 총 거리, 총 발생금액, 주행 횟수를 확인할 수 있어요. |
| 2 | statisticsPeriod | 기간별 추이 | 월별과 주간 기준을 바꿔 거리와 발생금액 추이를 비교해보세요. |
| 3 | statisticsMap | 이용 지역 모아보기 | 저장된 주행 경로를 격자로 모아 자주 이용한 지역을 확인할 수 있어요. |

### Screen 5: Settings (설정)

| Order | Target | Title | Description |
|-------|--------|-------|-------------|
| 1 | regionSetting | 지역 설정 | 출발 지역의 택시 요금 기준을 선택하세요. (서울, 부산, 대구 등) |
| 2 | surchargeMode | 할증 설정 | 야간 할증, 지역 할증 등 다양한 할증 옵션을 설정할 수 있어요. |
| 3 | soundSetting | 앱 설정 | 효과음, 다크 모드 등 앱 환경을 설정할 수 있어요. |
| 4 | resetGuide | 가이드 다시 보기 | 이 가이드를 다시 보고 싶으면 여기를 눌러주세요! |

---

## Integration Guide

### Adding Coach Mark Target to a View

```swift
// 1. Add the coachMarkTarget modifier
FareDisplayView(fare: viewModel.currentFare)
    .coachMarkTarget(id: "fareDisplay")

// 2. Store frames using preference key
@State private var coachMarkFrames: [String: CGRect] = [:]

.onPreferenceChange(CoachMarkFramePreferenceKey.self) { frames in
    coachMarkFrames = frames
}
```

### Showing Coach Mark Overlay

```swift
// In your view's ZStack
if coachMarkManager.isShowingCoachMark,
   coachMarkManager.currentScreenId == "main",
   let currentMark = coachMarkManager.currentCoachMark,
   let frame = coachMarkFrames[currentMark.targetView] {
    CoachMarkOverlay(
        manager: coachMarkManager,
        coachMark: currentMark,
        targetFrame: frame
    )
}
```

### Triggering Coach Marks on Appear

```swift
.onAppear {
    if coachMarkManager.shouldShowCoachMarks(for: "main") {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            coachMarkManager.startCoachMarks(for: "main")
        }
    }
}
```

---

## Settings: Reset Guide Option

A "가이드 다시 보기" option is available in Settings under the "도움말" section. When tapped:

1. Calls `CoachMarkManager.shared.resetAllCoachMarks()`
2. Shows confirmation alert
3. Next visit to each screen will trigger coach marks again

---

## UI Components

### Spotlight Background
- Black overlay with 75% opacity
- Rounded rectangle cutout around target element
- 8pt padding around target
- 12pt corner radius on cutout

### Tooltip Bubble
- Dark background (15% white)
- 16pt corner radius
- Title: Headline font, bold, white
- Description: Subheadline font, white with 90% opacity
- Progress dots: 6pt circles, yellow for current, 40% white for others
- Skip button: "건너뛰기", 70% white opacity
- Next/Done button: Yellow background with black text

---

## Test Cases

| TC | Description | Expected Result |
|----|-------------|-----------------|
| 001 | First app launch | Main screen shows coach marks |
| 002 | First visit to History tab | History coach marks appear |
| 003 | First visit to Settings tab | Settings coach marks appear |
| 004 | First time opening map during trip | Map coach marks appear |
| 005 | "다음" button | Advances through all coach marks in order |
| 006 | "건너뛰기" button | Completes coach marks for that screen |
| 007 | Subsequent visits | Don't show coach marks again |
| 008 | "가이드 다시 보기" | Resets all screens |
| 009 | After reset | Visiting each screen shows coach marks again |
| 010 | Spotlight | Correctly highlights target element |
| 011 | Tooltip position | Doesn't go off screen edges |

---

## Persistence

Coach mark completion states are stored using `@AppStorage`:

```swift
@AppStorage("hasCompletedOnboarding_main") var completedMain = false
@AppStorage("hasCompletedOnboarding_map") var completedMap = false
@AppStorage("hasCompletedOnboarding_history") var completedHistory = false
@AppStorage("hasCompletedOnboarding_settings") var completedSettings = false
@AppStorage("onboardingVersion") var onboardingVersion = 1
```

The `onboardingVersion` can be incremented to force re-display of coach marks after a major app update.

---

## Animations

- Overlay appearance: 0.25s ease-out
- Transition between marks: 0.3s ease-in-out
- Overlay dismissal: 0.2s ease-in
- Tooltip scale effect: 0.9 → 1.0 on appear
