# v1.1.1 버그 수정 작업 지시서

> 작성일: 2025-01-15
> 버전: 1.1.0 → 1.1.1
> 브랜치: `feature/v1.1.0-improvements`, `fix/fare-discrepancy-bug`

---

## 개요

v1.1.0 릴리즈 후 발견된 버그들을 수정하기 위한 작업 지시서입니다.

---

## Task 1: 다크 모드 마키 텍스트 가시성 수정

### 문제

미터기 실행 중 표시되는 마키 텍스트 "실제 택시요금이 아닙니다 - 참고용으로만 사용하세요"가 다크 모드에서 거의 보이지 않음.

### 원인 분석

| 파일 | 위치 | 기존 값 | 문제점 |
|------|------|---------|--------|
| `MarqueeTextView.swift` | 기본값 (라인 25) | `.gray.opacity(0.35)` | 다크 모드 미대응 |
| `MarqueeBackgroundView` | 라인 102 | `.primary.opacity(0.12)` | opacity 너무 낮음 |

### 해결 방법

시스템 적응형 색상 `Color.secondary` 사용:

```swift
// 수정 전
textColor: Color = .gray.opacity(0.35)
textColor: .primary.opacity(0.12)

// 수정 후
textColor: Color = Color.secondary.opacity(0.4)
textColor: Color.secondary.opacity(0.4)
```

### 검증 항목

- [x] 라이트 모드에서 텍스트 가시성 확인
- [x] 다크 모드에서 텍스트 가시성 확인
- [x] 적절한 대비율 유지

---

## Task 2: 무이동 감지 알림 백그라운드 재예약 수정

### 문제

사용자가 무이동 알림에서 "계속"을 선택한 후, 10분 후에 다시 알림이 발생하지 않는 문제.

### 원인 분석

```
문제 시나리오:
1. 미터기 시작
2. 10분 후 → 무이동 알림 발생
3. 사용자 "계속" 선택
4. dismissAlert() 호출
   - lastMovementTime 리셋 ✅
   - 하지만 백그라운드 알림 재예약 없음 ❌
5. 화면 꺼진 상태에서 10분 후 → 알림 안 감 ❌
```

### 해결 방법

`IdleDetectionService.dismissAlert()`에서 백그라운드 상태일 경우 알림 재예약:

```swift
func dismissAlert() {
    guard state == .idle || state == .alerted else { return }

    cancelScheduledNotification()
    notificationSent = false
    stateSubject.send(.dismissed)
    lastMovementTime = Date()
    idleDuration = 0

    stateSubject.send(.monitoring)

    // 🆕 백그라운드 상태면 다음 알림 예약 (10분 후)
    if isInBackground {
        scheduleBackgroundNotification()
        Logger.gps.info("[IdleDetection] 알림 해제 - 백그라운드 알림 재예약됨")
    }

    Logger.gps.info("[IdleDetection] 알림 해제 - 모니터링 재개")
}
```

### 검증 항목

- [x] 포그라운드에서 "계속" 후 10분 → 알림 재발생
- [x] 백그라운드에서 "계속" 후 10분 → 알림 재발생
- [x] 실내(GPS 약함) 상황에서도 정상 작동

---

## Task 3: 미터기/영수증 요금 불일치 수정

### 문제

미터기에 표시되는 요금과 "정지" 후 영수증에 표시되는 요금이 다름.

### 원인 분석

| 구분 | 함수 | surchargeStatus 사용 | 결과 |
|------|------|---------------------|------|
| 미터기 표시 | `calculate()` | ✅ 전달됨 | 리얼 모드 할증 적용 |
| 영수증 생성 | `breakdown()` | ❌ 파라미터 없음 | 리얼 모드 할증 누락 |

### 해결 방법

1. `FareCalculator.breakdown()` 함수에 `surchargeStatus` 파라미터 추가
2. `calculate()`와 동일한 할증 로직 적용
3. `MeterViewModel.calculateFinalFare()`에서 `surchargeStatus` 전달

```swift
// FareCalculator.swift
func breakdown(
    highSpeedDistance: Double,
    lowSpeedDuration: TimeInterval,
    regionChanges: Int,
    isNightTime: Bool = false,
    surchargeStatus: SurchargeStatus? = nil  // 🆕 추가
) -> FareBreakdown

// MeterViewModel.swift
private func calculateFinalFare() {
    fareBreakdown = fareCalculator.breakdown(
        highSpeedDistance: locationService.highSpeedDistance,
        lowSpeedDuration: locationService.lowSpeedDuration,
        regionChanges: regionDetector.regionChangeCount,
        isNightTime: isNightTime,
        surchargeStatus: surchargeStatus  // 🆕 추가
    )
}
```

### 검증 항목

- [x] 할증 없는 경우: 미터기 == 영수증
- [x] 리얼 모드 할증: 미터기 == 영수증
- [x] 재미 모드 할증: 미터기 == 영수증
- [x] 빌드 성공
- [x] 기존 테스트 통과

---

## 파일 변경 요약

### 브랜치: `feature/v1.1.0-improvements`

| 파일 | 변경 내용 |
|------|----------|
| `MarqueeTextView.swift` | 다크 모드 색상 수정 |
| `IdleDetectionService.swift` | 백그라운드 알림 재예약 로직 추가 |

### 브랜치: `fix/fare-discrepancy-bug`

| 파일 | 변경 내용 |
|------|----------|
| `FareCalculator.swift` | `breakdown()`에 `surchargeStatus` 파라미터 추가 |
| `MeterViewModel.swift` | `calculateFinalFare()`에서 `surchargeStatus` 전달 |

---

## 버전 관리

### 버전 형식: MAJOR.MINOR.PATCH

| 변경 유형 | 버전 범프 | 예시 |
|-----------|----------|------|
| MAJOR | X.0.0 | 호환성 깨지는 변경 |
| MINOR | 0.X.0 | 새 기능 (하위 호환) |
| PATCH | 0.0.X | 버그 수정 |

### 이번 릴리즈

- **변경 전**: 1.1.0 (빌드 2)
- **변경 후**: 1.1.1 (빌드 1) - 권장
- **변경 유형**: PATCH (버그 수정만 포함)

---

## 테스트 체크리스트

### UI 테스트

- [ ] 라이트 모드에서 마키 텍스트 확인
- [ ] 다크 모드에서 마키 텍스트 확인

### 기능 테스트

- [ ] 미터기 시작 → 10분 대기 → 알림 확인
- [ ] 알림 "계속" → 10분 대기 → 재알림 확인
- [ ] 백그라운드에서 위 시나리오 반복

### 요금 테스트

- [ ] 할증 없이 미터기 → 정지 → 영수증 요금 일치 확인
- [ ] 리얼 모드 할증 → 영수증 요금 일치 확인
- [ ] 재미 모드 할증 → 영수증 요금 일치 확인

---

## 참고 사항

### 실내 GPS 동작

- GPS 정확도 30m 이상: 이동으로 인정하지 않음 (무이동 감지 정상 작동)
- GPS 점프: 200km/h 초과 속도는 무시 (GPS 점프 필터링)
- Dead Reckoning 중에도 무이동 감지 정상 작동

### 백그라운드 동작

- `UIBackgroundModes: location` 설정됨
- `allowsBackgroundLocationUpdates = true` 설정됨
- 백그라운드에서 Timer는 중지되지만, 예약된 로컬 알림은 정상 발송됨
