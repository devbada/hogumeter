# Task 4.1: 영수증 생성

> **Epic**: Epic 4 - 영수증/공유
> **Status**: 🔵 Ready
> **Priority**: P1
> **PRD**: FR-4.1

---

## 📋 개요

주행 완료 후 상세 영수증을 생성하여 표시합니다.

## ✅ Acceptance Criteria

- [ ] 앱 로고 및 이름
- [ ] 날짜 및 시간 (시작 → 종료)
- [ ] 요금 상세 내역
  - 기본요금
  - 거리요금 (거리 표시)
  - 시간요금
  - 지역할증 (횟수 표시)
  - 야간할증
- [ ] 총 요금
- [ ] 슬로건 ("내 차 탔으면 내놔")

## 📝 구현 사항

### 1. ReceiptView UI
```swift
// Presentation/Views/Receipt/ReceiptView.swift
struct ReceiptView: View {
    let trip: Trip
}
```

---

**Created**: 2025-01-15
