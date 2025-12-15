# Task 8.3: GPS 경로 폴리라인

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.3 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P0 |
| 상태 | 🔲 대기 |
| 의존성 | TASK-8.1 |

---

## 🎯 목표

미터기 시작부터 현재까지의 이동 경로를 지도에 폴리라인(선)으로 표시한다. 출발 지점에 시작 마커를 표시하고, 실시간으로 경로를 업데이트한다.

---

## 📝 구현 내용

### 1. RoutePoint 엔티티 정의

```swift
// Domain/Entities/RoutePoint.swift

import Foundation
import CoreLocation

struct RoutePoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double       // km/h
    let accuracy: Double    // meters

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = max(0, location.speed * 3.6)
        self.accuracy = location.horizontalAccuracy
    }
}
```

### 2. RouteManager 서비스 구현

```swift
// Domain/Services/RouteManager.swift

import Foundation
import CoreLocation
import Combine

class RouteManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var routePoints: [RoutePoint] = []
    @Published private(set) var startLocation: CLLocationCoordinate2D?

    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private let minimumDistance: Double = 5.0 // 최소 5m 이동 시에만 포인트 추가

    // MARK: - Methods
    func startNewRoute(at location: CLLocation) {
        routePoints = []
        startLocation = location.coordinate
        addPoint(location)
    }

    func addPoint(_ location: CLLocation) {
        let newPoint = RoutePoint(location: location)

        // 이전 포인트와 거리 체크
        if let lastPoint = routePoints.last {
            let lastLocation = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
            let distance = location.distance(from: lastLocation)

            // 최소 거리 이상 이동했을 때만 추가
            guard distance >= minimumDistance else { return }
        }

        routePoints.append(newPoint)
    }

    func clearRoute() {
        routePoints = []
        startLocation = nil
    }

    var coordinates: [CLLocationCoordinate2D] {
        routePoints.map { $0.coordinate }
    }
}
```

### 3. 출발 마커 Annotation

```swift
// Domain/Entities/StartPointAnnotation.swift

import MapKit

class StartPointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String? = "출발"

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}
```

### 4. MapViewRepresentable에 폴리라인 추가

```swift
// MapViewRepresentable.swift 업데이트

func updateUIView(_ mapView: MKMapView, context: Context) {
    // 기존 코드...

    // 폴리라인 업데이트
    updatePolyline(mapView)

    // 출발 마커 업데이트
    updateStartMarker(mapView)
}

private func updatePolyline(_ mapView: MKMapView) {
    // 기존 폴리라인 제거
    mapView.overlays.forEach { overlay in
        if overlay is MKPolyline {
            mapView.removeOverlay(overlay)
        }
    }

    // 새 폴리라인 추가
    let coordinates = viewModel.routeCoordinates
    guard coordinates.count >= 2 else { return }

    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
    mapView.addOverlay(polyline)
}

private func updateStartMarker(_ mapView: MKMapView) {
    guard let startLocation = viewModel.startLocation else { return }

    // 이미 있으면 스킵
    let hasStartMarker = mapView.annotations.contains { $0 is StartPointAnnotation }
    guard !hasStartMarker else { return }

    let annotation = StartPointAnnotation(coordinate: startLocation)
    mapView.addAnnotation(annotation)
}

// Coordinator 델리게이트 - 폴리라인 렌더러
func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let polyline = overlay as? MKPolyline {
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.systemBlue
        renderer.lineWidth = 5
        renderer.lineCap = .round
        renderer.lineJoin = .round
        return renderer
    }
    return MKOverlayRenderer(overlay: overlay)
}

// Coordinator 델리게이트 - 출발 마커
func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation is StartPointAnnotation {
        let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "StartPoint")
        view.markerTintColor = .systemGreen
        view.glyphImage = UIImage(systemName: "flag.fill")
        return view
    }
    // 기존 TaxiHorseAnnotation 처리...
    return nil
}
```

### 5. MapViewModel에 RouteManager 연동

```swift
// MapViewModel.swift 업데이트

class MapViewModel: ObservableObject {
    // MARK: - Properties
    private let routeManager: RouteManager

    var routeCoordinates: [CLLocationCoordinate2D] {
        routeManager.coordinates
    }

    var startLocation: CLLocationCoordinate2D? {
        routeManager.startLocation
    }

    // MARK: - Init
    init(locationService: LocationService, routeManager: RouteManager) {
        self.locationService = locationService
        self.routeManager = routeManager
        // ...
    }

    // MARK: - Setup
    private func setupBindings() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateLocation(location)
                self?.routeManager.addPoint(location)
            }
            .store(in: &cancellables)
    }
}
```

---

## ✅ 수락 기준

- [ ] 출발 지점에 초록색 시작 마커가 표시됨
- [ ] 이동 경로가 파란색 폴리라인으로 그려짐
- [ ] 실시간으로 경로가 업데이트됨
- [ ] 경로선 두께 5pt, 라운드 캡
- [ ] 1000+ 포인트에서도 60fps 성능 유지

---

## 📁 생성할 파일

```
HoguMeter/
├── Domain/
│   ├── Entities/
│   │   ├── RoutePoint.swift
│   │   └── StartPointAnnotation.swift
│   └── Services/
│       └── RouteManager.swift
```

---

## 🧪 테스트

1. 미터기 시작 후 지도 화면 진입
2. 출발 지점에 초록색 마커 표시 확인
3. 시뮬레이터에서 이동 시뮬레이션
4. 파란색 경로선이 그려지는지 확인
5. 장시간 이동 시 성능 저하 없는지 확인

---

## 📎 참고

- [MKPolyline](https://developer.apple.com/documentation/mapkit/mkpolyline)
- [MKPolylineRenderer](https://developer.apple.com/documentation/mapkit/mkpolylinerenderer)
