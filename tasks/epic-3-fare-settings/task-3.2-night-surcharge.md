# Task 3.2: 야간 할증 자동 적용

> **Epic**: Epic 3 - 요금 설정
> **Status**: 🟢 Done
> **Priority**: P1
> **PRD**: FR-3.2

---

## 📋 개요

설정된 시간대에 자동으로 야간 할증을 적용하는 시스템을 구현합니다.

## ✅ Acceptance Criteria

- [x] 야간 시간대 진입 시 자동 감지
- [x] 거리요금 × 야간할증배율 적용
- [x] 시간요금 × 야간할증배율 적용
- [x] FareCalculator.isNightTime() 구현

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Services/FareCalculator.swift`
- [x] `HoguMeter/Data/Repositories/SettingsRepository.swift`

---

**Created**: 2025-01-15

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

