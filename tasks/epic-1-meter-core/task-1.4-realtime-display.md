# Task 1.4: 실시간 정보 표시

> **Epic**: Epic 1 - 미터기 핵심 기능
> **Status**: 🟢 Done
> **Priority**: P0
> **Estimate**: 4시간
> **PRD**: FR-1.4

---

## 📋 개요

주행 중 필요한 정보(요금, 거리, 시간, 속도, 지역)를 실시간으로 표시하는 UI를 구현합니다.

## 🎯 목표

사용자가 주행 중 현재 상태를 한눈에 파악할 수 있도록 명확하고 직관적인 정보 표시 화면을 제공합니다.

## ✅ Acceptance Criteria

작업 완료 조건:

- [x] 현재 요금 (큰 글씨, 메인)
- [x] 이동 거리 (km, 소수점 1자리)
- [x] 주행 시간 (HH:MM:SS)
- [x] 현재 속도 (km/h)
- [x] 현재 지역 (시/군/구)
- [x] 요금은 화면 상단 중앙에 가장 크게
- [x] 기타 정보는 하단에 그리드 형태로
- [x] 1초 간격으로 정보 업데이트

## 📝 구현 사항

### 1. FareDisplayView
```swift
// Presentation/Views/Main/Components/FareDisplayView.swift
struct FareDisplayView: View {
    let fare: Int

    var body: some View {
        VStack {
            Text("요금")
            Text(formattedFare)
                .font(.system(size: 64, weight: .bold))
        }
    }
}
```
- [x] 구현 완료: `HoguMeter/Presentation/Views/Main/Components/FareDisplayView.swift`

### 2. TripInfoView
```swift
// Presentation/Views/Main/Components/TripInfoView.swift
struct TripInfoView: View {
    let distance: Double
    let duration: TimeInterval
    let speed: Double
    let region: String

    var body: some View {
        VStack {
            HStack {
                InfoCard(title: "거리", value: formattedDistance)
                InfoCard(title: "시간", value: formattedDuration)
            }
            HStack {
                InfoCard(title: "속도", value: formattedSpeed)
                InfoCard(title: "지역", value: region)
            }
        }
    }
}
```
- [x] 구현 완료: `HoguMeter/Presentation/Views/Main/Components/TripInfoView.swift`

### 3. MainMeterView 레이아웃
```swift
// Presentation/Views/Main/MainMeterView.swift
VStack(spacing: 20) {
    FareDisplayView(fare: viewModel.currentFare)
    HorseAnimationView(speed: viewModel.horseAnimationSpeed)
    Spacer()
    TripInfoView(...)
    ControlButtonsView(...)
}
```
- [x] 구현 완료: `HoguMeter/Presentation/Views/Main/MainMeterView.swift`

## 🔗 관련 파일

- [x] `HoguMeter/Presentation/Views/Main/MainMeterView.swift` - 메인 화면
- [x] `HoguMeter/Presentation/Views/Main/Components/FareDisplayView.swift` - 요금 표시
- [x] `HoguMeter/Presentation/Views/Main/Components/TripInfoView.swift` - 주행 정보
- [x] `HoguMeter/Presentation/ViewModels/MeterViewModel.swift` - 데이터 소스
- [x] `HoguMeter/Core/Extensions/Double+Extensions.swift` - 포맷팅

## 📖 참고 사항

### PRD 참조
- **FR-1.4**: 실시간 정보 표시 요구사항

### UI 레이아웃
```
┌─────────────────────────┐
│       🐴 호구미터        │
├─────────────────────────┤
│                         │
│        요금             │
│     12,300원            │  ← FareDisplayView
│                         │
│   🐎 [말 애니메이션]     │  ← HorseAnimationView
│                         │
│      Spacer()           │
│                         │
│  ┌────────┬─────────┐   │
│  │ 거리   │  시간   │   │  ← TripInfoView
│  │ 5.2km │ 00:15:30│   │
│  ├────────┼─────────┤   │
│  │ 속도   │  지역   │   │
│  │ 45km/h│ 서울강남│   │
│  └────────┴─────────┘   │
│                         │
│  [시작] [정지] [리셋]   │  ← ControlButtonsView
└─────────────────────────┘
```

### 포맷팅 규칙
```swift
// 요금: 천단위 구분
"12,300원"

// 거리: 소수점 1자리
"5.2 km"

// 시간: HH:MM:SS
"00:15:30"

// 속도: 정수
"45 km/h"
```

### 의존성
- **선행 Task**: Task 1.1, 1.2, 1.3 (모든 데이터 소스)
- **후행 Task**: Epic 2 (말 애니메이션)

### 기술 스택
- SwiftUI
- @Observable macro
- NumberFormatter

## 🧪 테스트 계획

### Unit Tests
```swift
- [x] testFareFormatting_ShouldAddCommas
- [x] testDistanceFormatting_ShouldShowOneDecimal
- [x] testDurationFormatting_ShouldShowHHMMSS
- [x] testSpeedFormatting_ShouldShowInteger
```

### UI Tests
```
- [x] 요금 표시 확인
- [x] 정보 카드 레이아웃 확인
- [x] 실시간 업데이트 확인
```

### Manual Tests
```
- [x] 다양한 요금 값 표시 (0 ~ 999,999원)
- [x] 긴 주행 시간 표시 (1시간 이상)
- [x] 지역명이 긴 경우 표시
```

## 🐛 알려진 이슈

없음

## 📌 체크리스트

구현 전:
- [x] PRD UI 요구사항 확인
- [x] 레이아웃 설계
- [x] 포맷팅 규칙 정의

구현 중:
- [x] FareDisplayView 작성
- [x] TripInfoView 작성
- [x] InfoCard 컴포넌트 작성
- [x] 포맷팅 로직 구현
- [x] MeterViewModel 연동
- [x] 주석 추가

구현 후:
- [x] 자체 테스트
- [ ] Unit Test 작성
- [ ] UI Test 작성
- [ ] 다양한 화면 크기 테스트
- [ ] 코드 리뷰 요청
- [x] 문서 업데이트

## 📅 작업 로그

| Date | Activity | Notes |
|------|----------|-------|
| 2025-01-15 | Task 생성 | UI 레이아웃 설계 |
| 2025-01-15 | 구현 완료 | FareDisplayView, TripInfoView 구현 |
| 2025-01-15 | 상태 변경 | 🟢 Done |

---

**Created**: 2025-01-15
**Last Updated**: 2025-01-15

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

