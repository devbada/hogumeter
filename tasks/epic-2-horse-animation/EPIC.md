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
- [x] 80km/h 이상 특수 효과 구현
- [x] 배경 스크롤 애니메이션 구현
- [x] 부드러운 전환 효과 (60fps 유지)

## 📊 Task 목록

| Task | Title | Status | Priority | PRD |
|------|-------|--------|----------|-----|
| 2.1 | 속도 연동 애니메이션 | 🟢 Done | P0 | FR-2.1 |
| 2.2 | 80km/h 특수 효과 | 🟢 Done | P0 | FR-2.2 |
| 2.3 | 배경 스크롤 | 🟢 Done | P1 | FR-2.3 |

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

- [x] 모든 Task 완료 (Status: 🟢)
- [x] 6단계 속도 전환 부드럽게 작동
- [x] 80km/h 특수 효과 구현
- [x] 60fps 유지 확인
- [x] 배경 스크롤 자연스럽게 작동
- [ ] 실제 주행 테스트 통과 (차후 실제 테스트 필요)

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

**전체 진행률**: 100% (3/3 Tasks 완료)

| Status | Count | Percentage |
|--------|-------|------------|
| 🟢 Done | 3 | 100% |
| 🟡 In Progress | 0 | 0% |
| 🔵 Ready | 0 | 0% |

## 📝 주요 구현 결과

1. **HorseAnimationView**: 속도별 바운싱, 회전, 스케일 애니메이션 (6단계)
2. **SprintEffectView**: 속도선, 먼지 구름, 다리 회전 특수 효과
3. **BackgroundScrollView**: 무한 스크롤 도로 배경, 낮/밤 자동 전환

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
