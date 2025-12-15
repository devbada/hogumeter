# Task 8.8: 자동 줌 (Auto Zoom)

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.8 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P2 (선택) |
| 상태 | 🔲 대기 |
| 의존성 | TASK-8.1, TASK-8.6 |

---

## 🎯 목표

속도와 상황에 따라 지도 줌 레벨을 자동으로 조절하여 최적의 시야를 제공한다.
- 고속 주행 시: 넓은 시야 (줌 아웃)
- 저속/정차 시: 상세한 시야 (줌 인)

---

## 📝 구현 내용

### 1. 속도-줌 레벨 매핑 설정

```swift
// Domain/Entities/AutoZoomLevel.swift

import MapKit

/// 자동 줌 레벨 설정
enum AutoZoomLevel: CaseIterable {
    case stationary     // 정차 (0-5 km/h)
    case slow           // 서행 (5-20 km/h)
    case city           // 시내 (20-40 km/h)
    case suburban       // 외곽 (40-60 km/h)
    case highway        // 간선도로 (60-80 km/h)
    case expressway     // 고속도로 (80+ km/h)

    /// 속도 범위 (km/h)
    var speedRange: ClosedRange<Double> {
        switch self {
        case .stationary:  return 0...5
        case .slow:        return 5...20
        case .city:        return 20...40
        case .suburban:    return 40...60
        case .highway:     return 60...80
        case .expressway:  return 80...200
        }
    }

    /// 지도 축척 (latitudeDelta)
    var span: MKCoordinateSpan {
        switch self {
        case .stationary:  return MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)   // ~300m
        case .slow:        return MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)   // ~500m
        case .city:        return MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)   // ~800m
        case .suburban:    return MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)   // ~1.2km
        case .highway:     return MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)   // ~1.8km
        case .expressway:  return MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)   // ~2.5km
        }
    }

    /// 속도로부터 줌 레벨 결정
    static func from(speed: Double) -> AutoZoomLevel {
        for level in AutoZoomLevel.allCases {
            if level.speedRange.contains(speed) {
                return level
            }
        }
        return .expressway
    }
}
```

### 2. AutoZoomManager 구현

```swift
// Domain/Services/AutoZoomManager.swift

import Foundation
import MapKit
import Combine

@MainActor
class AutoZoomManager: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var currentZoomLevel: AutoZoomLevel = .stationary
    @Published private(set) var targetSpan: MKCoordinateSpan = AutoZoomLevel.stationary.span
    @Published var isAutoZoomEnabled: Bool = true

    // MARK: - Private Properties
    private var lastManualInteractionTime: Date?
    private let manualOverrideDuration: TimeInterval = 5.0  // 수동 조작 후 5초간 자동 줌 비활성화

    // 급격한 변화 방지를 위한 히스테리시스 (km/h)
    private let hysteresis: Double = 3.0

    // MARK: - Public Methods

    /// 속도에 따른 줌 레벨 업데이트
    func updateZoom(for speed: Double) {
        guard isAutoZoomEnabled else { return }
        guard !isManualOverrideActive else { return }

        let newLevel = calculateZoomLevel(for: speed)

        if newLevel != currentZoomLevel {
            currentZoomLevel = newLevel
            targetSpan = newLevel.span
        }
    }

    /// 사용자 수동 조작 감지
    func userDidInteract() {
        lastManualInteractionTime = Date()
    }

    /// 수동 조작 오버라이드가 활성화되어 있는지
    var isManualOverrideActive: Bool {
        guard let lastInteraction = lastManualInteractionTime else { return false }
        return Date().timeIntervalSince(lastInteraction) < manualOverrideDuration
    }

    /// 자동 줌 토글
    func toggleAutoZoom() {
        isAutoZoomEnabled.toggle()
    }

    // MARK: - Private Methods

    /// 히스테리시스를 적용한 줌 레벨 계산
    private func calculateZoomLevel(for speed: Double) -> AutoZoomLevel {
        let newLevel = AutoZoomLevel.from(speed: speed)

        // 히스테리시스: 경계 근처에서 잦은 변경 방지
        if newLevel != currentZoomLevel {
            let currentRange = currentZoomLevel.speedRange
            let threshold = hysteresis

            // 현재 레벨의 범위 안에서 threshold 이내면 유지
            if speed >= currentRange.lowerBound - threshold &&
               speed <= currentRange.upperBound + threshold {
                return currentZoomLevel
            }
        }

        return newLevel
    }
}
```

### 3. MapViewModel 수정

```swift
// Presentation/ViewModels/MapViewModel.swift

import Foundation
import MapKit
import Combine

@MainActor
class MapViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var region: MKCoordinateRegion
    @Published var shouldUpdateRegion = false
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentHeading: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var isTrackingEnabled = true

    // MARK: - Auto Zoom
    private let autoZoomManager = AutoZoomManager()

    var isAutoZoomEnabled: Bool {
        get { autoZoomManager.isAutoZoomEnabled }
        set { autoZoomManager.isAutoZoomEnabled = newValue }
    }

    // MARK: - Dependencies
    private let locationService: LocationServiceProtocol
    private let routeManager: RouteManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    // MARK: - Route Properties
    var routeCoordinates: [CLLocationCoordinate2D] {
        routeManager.coordinates
    }

    var startLocation: CLLocationCoordinate2D? {
        routeManager.startLocation
    }

    // MARK: - Init
    init(locationService: LocationServiceProtocol, routeManager: RouteManager) {
        self.locationService = locationService
        self.routeManager = routeManager

        let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        self.region = MKCoordinateRegion(center: defaultCoordinate, span: defaultSpan)

        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)

        // 자동 줌 레벨 변경 감지
        autoZoomManager.$targetSpan
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSpan in
                self?.applyAutoZoom(span: newSpan)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods
    private func updateLocation(_ location: CLLocation) {
        currentLocation = location.coordinate
        currentHeading = location.course >= 0 ? location.course : currentHeading
        currentSpeed = max(0, location.speed * 3.6)

        // 자동 줌 업데이트
        autoZoomManager.updateZoom(for: currentSpeed)

        // 추적 모드일 때만 지도 중심 업데이트
        if isTrackingEnabled {
            region = MKCoordinateRegion(center: location.coordinate, span: region.span)
            shouldUpdateRegion = true
        }
    }

    private func applyAutoZoom(span: MKCoordinateSpan) {
        guard isTrackingEnabled else { return }
        guard autoZoomManager.isAutoZoomEnabled else { return }

        // 부드러운 전환을 위해 현재 위치 유지하며 span만 변경
        region = MKCoordinateRegion(center: region.center, span: span)
        shouldUpdateRegion = true
    }

    // MARK: - Public Methods
    func centerOnCurrentLocation() {
        guard let location = currentLocation else { return }
        region = MKCoordinateRegion(center: location, span: defaultSpan)
        shouldUpdateRegion = true
        isTrackingEnabled = true
    }

    func initializeMapCenter() {
        if let location = currentLocation {
            region = MKCoordinateRegion(center: location, span: defaultSpan)
            shouldUpdateRegion = true
        }
    }

    func disableTracking() {
        isTrackingEnabled = false
    }

    /// 사용자가 지도를 직접 조작했음을 알림
    func userDidInteractWithMap() {
        autoZoomManager.userDidInteract()
    }

    /// 자동 줌 토글
    func toggleAutoZoom() {
        autoZoomManager.toggleAutoZoom()
    }
}
```

### 4. MapViewRepresentable 수정 (제스처 감지)

```swift
// Presentation/Views/Map/MapViewRepresentable.swift - Coordinator 수정

class Coordinator: NSObject, MKMapViewDelegate {
    var parent: MapViewRepresentable

    init(_ parent: MapViewRepresentable) {
        self.parent = parent
    }

    // 사용자 제스처 감지
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // 사용자 제스처로 인한 변경인지 확인
        if let gestureRecognizers = mapView.subviews.first?.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer.state == .began || recognizer.state == .changed {
                    parent.viewModel.userDidInteractWithMap()
                    parent.viewModel.disableTracking()
                    break
                }
            }
        }
    }

    // ... 기존 delegate 메서드들 ...
}
```

### 5. 자동 줌 토글 버튼 (MapContainerView)

```swift
// Presentation/Views/Map/MapContainerView.swift - 버튼 추가

// MARK: - Auto Zoom Button
private var autoZoomButton: some View {
    Button(action: {
        mapViewModel.toggleAutoZoom()
    }) {
        Image(systemName: mapViewModel.isAutoZoomEnabled ? "scope" : "scope")
            .font(.system(size: 20))
            .foregroundColor(mapViewModel.isAutoZoomEnabled ? .blue : .gray)
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                // 비활성화 시 취소선 표시
                mapViewModel.isAutoZoomEnabled ? nil :
                    Image(systemName: "line.diagonal")
                        .font(.system(size: 24))
                        .foregroundColor(.red.opacity(0.8))
            )
    }
}

// 우측 컨트롤에 추가
HStack {
    Spacer()
    VStack(spacing: 12) {
        autoZoomButton      // 자동 줌 버튼 추가
        currentLocationButton
    }
    .padding(.trailing, 16)
}
```

---

## ✅ 수락 기준

- [ ] 정차/저속 시 상세한 줌 레벨 (300-500m 축척)
- [ ] 고속도로 주행 시 넓은 줌 레벨 (2-2.5km 축척)
- [ ] 속도 변화에 따른 부드러운 줌 전환
- [ ] 사용자 수동 조작 시 자동 줌 일시 중지 (5초)
- [ ] 자동 줌 ON/OFF 토글 버튼
- [ ] 히스테리시스 적용으로 잦은 줌 변경 방지

---

## 📁 수정/생성할 파일

```
HoguMeter/
├── Domain/
│   ├── Entities/
│   │   └── AutoZoomLevel.swift           # 새로 생성
│   └── Services/
│       └── AutoZoomManager.swift         # 새로 생성
├── Presentation/
│   ├── ViewModels/
│   │   └── MapViewModel.swift            # 수정
│   └── Views/
│       └── Map/
│           ├── MapContainerView.swift    # 수정 (버튼 추가)
│           └── MapViewRepresentable.swift # 수정 (제스처 감지)
```

---

## 🔧 구현 옵션

### 옵션 A: 기본 구현 (권장)
- 속도 기반 줌만 적용
- 히스테리시스 적용
- 수동 조작 시 일시 중지

### 옵션 B: 고급 구현
- 속도 + 도로 유형 기반 (MapKit 도로 정보 활용)
- 다음 교차로까지 거리 고려 (네비게이션 연동 필요)
- 기울기(pitch) 자동 조절 추가

---

## 🧪 테스트

### 단위 테스트
1. `AutoZoomLevel.from(speed:)` 속도별 레벨 반환 확인
2. 히스테리시스 경계값 테스트
3. 수동 오버라이드 타이머 테스트

### 통합 테스트 (시뮬레이터)
1. GPX 파일로 속도 변화 시뮬레이션
2. 줌 레벨 변화 확인
3. 수동 줌 조작 후 자동 복귀 확인

### 실기기 테스트
1. 실제 주행 중 줌 레벨 변화 확인
2. 고속도로 진입/이탈 시 줌 변화
3. 배터리 소모 측정

---

## 📎 참고

### 타 앱 자동 줌 구현 방식

| 앱 | 속도 기반 | 안내 지점 기반 | 사용자 설정 |
|----|----------|---------------|------------|
| Google Maps | O | O (0.25mi 전 줌인) | X |
| Apple Maps | O | O | X |
| OsmAnd | O | O | O (3단계) |
| MyRouteApp | O | O | O (4가지 모드) |
| 카카오내비 | O | O | X |

### 관련 리소스
- [Google Design - Prototyping a Smoother Map](https://medium.com/google-design/google-maps-cb0326d165f5)
- [MKZoomLevel Library](https://github.com/stleamist/MKZoomLevel)
- [OsmAnd Auto Zoom Settings](https://groups.google.com/g/osmand/c/ezgiZTXpTGw)

---

## ⚠️ 주의사항

1. **배터리 최적화**: 줌 변경 시 불필요한 타일 로딩 방지
2. **멀미 방지**: 너무 잦은 줌 변경은 사용자 피로감 유발
3. **사용자 컨트롤**: 자동 줌 비활성화 옵션 필수 제공
