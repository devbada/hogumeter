# HoguMeter 열·자동 잠금 심층 조사 및 수정 지침

## 역할과 목표

당신은 HoguMeter iOS 앱의 전력·열·백그라운드 동작을 검토하는 수석 iOS 엔지니어다. 사용자 경험과 택시 미터의 거리 측정 정확도를 모두 보존하면서 다음을 해결한다.

1. 주행 중 앱을 background 또는 inactive 상태로 보내면 화면 자동 잠금 억제가 남는 문제.
2. 장시간 사용, 특히 background 상태에서 불필요하게 높은 GPS·CPU·GPU 부하가 이어지는 문제.

안전 원칙은 다음과 같다.

- 백그라운드 위치 측정이 제품 요구사항인 경우 이를 무단으로 중지하지 않는다.
- 화면을 켜 두는 정책과 백그라운드 위치 측정 정책은 별개로 취급한다.
- 열 완화는 요금 계산, 주행 기록, 경로 안내의 정확성을 몰래 저하시키면 안 된다.
- 모든 정책 변경은 foreground 복귀·주행 종료·다중 scene 경계에서 원상 복구되어야 한다.

## 확정된 정적 근거

### 자동 잠금

- `MeterViewModel.startMeter()`가 전역 `UIApplication.shared.isIdleTimerDisabled`를 `true`로 설정한다.
- `stopMeter()`와 `resetMeter()`는 `false`로 복구한다.
- `HoguMeterApp`의 `.background` 처리와 `MeterViewModel`의 background 구독은 idle timer를 복구하지 않는다.
- `.active` 복귀 시 실행 중인 미터는 idle timer를 다시 `true`로 설정한다.

따라서 화면 항상 켜짐은 **foreground에서 실행 중일 때만** 허용하고, `.inactive` 및 `.background` 진입 시 반드시 해제해야 한다. 실제 iOS 잠금 시점은 실기기로 검증하지만, 전역 플래그의 생명주기 불일치는 코드상 확정이다.

### 위치·타이머

- `LocationService`는 `kCLLocationAccuracyBest`, `distanceFilter = 10`, background location 허용, 자동 일시정지 비활성화로 시작한다.
- 주행 중에는 1초 GPS 신호 손실 확인 타이머가 실행된다. GPS 손실 상태에서는 Dead Reckoning도 최대 5분 동안 1초 주기로 실행된다.
- 무이동 감지는 30초 주기이며, background 진입 시 로컬 알림을 예약한다.
- 백그라운드 위치 모드가 Info.plist에 선언돼 있다.

주행 중 연속 위치 추적은 의도된 기능이지만, 정차·background에서도 최고 정확도와 자동 일시정지 금지가 유지되는 구조는 장시간 발열의 최우선 원인 후보다.

### 추가 열원

- gallop/rocket 효과는 20Hz Canvas 속도선, 10Hz 파티클, 10Hz 흔들기와 무한 SwiftUI 애니메이션을 중첩한다.
- 최신 develop 1.5.2는 호구게이션을 제거했고, 이번 버그 수정의 출시 대상은 1.5.3이다. 이 조사와 수정에서는 해당 기능·소스·UI·설정을 복구하지 않는다.

## 이번 수정의 최소 범위

1. `HoguMeterApp`: `.inactive`와 `.background`에서 idle timer를 명시적으로 해제한다.
2. `MeterViewModel`: lifecycle 이벤트에 맞춰 위치 서비스의 foreground/background 에너지 정책을 호출한다. `.active`이며 미터가 running일 때만 화면 항상 켜짐을 재설정한다.
3. `LocationService`: background에서는 위치 추적 정확도와 10m 필터를 유지하되, 정차 시 자동 일시정지를 허용한다. foreground로 돌아오면 자동 일시정지 비활성 정책으로 복구한다. 신호 손실 확인 timer는 background에서 15초, foreground에서 1초로 조절한다. 주행 종료 뒤에는 background location execution을 해제한다.
4. `IdleDetectionService`: background에서 이미 예약한 로컬 알림을 사용하고 30초 반복 timer는 중지한다. foreground 복귀 시 monitoring/alerted 상태에서 재개한다.

## 반드시 검증할 회귀 조건

- 미터 off에서는 Auto-Lock 시간이 지나면 화면이 잠긴다.
- 미터 running + foreground에서만 화면이 유지된다.
- running 상태에서 Home/앱 전환/잠금 시 idle timer가 즉시 해제된다.
- background 주행 중 위치 추적이 유지되고, foreground 복귀 뒤 고정밀 정책으로 돌아온다.
- stop/reset 뒤에도 idle timer와 위치 추적이 남지 않는다.
- 30분 실기기 Release trace에서 Energy Log, Time Profiler, Core Animation, thermal state, CPU wakeup을 기록한다.

## 후속 개선 후보

- Low Power Mode 및 thermal state에 메인 말 애니메이션의 FPS/효과 수를 연결한다.
- 장거리 RouteManager 단순화와 지도 overlay를 background/배치 방식으로 전환한다.
- production에서 개인 위치를 남기지 않는 MetricKit 기반 에너지·thermal 집계를 추가한다.
