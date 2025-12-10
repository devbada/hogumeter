# Epic 2: 말 애니메이션 시스템 (Horse Animation)

> **Priority**: P0 (Must Have)
> **Status**: 🟢 Done
> **Target**: Week 3
> **PRD Reference**: Epic 2 (FR-2.1 ~ FR-2.3)

---

## 📋 Epic 개요

차량 속도에 연동되어 변화하는 말 애니메이션 시스템을 구현합니다. 속도에 따라 말의 움직임이 달라지며, 80km/h 이상에서는 특수 효과를 표시합니다.

## 🎯 Epic 목표

- [x] 속도별 애니메이션 시스템 구현 (6단계)
- [x] 이모지 기반 간단한 시각 피드백 구현
- [x] 속도별 텍스트 상태 표시

## 📊 Task 목록

| Task | Title | Status | Priority | PRD |
|------|-------|--------|----------|-----|
| 2.1 | 속도 연동 애니메이션 | 🟢 Done (간소화) | P0 | FR-2.1 |
| 2.2 | 80km/h 특수 효과 | ⚪ 삭제됨 | P0 | FR-2.2 |
| 2.3 | 배경 스크롤 | ⚪ 삭제됨 | P1 | FR-2.3 |

## 🏗️ 아키텍처 개요

```
┌─────────────────────────────────────┐
│      MeterViewModel                 │
│  currentSpeed: Double               │
│  horseAnimationSpeed: HorseSpeed    │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│   HorseAnimationView                │
│  - 속도별 애니메이션 선택             │
│  - 전환 효과 (0.3s)                  │
│  - 80km/h 특수 효과                  │
└─────────────────────────────────────┘
```

## 📝 속도별 애니메이션 상태

| 속도 구간 | HorseSpeed | 설명 | 이모지 |
|----------|-----------|------|--------|
| 0 km/h | .idle | 서있음 | 🐴 |
| 1-20 km/h | .walk | 느린 걸음 | 🐎 |
| 21-40 km/h | .trot | 빠른 걸음 | 🏇 |
| 41-60 km/h | .run | 달리기 | 🏇 |
| 61-80 km/h | .gallop | 질주 | 🏇💨 |
| 80+ km/h | .sprint | 폭주 (특수효과) | 🏇💨🔥 |

## ✅ Epic 완료 조건

- [x] Task 2.1 완료 (이모지 기반 간소화)
- [x] 6단계 속도 전환 작동 (이모지 + 텍스트)
- [x] 간단하고 직관적인 UI
- [ ] 실제 주행 테스트 통과 (차후 실제 테스트 필요)

**참고**: Task 2.2, 2.3은 복잡도 문제로 삭제되었습니다 (2025-12-09)

## 🧪 테스트 계획

### Unit Tests
- [ ] HorseSpeed enum 테스트
- [ ] 속도별 애니메이션 전환 테스트

### UI Tests
- [ ] 모든 속도 구간 애니메이션 확인
- [ ] 80km/h 특수 효과 확인
- [ ] 배경 스크롤 확인

### Performance Tests
- [ ] 60fps 유지 확인
- [ ] 메모리 사용량 모니터링

## 📖 참고 문서

- [PRD.md](../../docs/PRD.md) - Section 2.2: Epic 2
- [ARCHITECTURE.md](../../docs/ARCHITECTURE.md) - Section 4: Core Components

## 🔗 의존성

### 필수 Framework
- SwiftUI
- CoreAnimation

### 선행 Epic
- Epic 1: 미터기 핵심 (속도 데이터 제공)

## 📅 타임라인

```
Week 3:
├── Day 1-2: Task 2.1 (속도 애니메이션)
├── Day 3: Task 2.2 (특수 효과)
└── Day 4-5: Task 2.3 (배경 스크롤)
```

## 🐛 알려진 이슈

- 애니메이션 리소스 (이미지/Lottie) 필요
- 고성능 애니메이션 최적화 필요

## 📊 진행 상황

**전체 진행률**: 33% (1/3 Tasks 완료, 2개 삭제)

| Status | Count | Percentage |
|--------|-------|------------|
| 🟢 Done | 1 | 33% |
| ⚪ 삭제됨 | 2 | 67% |
| 🟡 In Progress | 0 | 0% |
| 🔵 Ready | 0 | 0% |

## 📝 주요 구현 결과

1. **HorseAnimationView**: 이모지 기반 속도별 시각 피드백 (6단계)
   - 🐴 idle → 🐎 walk → 🏇 trot/run → 🏇💨 gallop → 🏇💨🔥 sprint
   - 속도 텍스트 표시: "대기 중", "걷기", "빠른 걸음", "달리기", "질주", "폭주!"
   - 간소화된 구현으로 성능 최적화 및 유지보수 용이

**삭제된 기능** (2025-12-09):
- ~~SprintEffectView~~: 복잡한 특수 효과 제거
- ~~BackgroundScrollView~~: 배경 스크롤 제거
- ~~바운싱/회전 애니메이션~~: 간소화

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
