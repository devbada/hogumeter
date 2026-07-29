# 호구게이션 발열·전력 최적화 패치 명세

- 작성일: 2026-07-29
- 상태: `READY_FOR_IMPLEMENTATION`
- 범위: iOS 호구게이션 주행 중 발열, 충전 보류, CPU/GPU·위치·네트워크 전력 사용
- 기준 브랜치: 현재 작업 브랜치의 미커밋 호구게이션 변경 포함
- 완료 게이트: `DEVELOPER -> CODE_REVIEWER -> QA -> USER_QA_REQUIRED`

## 1. 결론

충전이 기기 냉각 후 다시 시작됐다면 iOS의 열 보호 충전 제한과 일치한다. Apple은 내부 온도가 높을 때 유선·무선 충전을 늦추거나 중단하며, 더운 차량에서 장시간 GPS 내비게이션을 사용하는 상황을 고온 위험 사례로 안내한다.

현재 코드에는 일반적인 내비게이션 부하 외에 앱 고유의 중복·반복 작업이 존재한다.

1. 호구게이션 GPS와 미터기 GPS가 동시에 연속 실행된다.
2. GPS 이벤트마다 `후보 단속카메라 수 × 전체 경로 선분 수` 계산이 반복된다.
3. 같은 위치의 경로 투영을 ViewModel과 MapView에서 여러 번 계산한다.
4. 3D 지도 카메라·차량·경로 overlay가 높은 빈도로 갱신된다.
5. 움직이는 지도 위 블러 소재와 화면 항상 켜짐이 GPU·디스플레이 전력을 높인다.
6. 시작·재탐색 시 역지오코딩과 단속카메라 네트워크 요청이 추가된다.
7. `ProcessInfo.thermalState`에 따른 단계적 성능 저하 정책이 없다.

Apple 지도 내부 구현은 공개되지 않았다. 따라서 직접적인 내부 구조 비교는 추론이다. 다만 HoguMeter는 MapKit 렌더링 위에 자체 GPS, 미터기, 경로 투영, 단속카메라 탐색, 애니메이션을 추가로 수행하므로 Apple 지도보다 높은 부하가 발생할 구조적 이유가 있다.

## 2. 목표

- 앱이 제어하는 연속 `CLLocationManager`를 주행 중 1개로 제한한다.
- 위치 이벤트당 전체 경로 투영을 1회만 수행하고 결과를 공유한다.
- 단속카메라 판단을 위치 이벤트당 `O(C × P)`에서 `O(log C)` 또는 상수 시간에 가깝게 줄인다.
- 지도 카메라와 overlay 갱신 빈도에 명시적 예산을 둔다.
- `.serious` 이상 thermal state에서 자동으로 저전력 안내 모드로 전환한다.
- 안내 정확도, 요금 계산, 경로 이탈, 차량 snap, 회전 안내를 회귀시키지 않는다.
- 동일 조건 Apple 지도 대비 발열·배터리 차이를 계측 가능한 수준으로 낮춘다.

여기서 `C`는 경로 주변 단속카메라 수, `P`는 경로 polyline 선분 수다.

## 3. 비목표

- 요금 정책 변경
- 경로 탐색 공급자 변경
- Apple 지도와 UI를 동일하게 만드는 작업
- 실측 없이 `desiredAccuracy`만 낮추는 임시 대응
- 발열 경고를 숨기거나 iOS 열 보호 동작을 우회하는 작업

## 4. 현재 원인 근거

### 4.1 위치 파이프라인 중복

`HoguNavigationViewModel.startNavigationFromPreview()`는 자체 `CLLocationManager`를 `distanceFilter = kCLDistanceFilterNone`으로 시작한다.

동시에 `MainMeterView`가 `.hoguNavigationDidStart`를 받으면 `MeterViewModel.startMeter()`를 호출한다. 이 경로는 별도 `LocationService`를 시작한다.

`LocationService` 설정:

- `desiredAccuracy = kCLLocationAccuracyBest`
- `distanceFilter = 10`
- `allowsBackgroundLocationUpdates = true`
- `pausesLocationUpdatesAutomatically = false`
- 1초 신호 손실 타이머

관련 파일:

- `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift`
- `HoguMeter/Presentation/Views/Main/MainMeterView.swift`
- `HoguMeter/Presentation/ViewModels/MeterViewModel.swift`
- `HoguMeter/Domain/Services/LocationService.swift`

### 4.2 단속카메라 전수 계산

`updateSpeedCameraWarning()`은 GPS 이벤트마다 모든 `speedCameraCandidates`를 순회한다. 각 후보마다 사용자와 카메라를 전체 경로에 투영하고, 다시 전체 경로와 거리를 계산한 뒤 전체 결과를 정렬한다.

관련 심볼:

- `HoguNavigationViewModel.updateSpeedCameraWarning()`
- `HoguNavigationViewModel.routeAheadDistance(...)`
- `HoguNavigationRouteProjector.project(...)`

### 4.3 중복 경로 투영과 배열 생성

현재 동일 위치를 다음 경로에서 각각 투영한다.

- 경로 이탈 판정
- 다음 회전 안내
- 단속카메라 판정
- route overlay 분할
- 차량 snap
- 차량 heading fallback
- 카메라 focus 계산

각 호출은 polyline 좌표 배열을 다시 만들고 모든 선분을 순회한다.

### 4.4 지도 렌더링

`HoguNavigationMapView.updateUIView()`에서 다음 작업이 반복된다.

- 58도 pitch 3D camera
- 모든 POI 표시
- 최소 0.25초 간격 camera 변경
- `UIView.animate` 안에서 다시 `mapView.setCamera(..., animated: true)` 실행
- 0.75초 차량 annotation 애니메이션
- 3m 진행마다 overlay 전체 제거·재생성
- 움직이는 지도 위 다수의 `.ultraThinMaterial`

### 4.5 추가 네트워크·디스플레이 부하

- 경로 샘플 최대 8개 역지오코딩
- 지역별 단속카메라 API 요청
- 페이지당 1,000개, 최대 50페이지
- 미터기 지역 감지 10초 간격 역지오코딩
- `MeterViewModel`이 `UIApplication.shared.isIdleTimerDisabled = true` 설정

## 5. 패치 설계

### Phase A — 계측 기준선

제품 동작을 바꾸기 전에 병목별 시간을 측정한다.

#### 추가 항목

- `os_signpost` 구간:
  - location callback 전체
  - route projection
  - route guidance 갱신
  - speed camera 갱신
  - `updateUIView`
  - overlay 재생성
  - camera 갱신
- 위치 이벤트당 카운터:
  - projector 호출 수
  - 평가한 camera 수
  - 평가한 route segment 수
  - overlay 교체 수
  - camera animation 수
- thermal state 변경 로그
- 경로 변경·재탐색 횟수

#### 보안·개인정보

- 원시 좌표, 출발지, 목적지, 도로명, 카메라 ID를 로그에 남기지 않는다.
- 시간, 개수, 소요시간, thermal state만 기록한다.
- 외부 서버로 성능 로그를 전송하지 않는다.

#### 제안 파일

- `HoguMeter/Core/Performance/HoguNavigationPerformanceMonitor.swift`
- `HoguMeterTests/HoguNavigationPerformanceMonitorTests.swift`

### Phase B — 위치 스트림 단일화

#### 목표

주행 중 앱 소유 연속 위치 세션을 1개만 유지한다.

#### 권장 구조

`LocationSessionCoordinator`가 `CLLocationManager` 하나를 소유하고 위치 이벤트를 다음 소비자에게 전달한다.

- 미터 요금 계산
- 호구게이션 안내
- 경로 기록
- 무이동·GPS 신호 감지

소비자는 직접 `startUpdatingLocation()`을 호출하지 않고 세션 요구사항만 등록한다.

```swift
enum LocationConsumer {
    case meter
    case navigation
}

struct LocationDemand {
    let desiredAccuracy: CLLocationAccuracy
    let distanceFilter: CLLocationDistance
    let activityType: CLActivityType
    let needsBackgroundUpdates: Bool
}
```

Coordinator는 활성 소비자 요구사항 중 가장 엄격한 정책을 적용한다. 호구게이션 종료 후 미터도 종료됐다면 즉시 위치 업데이트를 중단한다.

#### 점진적 패치 대안

큰 구조 변경이 위험하면 다음 순서로 적용한다.

1. 검색·출발지 선택 전에는 `HoguNavigationViewModel`이 one-shot `requestLocation()`만 사용한다.
2. 안내 시작 시 자체 연속 manager를 중단한다.
3. `MeterViewModel.locationService.locationPublisher`를 호구게이션에 주입한다.
4. 안내·미터가 동일 `CLLocation` 이벤트를 소비한다.

#### 대상 파일

- `HoguMeter/Domain/Services/LocationService.swift`
- `HoguMeter/Presentation/ViewModels/MeterViewModel.swift`
- `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift`
- `HoguMeter/Presentation/Views/HoguNavigation/HoguNavigationView.swift`

### Phase C — 경로 계산 캐시

#### `RouteProjectionIndex`

경로가 생성되거나 재탐색될 때 한 번 계산한다.

- polyline 좌표
- `MKMapPoint` 배열
- 선분 길이
- 누적 거리
- 선분 heading
- 공간 bucket 또는 최근 진행 segment 주변 검색 범위

GPS 이벤트에서는 이전 segment 주변을 우선 탐색하고 실패할 때만 전체 경로 fallback을 사용한다.

```swift
struct NavigationFrame {
    let location: CLLocation
    let projection: HoguNavigationRouteProjection
    let snappedCoordinate: CLLocationCoordinate2D
    let displayHeading: CLLocationDirection
    let remainingDistance: CLLocationDistance
    let remainingTravelTime: TimeInterval
    let nextGuidance: HoguNavigationRouteStep?
}
```

한 위치 이벤트에서 `NavigationFrame`을 한 번 만들고 ViewModel과 MapView가 공유한다.

#### 성능 예산

- route projection: 위치 이벤트당 기본 1회
- polyline 좌표 복사: 경로 변경당 1회
- route 전체 순회: 정상 주행 위치 이벤트에서 금지
- projector P95: 기준 기기에서 2ms 이하

#### 제안 파일

- `HoguMeter/Domain/Navigation/RouteProjectionIndex.swift`
- `HoguMeter/Domain/Navigation/NavigationFrame.swift`
- `HoguMeterTests/RouteProjectionIndexTests.swift`

### Phase D — 단속카메라 색인

경로 또는 카메라 목록이 변경될 때만 각 카메라를 경로에 투영한다.

```swift
struct ProjectedSpeedCamera {
    let camera: SpeedCamera
    let progressDistance: CLLocationDistance
    let distanceToRoute: CLLocationDistance
}
```

#### 처리 순서

1. `distanceToRoute <= 160m` 카메라만 저장한다.
2. `progressDistance`로 정렬한다.
3. GPS 업데이트 시 사용자 progress 뒤의 첫 후보를 binary search한다.
4. 600m 이내 후보 몇 개만 bearing·속도 제한을 검사한다.
5. 전체 배열 `compactMap + sorted`를 제거한다.

#### 성능 예산

- route 변경 시: `O(C × P)` 허용, main thread 밖에서 실행
- 위치 이벤트 시: `O(log C)` 검색 + 최대 3개 후보 평가
- speed camera 갱신 P95: 5ms 이하
- 동일 경로에서 API 재요청 금지

#### 대상 파일

- `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift`
- `HoguMeter/Domain/Services/SpeedCameraAPIClient.swift`
- `HoguMeterTests/SpeedCameraRouteIndexTests.swift`

### Phase E — 지도 렌더링 예산

#### Camera

- `UIView.animate { setCamera(animated: true) }` 중첩 제거
- `mapView.setCamera(camera, animated: true)` 한 방식만 사용
- 최대 1~2Hz 갱신
- 위치 5m 이상 또는 heading 3도 이상 변화할 때만 갱신
- 실행 중 animation이 있으면 최신 target으로 병합

#### Vehicle

- `NavigationFrame`의 projection·heading 재사용
- 0.75초 고정 animation 대신 위치 이벤트 주기에 맞춘 짧은 animation
- 화면 밖 또는 thermal 제한 모드에서는 animation 제거

#### Overlay

- 3m마다 전체 삭제·재생성 금지
- 최소 10m 또는 1초 간격
- route가 바뀌지 않으면 고정 polyline과 renderer 재사용

#### Map detail

- 기본 POI를 `.excludingAll` 또는 필요한 범주만 표시
- 건물·그림자·pitch의 제품 필요성을 실기기로 비교
- 움직이는 지도 위 `.ultraThinMaterial`을 불투명 또는 단순 반투명 배경으로 교체

#### 대상 파일

- `HoguMeter/Presentation/Views/HoguNavigation/HoguNavigationView.swift`

### Phase F — Thermal 적응 모드

`ProcessInfo.thermalStateDidChangeNotification`을 구독한다.

| Thermal state | 정책 |
|---|---|
| `nominal` | 정상 안내 |
| `fair` | camera 최대 1Hz, overlay 최소 10m |
| `serious` | 2D 또는 낮은 pitch, POI 제거, 블러 제거, camera 최대 0.5~1Hz, 단속카메라 평가 최대 2초 간격 |
| `critical` | 지도 animation·overlay 진행 갱신 중단, 화면 자동 꺼짐 허용, 음성·핵심 안내만 유지 |

복구 시 즉시 최고 품질로 올리지 않고 30초 이상 낮은 thermal state가 유지된 뒤 단계적으로 복구한다.

#### 제안 파일

- `HoguMeter/Domain/Navigation/HoguNavigationEnergyPolicy.swift`
- `HoguMeterTests/HoguNavigationEnergyPolicyTests.swift`

### Phase G — 네트워크·역지오코딩

- route sample reverse geocode를 최대 3개 지역 대표점으로 축소
- 동일 행정구역 중복 geocode 제거
- 동일 경로·지역 API 결과 캐시
- reroute가 같은 지역 안에서 발생하면 전체 카메라 목록 삭제·재다운로드 금지
- 네트워크 실패 시 즉시 반복 요청하지 않고 backoff 적용
- 지역 감지 10초 주기가 실제 요금 정책에 필요한지 검증

## 6. 테스트 전략

### 단위 테스트

- 한 location event가 projection 1회만 생성하는지
- 최근 segment 우선 탐색과 전체 fallback 결과가 동일한지
- speed camera binary search 경계
- reroute 후 camera index 재구축
- thermal state별 camera/overlay/POI/animation 정책
- navigation 시작·종료 후 active location session 수
- 미터 요금과 호구게이션이 동일 location timestamp를 소비하는지

### 성능 테스트

`XCTCPUMetric`, `XCTMemoryMetric`, `XCTClockMetric`을 사용한다.

- 5,000개 route segment
- 1,000개 camera
- 600개 연속 location event
- 기존 구현과 패치 구현 비교

필수 판정:

- 위치 이벤트 CPU 시간 80% 이상 감소 목표
- speed camera 갱신 P95 5ms 이하
- 정상 위치 이벤트에서 전체 route scan 0회
- 메모리 지속 증가 없음

### 실기기 A/B

동일 조건에서 Apple 지도와 HoguMeter를 각각 최소 20분 실행한다.

- 같은 기기·iOS·배터리 상태
- 동일 경로·시간대·네트워크
- 화면 밝기 50% 고정
- 케이스 제거
- 실내 또는 직사광선 없는 22~25°C 환경
- 배터리 상태로 Power trace 수집
- 충전 테스트는 별도 실행

기록 항목:

- 시작·종료 배터리
- 최대 surface temperature
- `thermalState` 변화 시각
- CPU/GPU/Display/Location/Network power
- camera·overlay 갱신 횟수
- 충전 보류 발생 여부

목표:

- 20분 내 `.serious` 또는 `.critical` 미진입
- Apple 지도 대비 표면 온도 차이 `+3°C` 이내
- Apple 지도 대비 배터리 소모 `1.25배` 이내
- 제어된 유선 충전 환경에서 `Charging On Hold` 미발생

환경 편차가 크므로 3회 반복 후 중앙값으로 판정한다.

### TODO-minam — 실기기 정보

- [ ] 기기 모델
- [ ] iOS 버전
- [ ] 앱 build 번호
- [ ] 충전 방식: 유선 / MagSafe / 기타 무선
- [ ] 충전기 출력
- [ ] 케이스 사용 여부
- [ ] 화면 밝기
- [ ] 외기·차량 내부 온도
- [ ] 충전 보류 메시지 정확한 문구와 발생 시각
- [ ] Apple 지도와 HoguMeter 각각 20분 결과

## 7. Instruments 실행 절차

1. 실제 기기에서 Release 또는 성능 측정용 build를 설치한다.
2. Xcode Debug Navigator의 Energy Impact로 1차 확인한다.
3. Instruments에서 다음을 같은 시간축으로 수집한다.
   - Power Profiler 또는 Energy Log
   - Time Profiler
   - Core Animation / Display
   - Network Connections / HTTP Traffic
   - Thermal State
4. 다음 구간에 signpost를 표시한다.
   - 안내 시작
   - 정상 주행
   - 단속카메라 후보 갱신
   - 재탐색
   - thermal state 변경
5. 패치 전후 동일 경로 trace를 비교한다.

주의: 충전 중 Power Profiler의 전체 시스템 전력 값은 측정에 제약이 있다. 전력 trace는 배터리 상태에서 수집하고, 충전 보류 검증은 별도 시나리오로 실행한다.

## 8. 구현 순서와 게이트

1. `THERMAL-01` 계측·기준선
2. `THERMAL-02` 위치 스트림 단일화
3. `THERMAL-03` route projection cache
4. `THERMAL-04` speed camera route index
5. `THERMAL-05` map update budget
6. `THERMAL-06` thermal adaptive mode
7. `THERMAL-07` network/geocode cache
8. Code Review
9. 자동 성능 테스트
10. 실기기 A/B 및 충전 QA

각 단계는 개별 commit과 성능 근거를 가져야 한다. 기능 변경과 최적화를 한 commit에 과도하게 섞지 않는다.

## 9. 롤백

초기 릴리스에서는 다음 feature flag를 둔다.

- `navigationSharedLocationSessionEnabled`
- `navigationRouteIndexEnabled`
- `navigationCameraIndexEnabled`
- `navigationThermalAdaptationEnabled`

문제 발생 시 전체 기능이 아니라 해당 최적화만 비활성화한다. 단, 개인정보 로그와 thermal 보호 로직은 롤백 대상에서 제외한다.

## 10. 완료 조건

- [ ] 주행 중 연속 `CLLocationManager` 1개
- [ ] 위치 이벤트당 route projection 기본 1회
- [ ] speed camera 위치 이벤트 처리 `O(log C)`
- [ ] camera 최대 1~2Hz
- [ ] 중첩 camera animation 제거
- [ ] overlay 갱신 예산 적용
- [ ] `.serious`·`.critical` thermal 정책 적용
- [ ] 단위·성능 테스트 통과
- [ ] Code Review P1/P2 없음
- [ ] 실기기 A/B 목표 충족
- [ ] 유선·무선 충전 보류 시나리오 결과 기록

## 11. Apple 공식 참고자료

- [If your iPhone or iPad gets too hot or too cold](https://support.apple.com/en-asia/118431)
- [Understand Thermally Limited Charging on iPhone](https://support.apple.com/en-ca/guide/iphone/iph3006fbee4/ios)
- [Accessing the device's location efficiently](https://developer.apple.com/documentation/xcode/accessing-the-device-s-location-efficiently)
- [Reduce Location Accuracy and Duration](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/LocationBestPractices.html)
- [Avoid Extraneous Graphics and Animations](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/AvoidExtraneousGraphicsAndAnimations.html)
- [Minimize Timer Use](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/MinimizeTimerUse.html)
- [ProcessInfo.ThermalState.serious](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum/serious)
- [Analyzing your app's battery use](https://developer.apple.com/documentation/xcode/analyzing-your-app-s-battery-use)
- [Measuring your app's power use with Power Profiler](https://developer.apple.com/documentation/xcode/measuring-your-app-s-power-use-with-power-profiler)
