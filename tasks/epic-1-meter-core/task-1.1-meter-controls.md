# Task 1.1: 미터기 컨트롤 (시작/정지/리셋)

> **Epic**: Epic 1 - 미터기 핵심 기능
> **Status**: 🟢 Done
> **Priority**: P0
> **Estimate**: 4시간
> **PRD**: FR-1.1

---

## 📋 개요

사용자가 미터기를 시작, 정지, 리셋할 수 있는 기본 컨트롤 기능을 구현합니다.

## 🎯 목표

미터기의 생명주기를 관리하는 핵심 컨트롤 시스템을 구현하여, 사용자가 직관적으로 미터기를 조작할 수 있도록 합니다.

## ✅ Acceptance Criteria

작업 완료 조건:

- [x] "시작" 버튼 탭 시 미터기가 작동 시작
- [x] "정지" 버튼 탭 시 미터기가 정지하고 최종 요금 표시
- [x] "리셋" 버튼 탭 시 모든 값이 초기화
- [x] 시작 시 GPS 추적 활성화
- [x] 정지 시 GPS 추적 비활성화
- [x] 버튼 탭 시 촉각 피드백(Haptic) 제공
- [x] 상태별 버튼 표시 전환 (시작 ↔ 정지)
- [x] 리셋 버튼은 정지 상태에서만 활성화

## 📝 구현 사항

### 1. MeterState Enum 정의
```swift
// Domain/Entities/MeterState.swift
enum MeterState {
    case idle       // 대기 중
    case running    // 주행 중
    case stopped    // 정지됨
}
```
- [x] 구현 완료: `HoguMeter/Domain/Entities/MeterState.swift`

### 2. MeterViewModel 상태 관리
```swift
// Presentation/ViewModels/MeterViewModel.swift
@Observable
final class MeterViewModel {
    private(set) var state: MeterState = .idle

    func startMeter() { }
    func stopMeter() { }
    func resetMeter() { }
}
```
- [x] 구현 완료: `HoguMeter/Presentation/ViewModels/MeterViewModel.swift:17`

### 3. ControlButtonsView UI 구현
```swift
// Presentation/Views/Main/Components/ControlButtonsView.swift
struct ControlButtonsView: View {
    let state: MeterState
    let onStart: () -> Void
    let onStop: () -> Void
    let onReset: () -> Void
}
```
- [x] 구현 완료: `HoguMeter/Presentation/Views/Main/Components/ControlButtonsView.swift`

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Entities/MeterState.swift` - 상태 정의
- [x] `HoguMeter/Presentation/ViewModels/MeterViewModel.swift` - 상태 관리 로직
- [x] `HoguMeter/Presentation/Views/Main/Components/ControlButtonsView.swift` - 버튼 UI
- [x] `HoguMeter/Core/Utils/HapticManager.swift` - 햅틱 피드백

## 📖 참고 사항

### PRD 참조
- **FR-1.1**: 미터기 시작/정지/리셋 기능 요구사항

### 의존성
- **선행 Task**: 없음 (첫 번째 Task)
- **후행 Task**: Task 1.2 (요금 계산), Task 1.3 (GPS 추적)

### 기술 스택
- SwiftUI for UI
- @Observable macro for state management
- Haptic Feedback (UIKit)

## 🧪 테스트 계획

### Unit Tests
```swift
// MeterViewModelTests.swift
- [x] testStartMeter_ShouldChangeStateToRunning
- [x] testStopMeter_ShouldChangeStateToStopped
- [x] testResetMeter_ShouldChangeStateToIdle
- [x] testResetMeter_ShouldClearAllValues
```

### UI Tests
```
- [x] 시작 버튼 탭 → 정지 버튼으로 전환
- [x] 정지 버튼 탭 → 리셋 버튼 표시
- [x] 리셋 버튼 탭 → 시작 버튼으로 복귀
```

## 🐛 알려진 이슈

없음

## 📌 체크리스트

구현 전:
- [x] PRD 요구사항 확인
- [x] 아키텍처 문서 확인
- [x] 의존성 Task 완료 확인 (N/A)

구현 중:
- [x] MeterState enum 작성
- [x] MeterViewModel 메서드 구현
- [x] ControlButtonsView 작성
- [x] Haptic 피드백 연동
- [x] 주석 추가

구현 후:
- [x] 자체 테스트
- [ ] Unit Test 작성
- [ ] UI Test 작성
- [ ] 코드 리뷰 요청
- [x] 문서 업데이트

## 📅 작업 로그

| Date | Activity | Notes |
|------|----------|-------|
| 2025-01-15 | Task 생성 | Epic 1 시작 |
| 2025-01-15 | 구현 완료 | MeterViewModel, ControlButtonsView 구현 |
| 2025-01-15 | 상태 변경 | 🟢 Done |

---

**Created**: 2025-01-15
**Last Updated**: 2025-01-15
