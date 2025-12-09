# Epic 6: 주행 기록 (Trip History)

> **Priority**: P2 (Could Have)
> **Status**: 🟢 Done
> **Target**: Week 4
> **PRD Reference**: Epic 6 (FR-6.1 ~ FR-6.2)

---

## 📋 Epic 개요

완료된 주행 기록을 저장하고 조회할 수 있는 기능을 구현합니다.

## 🎯 Epic 목표

- [x] TripRepository 구현 (UserDefaults 기반)
- [x] 주행 기록 저장/조회/삭제 기능
- [x] 주행 기록 UI 구현
- [x] 스와이프 삭제 기능
- [x] 영수증 재공유 기능

## 📊 Task 목록

| Task | Title | Status | Priority | PRD |
|------|-------|--------|----------|-----|
| 6.1 | 주행 기록 저장 | 🟢 Done | P2 | FR-6.1 |
| 6.2 | 주행 기록 조회 | 🟢 Done | P2 | FR-6.2 |

## 📊 진행 상황

**전체 진행률**: 100% (2/2 Tasks 완료)

## 📝 주요 구현 결과

- **TripRepository**: UserDefaults + Codable 기반 저장소 (최대 100건)
- **TripHistoryView**: 주행 기록 목록 (최신순, 스와이프 삭제)
- **TripDetailView**: 상세 정보 + 영수증 공유 + 삭제 기능
- **TripRowView**: 요약 정보 (날짜, 요금, 거리, 지역)

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
