# Task 3.3: 지역 변경 할증

> **Epic**: Epic 3 - 요금 설정
> **Status**: 🟢 Done
> **Priority**: P1
> **PRD**: FR-3.3

---

## 📋 개요

지역 경계를 넘을 때 할증 요금을 적용하는 시스템을 구현합니다.

## ✅ Acceptance Criteria

- [x] GPS 기반 현재 지역 감지 (Reverse Geocoding)
- [x] 지역 변경 시 고정 할증금액 추가
- [x] 변경 횟수 기록
- [x] RegionDetector 서비스 구현

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Services/RegionDetector.swift`
- [x] `HoguMeter/Domain/Services/FareCalculator.swift`

---

## 📝 구현 노트

### 주요 구현 내용

1. **RegionDetector 서비스** (HoguMeter/Domain/Services/RegionDetector.swift:12-72)
   - CLGeocoder를 사용한 역지오코딩
   - 10초 throttling으로 API 호출 최적화
   - 지역 변경 횟수 자동 추적

2. **상세 주소 표시** (개선: 2025-12-10)
   - 기존: "서울특별시 서울특별시" (중복 문제)
   - 개선: "서울특별시 영등포구" (상세 주소)
   - `administrativeArea` (시/도) + `subLocality` (구/군) 조합
   - locality와 administrativeArea 중복 방지 로직 추가

3. **지역 변경 감지**
   - 이전 지역과 현재 지역 비교
   - 변경 시 regionChangeCount 증가
   - FareCalculator에서 할증금 계산

4. **성능 최적화**
   - isGeocoding 플래그로 동시 호출 방지
   - lastGeocodingTime으로 10초 간격 유지
   - weak self로 메모리 누수 방지

### 기술 스택
- CoreLocation CLGeocoder
- CLPlacemark 주소 정보
- DispatchQueue 비동기 처리

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
**Last Updated**: 2025-12-10 (상세 주소 개선)

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

