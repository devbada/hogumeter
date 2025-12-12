# Task 8.1: 지도 화면 기본 구조

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.1 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P0 |
| 상태 | 🔲 대기 |
| 의존성 | 없음 |

---

## 🎯 목표

Apple Maps (MapKit)을 사용하여 지도 화면의 기본 구조를 구현한다. SwiftUI에서 MKMapView를 사용하기 위한 UIViewRepresentable 래퍼를 만들고, 기본적인 지도 표시 및 제스처를 지원한다.

---

## 📝 구현 내용

### 1. MapContainerView 생성

```swift
// Presentation/Views/Map/MapContainerView.swift

import SwiftUI
import MapKit

struct MapContainerView: View {
    @StateObject private var viewModel: MapViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // 지도 뷰
            MapViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea(edges: .top)

            // 컨트롤 버튼 오버레이
            VStack {
                // 상단 네비게이션 바
                HStack {
                    Button("← 미터기") {
                        isPresented = false
                    }
                    Spacer()
                    Text("지도보기")
                        .font(.headline)
                    Spacer()
                    Button(action: { viewModel.centerOnCurrentLocation() }) {
                        Image(systemName: "location.fill")
                    }
                }
                .padding()
                .background(.ultraThinMaterial)

                Spacer()

                // 하단 정보 오버레이 (별도 Task에서 구현)
            }
        }
    }
}
```

### 2. MapViewRepresentable (UIViewRepresentable)

```swift
// Presentation/Views/Map/MapViewRepresentable.swift

import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false // 커스텀 마커 사용
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 지도 중심 업데이트
        if viewModel.shouldUpdateRegion {
            mapView.setRegion(viewModel.region, animated: true)
            viewModel.shouldUpdateRegion = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // 추후 마커, 폴리라인 델리게이트 추가
    }
}
```

### 3. MapViewModel 생성

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

    // MARK: - Dependencies
    private let locationService: LocationService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    // MARK: - Init
    init(locationService: LocationService) {
        self.locationService = locationService

        // 기본 위치 (서울)
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
    }

    // MARK: - Methods
    private func updateLocation(_ location: CLLocation) {
        currentLocation = location.coordinate
        currentHeading = location.course >= 0 ? location.course : currentHeading
    }

    func centerOnCurrentLocation() {
        guard let location = currentLocation else { return }
        region = MKCoordinateRegion(center: location, span: defaultSpan)
        shouldUpdateRegion = true
    }

    func initializeMapCenter() {
        if let location = currentLocation {
            region = MKCoordinateRegion(center: location, span: defaultSpan)
            shouldUpdateRegion = true
        }
    }
}
```

---

## ✅ 수락 기준

- [ ] MapKit을 사용하여 지도가 정상 표시됨
- [ ] 현재 위치 중심으로 지도 초기화
- [ ] 줌 인/아웃 제스처 지원
- [ ] 스크롤(팬) 제스처 지원
- [ ] 회전 제스처 지원
- [ ] MapViewModel이 LocationService와 연동됨

---

## 📁 생성할 파일

```
HoguMeter/
├── Presentation/
│   ├── Views/
│   │   └── Map/
│   │       ├── MapContainerView.swift
│   │       └── MapViewRepresentable.swift
│   └── ViewModels/
│       └── MapViewModel.swift
```

---

## 🧪 테스트

1. 앱 실행 후 지도 화면 진입
2. 지도가 현재 위치 중심으로 표시되는지 확인
3. 두 손가락으로 줌 인/아웃 테스트
4. 드래그로 지도 이동 테스트
5. 두 손가락 회전 테스트

---

## 📎 참고

- [MapKit Documentation](https://developer.apple.com/documentation/mapkit)
- [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)
