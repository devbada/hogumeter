# Epic 3: 요금 설정 시스템 (Fare Settings)

> **Priority**: P1 (Should Have)
> **Status**: 🟢 Done
> **Target**: Week 2
> **PRD Reference**: Epic 3 (FR-3.1 ~ FR-3.3)

---

## 📋 Epic 개요

사용자가 지역별 택시 요금을 설정하고, 야간/지역 할증을 관리할 수 있는 시스템을 구현합니다.

## 🎯 Epic 목표

- [x] 지역별 요금 관리 시스템 구현
- [x] 야간 할증 자동 적용 시스템 구현
- [x] 지역 변경 할증 시스템 구현

## 📊 Task 목록

| Task | Title | Status | Priority | PRD |
|------|-------|--------|----------|-----|
| 3.1 | 지역별 요금 관리 | 🟢 Done | P1 | FR-3.1 |
| 3.2 | 야간 할증 자동 적용 | 🟢 Done | P1 | FR-3.2 |
| 3.3 | 지역 변경 할증 | 🟢 Done | P1 | FR-3.3 |

## 📊 진행 상황

**전체 진행률**: 100% (3/3 Tasks 완료)

| Status | Count | Percentage |
|--------|-------|------------|
| 🟢 Done | 3 | 100% |
| 🟡 In Progress | 0 | 0% |
| 🔵 Ready | 0 | 0% |

## 📝 주요 구현 결과

1. **RegionFare**: 지역별 요금 정보 모델 (서울, 경기, 인천)
2. **RegionFareRepository**: 지역 요금 데이터 관리 (DefaultFares.json)
3. **FareCalculator**: 야간 할증 자동 적용 (22:00-04:00, 20% 할증)
4. **RegionDetector**: 지역 변경 감지 및 할증 적용 (상세 주소 표시)

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
**Last Updated**: 2025-12-10
