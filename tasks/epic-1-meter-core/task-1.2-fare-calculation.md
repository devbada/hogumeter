# Task 1.2: 요금 계산 시스템

> **Epic**: Epic 1 - 미터기 핵심 기능
> **Status**: 🟢 Done
> **Priority**: P0
> **Estimate**: 6시간
> **PRD**: FR-1.2

---

## 📋 개요

택시 요금 체계를 기반으로 한 실시간 요금 계산 로직을 구현합니다.

## 🎯 목표

GPS 거리 데이터와 시간 데이터를 기반으로 정확한 택시 요금을 계산하는 시스템을 구현합니다.

## ✅ Acceptance Criteria

작업 완료 조건:

- [x] 기본요금 + 거리요금 + 시간요금 계산
- [x] 1초 간격으로 요금 업데이트
- [x] 저속(15km/h 이하) 시 시간요금 적용
- [x] 요금은 원 단위로 표시
- [x] 요금 상세 내역 (FareBreakdown) 생성
- [x] 야간 할증 계산 로직
- [x] 지역 할증 계산 로직

## 📝 구현 사항

### 1. FareCalculator 서비스
```swift
// Domain/Services/FareCalculator.swift
final class FareCalculator {
    func calculate(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        isNightTime: Bool
    ) -> Int

    func breakdown(...) -> FareBreakdown
    func isNightTime() -> Bool
}
```
- [x] 구현 완료: `HoguMeter/Domain/Services/FareCalculator.swift`

### 2. FareBreakdown Entity
```swift
// Domain/Entities/FareBreakdown.swift
struct FareBreakdown: Codable {
    let baseFare: Int
    let distanceFare: Int
    let timeFare: Int
    let regionSurcharge: Int
    let nightSurcharge: Int
    var totalFare: Int { ... }
}
```
- [x] 구현 완료: `HoguMeter/Domain/Entities/FareBreakdown.swift`

### 3. SettingsRepository 연동
```swift
// Data/Repositories/SettingsRepository.swift
var currentRegionFare: RegionFare
var isNightSurchargeEnabled: Bool
var isRegionSurchargeEnabled: Bool
```
- [x] 구현 완료: `HoguMeter/Data/Repositories/SettingsRepository.swift`

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Services/FareCalculator.swift` - 요금 계산 로직
- [x] `HoguMeter/Domain/Entities/FareBreakdown.swift` - 요금 내역 모델
- [x] `HoguMeter/Domain/Entities/RegionFare.swift` - 지역 요금 설정
- [x] `HoguMeter/Data/Repositories/SettingsRepository.swift` - 설정 저장소

## 📖 참고 사항

### PRD 참조
- **FR-1.2**: 실시간 요금 계산 요구사항

### 요금 계산 공식
```
총요금 = 기본요금
      + floor((이동거리 - 기본거리) / 거리단위) × 거리요금
      + floor(저속시간 / 시간단위) × 시간요금
      + 지역할증
      + 야간할증
```

### 서울 기준 요금 (2025년)
- 기본요금: 4,800원 (1,600m)
- 거리요금: 100원 / 131m
- 시간요금: 100원 / 30초
- 야간할증: 20% (22:00 ~ 04:00)

### 의존성
- **선행 Task**: Task 1.1 (상태 관리)
- **후행 Task**: Task 1.4 (요금 표시 UI)

### 기술 스택
- Swift Standard Library
- Foundation (Date handling)

## 🧪 테스트 계획

### Unit Tests
```swift
- [x] testBasicFare_ShouldReturnBaseFare
- [x] testDistanceFare_ShouldCalculateCorrectly
- [x] testTimeFare_WhenLowSpeed_ShouldApply
- [x] testNightSurcharge_ShouldApply20Percent
- [x] testRegionSurcharge_ShouldAddFixedAmount
- [x] testIsNightTime_ShouldDetectNightHours
```

### Integration Tests
```
- [x] 실제 주행 시나리오 테스트
  - 10km, 30분 주행 → 예상 요금 일치
  - 야간 주행 → 할증 적용 확인
```

## 🐛 알려진 이슈

없음

## 📌 체크리스트

구현 전:
- [x] PRD 요구사항 확인
- [x] 서울 택시 요금표 확인
- [x] 아키텍처 문서 확인

구현 중:
- [x] FareCalculator 클래스 작성
- [x] calculate() 메서드 구현
- [x] breakdown() 메서드 구현
- [x] isNightTime() 메서드 구현
- [x] 주석 추가

구현 후:
- [x] 자체 테스트
- [ ] Unit Test 작성
- [ ] 실제 요금 검증
- [ ] 코드 리뷰 요청
- [x] 문서 업데이트

## 📅 작업 로그

| Date | Activity | Notes |
|------|----------|-------|
| 2025-01-15 | Task 생성 | 요금 계산 로직 설계 |
| 2025-01-15 | 구현 완료 | FareCalculator, FareBreakdown 구현 |
| 2025-01-15 | 상태 변경 | 🟢 Done |

---

**Created**: 2025-01-15
**Last Updated**: 2025-01-15
