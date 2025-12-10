# Epic 1: 미터기 핵심 기능 (Meter Core)

> **Priority**: P0 (Must Have)
> **Status**: 🟢 Done
> **Target**: Week 1-2
> **PRD Reference**: Epic 1 (FR-1.1 ~ FR-1.4)

---

## 📋 Epic 개요

HoguMeter의 핵심 기능인 택시 미터기 기능을 구현합니다. GPS를 기반으로 실시간 거리와 시간을 측정하고, 택시 요금 체계에 따라 요금을 계산하여 표시합니다.

## 🎯 Epic 목표

- [x] 미터기 시작/정지/리셋 기능 구현
- [x] GPS 기반 거리 측정 시스템 구현
- [x] 실시간 요금 계산 로직 구현
- [x] 주행 정보 실시간 표시 UI 구현

## 📊 Task 목록

| Task | Title | Status | Priority | PRD |
|------|-------|--------|----------|-----|
| 1.0 | 백그라운드 GPS 권한 설정 | 🟢 Done | P0 | FR-1.3 |
| 1.1 | 미터기 컨트롤 (시작/정지/리셋) | 🟢 Done | P0 | FR-1.1 |
| 1.2 | 요금 계산 시스템 | 🟢 Done | P0 | FR-1.2 |
| 1.3 | GPS 거리 측정 | 🟢 Done | P0 | FR-1.3 |
| 1.4 | 실시간 정보 표시 | 🟢 Done | P0 | FR-1.4 |

## 🏗️ 아키텍처 개요

```
┌─────────────────────────────────────┐
│        MeterViewModel               │
│  (Presentation/ViewModels/)         │
│  - state: MeterState                │
│  - currentFare: Int                 │
│  - distance: Double                 │
│  - duration: TimeInterval           │
│  - currentSpeed: Double             │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│       Domain Services                │
│  - LocationService (GPS 추적)        │
│  - FareCalculator (요금 계산)        │
│  - RegionDetector (지역 감지)        │
└─────────────────────────────────────┘
```

## 📝 상세 Task 설명

### Task 1.0: 백그라운드 GPS 권한 설정
**파일**: `task-1.0-background-location-permission.md`

미터기 구현에 앞서 필요한 iOS 위치 권한 시스템을 설정합니다.
- Info.plist 위치 권한 설명 추가
- Background Modes 설정
- 권한 요청 시나리오 문서화

### Task 1.1: 미터기 컨트롤
**파일**: `task-1.1-meter-controls.md`

미터기의 시작, 정지, 리셋 기능을 구현합니다.
- MeterViewModel의 상태 관리
- ControlButtonsView UI 구현
- Haptic 피드백 연동

### Task 1.2: 요금 계산 시스템
**파일**: `task-1.2-fare-calculation.md`

택시 요금 체계를 기반으로 한 실시간 요금 계산 로직을 구현합니다.
- FareCalculator 서비스
- 기본요금 + 거리요금 + 시간요금 계산
- 요금 상세 내역 (FareBreakdown)

### Task 1.3: GPS 거리 측정
**파일**: `task-1.3-gps-tracking.md`

Core Location을 사용한 정확한 거리 측정 시스템을 구현합니다.
- LocationService 구현
- 거리 계산 알고리즘
- 저속 시간 추적

### Task 1.4: 실시간 정보 표시
**파일**: `task-1.4-realtime-display.md`

주행 중 필요한 정보를 실시간으로 표시합니다.
- FareDisplayView (요금 표시)
- TripInfoView (거리, 시간, 속도, 지역)
- 실시간 업데이트 UI

## ✅ Epic 완료 조건

- [ ] 모든 Task 완료 (Status: 🟢)
- [x] LocationService 정상 작동
- [x] 요금 계산 정확도 검증
- [x] UI 반응성 테스트
- [ ] 실제 주행 테스트 (1km 이상)
- [ ] GPS 정확도 검증 (오차 5% 이내)

## 🧪 테스트 계획

### Unit Tests
- [ ] FareCalculator 테스트
- [ ] LocationService 테스트
- [ ] MeterViewModel 상태 전환 테스트

### Integration Tests
- [ ] 전체 미터기 플로우 테스트
- [ ] GPS → 요금 계산 통합 테스트

### Manual Tests
- [ ] 실제 차량 주행 테스트
- [ ] 다양한 속도 테스트
- [ ] 정차/출발 반복 테스트

## 📖 참고 문서

- [PRD.md](../../docs/PRD.md) - Section 2.1: Epic 1
- [ARCHITECTURE.md](../../docs/ARCHITECTURE.md) - Section 4: Core Components
- [PROJECT_BRIEF.md](../../docs/PROJECT_BRIEF.md) - Section 4: Core Features

## 🔗 의존성

### 필수 Framework
- Core Location
- Combine
- SwiftUI

### 다음 Epic과의 연계
- Epic 2: 말 애니메이션 (속도 데이터 사용)
- Epic 3: 요금 설정 (요금 계산 로직 확장)

## 📅 타임라인

```
Week 1:
├── Day 1-2: Task 1.1, 1.3 (LocationService + 컨트롤)
├── Day 3-4: Task 1.2 (FareCalculator)
└── Day 5: Task 1.4 (UI 구현)

Week 2:
├── Day 1-2: 테스트 작성
├── Day 3-4: 실제 주행 테스트
└── Day 5: 버그 수정 및 최적화
```

## 🐛 알려진 이슈

- GPS 신호 약한 지역에서 정확도 저하 → 보정 알고리즘 필요
- 백그라운드 위치 추적 시 배터리 소모 → 최적화 필요

## 📊 진행 상황

**전체 진행률**: 100% (5/5 Tasks 완료)

| Status | Count | Percentage |
|--------|-------|------------|
| 🟢 Done | 5 | 100% |
| 🟡 In Progress | 0 | 0% |
| 🔵 Ready | 0 | 0% |

## 📝 주요 구현 결과

1. **Task 1.0**: Info.plist 위치 권한 설정 완료
2. **Task 1.1**: MeterViewModel, ControlButtonsView 구현
3. **Task 1.2**: FareCalculator, FareBreakdown 구현
4. **Task 1.3**: LocationService, GPS 거리 측정 구현
5. **Task 1.4**: FareDisplayView, TripInfoView 구현

---

**Created**: 2025-01-15
**Completed**: 2025-12-10
**Last Updated**: 2025-12-10
