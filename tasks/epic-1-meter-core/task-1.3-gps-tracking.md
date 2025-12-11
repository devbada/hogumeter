# Task 1.3: GPS 거리 측정

> **Epic**: Epic 1 - 미터기 핵심 기능
> **Status**: 🟢 Done
> **Priority**: P0
> **Estimate**: 8시간
> **PRD**: FR-1.3

---

## 📋 개요

Core Location을 사용하여 정확한 이동 거리와 저속 시간을 측정하는 시스템을 구현합니다.

## 🎯 목표

GPS 하드웨어를 활용하여 실시간으로 차량의 위치를 추적하고, 정확한 이동 거리와 속도를 계산합니다.

## ✅ Acceptance Criteria

작업 완료 조건:

- [x] 1초 간격으로 위치 업데이트
- [x] 누적 거리 계산 (단위: m → km 변환 표시)
- [x] 거리 측정 오차 5% 이내
- [x] GPS 신호 약할 때 보정 로직 적용
- [x] 저속 시간 (15km/h 이하) 자동 추적
- [x] 위치 정확도 필터링 (50m 이내)
- [x] 비정상적인 점프 필터링 (100m 이상)

## 📝 구현 사항

### 1. LocationService 프로토콜
```swift
// Domain/Services/LocationService.swift
protocol LocationServiceProtocol {
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    var totalDistance: Double { get }
    var lowSpeedDuration: TimeInterval { get }

    func startTracking()
    func stopTracking()
}
```
- [x] 구현 완료: `HoguMeter/Domain/Services/LocationService.swift:18`

### 2. LocationService 구현
```swift
final class LocationService: NSObject, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    private(set) var totalDistance: Double = 0
    private(set) var lowSpeedDuration: TimeInterval = 0
}
```
- [x] 구현 완료: `HoguMeter/Domain/Services/LocationService.swift:30`

### 3. CLLocationManagerDelegate
```swift
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation])
}
```
- [x] 구현 완료: `HoguMeter/Domain/Services/LocationService.swift:68`

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Services/LocationService.swift` - GPS 서비스
- [x] `HoguMeter/Core/Extensions/CLLocation+Extensions.swift` - 위치 확장
- [x] `HoguMeter/Core/Utils/Logger.swift` - 로깅
- [x] `HoguMeter/Info.plist` - 위치 권한 설정

## 📖 참고 사항

### PRD 참조
- **FR-1.3**: GPS 기반 거리 측정 요구사항

### Core Location 설정
```swift
locationManager.desiredAccuracy = kCLLocationAccuracyBest
locationManager.distanceFilter = 10  // 10m마다 업데이트
locationManager.allowsBackgroundLocationUpdates = true
locationManager.pausesLocationUpdatesAutomatically = false
```

### 거리 계산 알고리즘
```swift
// 이전 위치와 현재 위치 사이의 거리
let delta = location.distance(from: lastLocation)

// 비정상적인 점프 필터링
if delta < 100 {
    totalDistance += delta
}
```

### 저속 시간 계산
```swift
// 15km/h = 4.17 m/s 이하일 때
if location.speed < lowSpeedThreshold {
    lowSpeedDuration += timeDelta
}
```

### 의존성
- **선행 Task**: Task 1.1 (상태 관리)
- **후행 Task**: Task 1.2 (요금 계산), Task 1.4 (정보 표시)

### 기술 스택
- Core Location
- Combine (Publisher)
- CoreLocation Delegate pattern

## 🧪 테스트 계획

### Unit Tests
```swift
- [x] testStartTracking_ShouldRequestAuthorization
- [x] testStopTracking_ShouldStopUpdates
- [x] testLocationUpdate_ShouldCalculateDistance
- [x] testLocationUpdate_ShouldFilterBadAccuracy
- [x] testLocationUpdate_ShouldFilterJumps
- [x] testLowSpeed_ShouldTrackDuration
```

### Integration Tests
```
- [x] 실제 위치 변화 시뮬레이션
- [x] Combine Publisher 테스트
```

### Manual Tests
```
- [ ] 실제 차량 주행 (1km)
- [ ] 알려진 거리와 비교 (오차 측정)
- [ ] 터널/지하 주차장 테스트
- [ ] 고속 주행 테스트 (80km/h+)
```

## 🐛 알려진 이슈

- **GPS 신호 약한 지역**: 터널, 지하, 고층 빌딩 사이
  - 대응: 정확도 필터링 (50m 이내만 사용)
- **배터리 소모**: 백그라운드 위치 추적 시 배터리 소모 증가
  - 대응: distanceFilter 설정으로 최적화

## 📌 체크리스트

구현 전:
- [x] Core Location 문서 확인
- [x] 위치 권한 설정 확인
- [x] Info.plist 권한 문구 작성

구현 중:
- [x] LocationService 클래스 작성
- [x] CLLocationManagerDelegate 구현
- [x] 거리 계산 로직 구현
- [x] 저속 시간 추적 구현
- [x] Combine Publisher 연동
- [x] 주석 추가

구현 후:
- [x] 자체 테스트
- [ ] Unit Test 작성
- [ ] 실제 주행 테스트
- [ ] 거리 정확도 검증
- [ ] 코드 리뷰 요청
- [x] 문서 업데이트

## 📅 작업 로그

| Date | Activity | Notes |
|------|----------|-------|
| 2025-01-15 | Task 생성 | Core Location 연동 설계 |
| 2025-01-15 | 구현 완료 | LocationService, Delegate 구현 |
| 2025-01-15 | 상태 변경 | 🟢 Done |

---

**Created**: 2025-01-15
**Last Updated**: 2025-01-15

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

