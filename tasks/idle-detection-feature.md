# Idle Detection Feature (무이동 감지 기능)

## 개요

미터기 실행 중 일정 시간(10분) 동안 GPS 이동이 감지되지 않을 경우 사용자에게 알림을 표시하여 계속 진행 또는 종료를 선택할 수 있도록 하는 기능.

## 목적

- 사용자가 미터기를 켜둔 채 잊어버리는 상황 방지
- 불필요한 요금 적산 방지
- 배터리 및 리소스 절약

## 기능 요구사항

### 1. IdleDetectionService

무이동 상태를 감지하는 독립적인 서비스.

#### 설정값 (IdleDetectionConfig)

| 설정 | 값 | 설명 |
|------|-----|------|
| `idleThreshold` | 600초 (10분) | 무이동 판단 기준 시간 |
| `movementThreshold` | 50m | 이동으로 판단하는 최소 거리 |
| `checkInterval` | 30초 | 무이동 체크 주기 |

#### 상태 (IdleDetectionState)

```swift
enum IdleDetectionState {
    case monitoring      // 모니터링 중 (이동 감지됨)
    case idle           // 무이동 상태 감지됨
    case alerted        // 알림 표시됨
    case dismissed      // 알림 해제됨 (사용자가 "계속" 선택)
}
```

#### 주요 메서드

```swift
protocol IdleDetectionServiceProtocol {
    var statePublisher: AnyPublisher<IdleDetectionState, Never> { get }
    var idleDuration: TimeInterval { get }

    func startMonitoring()
    func stopMonitoring()
    func updateLocation(_ location: CLLocation)
    func dismissAlert()  // 사용자가 "계속" 선택 시
    func reset()
}
```

### 2. LocationService 연동

- LocationService에서 위치 업데이트 시 `IdleDetectionService.updateLocation()` 호출
- Dead Reckoning 활성화 상태에서는 무이동 감지 비활성화 (GPS 손실 중이므로)

### 3. 알림 UI

#### 알림 내용

- **제목**: "이동이 감지되지 않습니다"
- **메시지**: "10분 동안 이동이 없습니다. 미터기를 계속 실행하시겠습니까?"
- **버튼**:
  - "계속" - 알림 해제, 모니터링 계속
  - "종료" - 미터기 정지

#### 표시 방식

- SwiftUI Alert 사용
- MeterViewModel에서 상태 관리
- MeterView에서 `.alert()` 모디파이어로 표시

### 4. MeterViewModel 연동

```swift
// MeterViewModel에 추가할 속성
@Published var showIdleAlert: Bool = false

// IdleDetectionService 상태 구독
idleDetectionService.statePublisher
    .sink { [weak self] state in
        if state == .idle {
            self?.showIdleAlert = true
        }
    }
```

## 구현 파일

### 새로 생성

1. `HoguMeter/Domain/Services/IdleDetectionService.swift`
   - IdleDetectionConfig enum
   - IdleDetectionState enum
   - IdleDetectionServiceProtocol
   - IdleDetectionService class

2. `HoguMeterTests/Unit/IdleDetectionServiceTests.swift`
   - 10분 무이동 시 idle 상태 전환 테스트
   - 이동 감지 시 타이머 리셋 테스트
   - dismissAlert 호출 시 다시 모니터링 시작 테스트
   - Dead Reckoning 중 무시 테스트

### 수정

1. `HoguMeter/Presentation/ViewModels/MeterViewModel.swift`
   - IdleDetectionService 의존성 추가
   - showIdleAlert 상태 추가
   - 알림 처리 메서드 추가

2. `HoguMeter/Presentation/Views/MeterView.swift`
   - `.alert()` 모디파이어 추가

## 테스트 시나리오

1. **10분 무이동 감지**
   - 미터기 시작 후 이동 없이 10분 경과 → 알림 표시

2. **이동 시 타이머 리셋**
   - 9분 경과 후 50m 이상 이동 → 타이머 리셋, 알림 없음

3. **"계속" 선택**
   - 알림에서 "계속" 선택 → 알림 해제, 다시 모니터링

4. **"종료" 선택**
   - 알림에서 "종료" 선택 → 미터기 정지

5. **Dead Reckoning 중 무시**
   - GPS 손실로 Dead Reckoning 활성화 → 무이동 감지 일시 중지

## 브랜치

- `feature/idle-detection`
- develop 브랜치 기준 생성

## 완료 조건

- [ ] IdleDetectionService 구현
- [ ] LocationService 연동
- [ ] MeterViewModel 알림 상태 관리
- [ ] MeterView 알림 UI
- [ ] 단위 테스트 통과
- [ ] 빌드 성공
