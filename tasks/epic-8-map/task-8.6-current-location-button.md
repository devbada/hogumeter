# Task 8.6: 현재 위치 버튼

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.6 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P1 |
| 상태 | 🔲 대기 |
| 의존성 | TASK-8.1 |

---

## 🎯 목표

지도를 스크롤한 후 현재 위치로 빠르게 돌아올 수 있는 버튼을 구현한다. 추적 모드 토글 기능도 선택적으로 추가한다.

---

## 📝 구현 내용

### 1. MapControlsView 구현

```swift
// Presentation/Views/Map/Components/MapControlsView.swift

import SwiftUI

struct MapControlsView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        VStack(spacing: 12) {
            // 현재 위치 버튼
            currentLocationButton

            // 추적 모드 토글 (선택)
            if viewModel.isTrackingEnabled {
                trackingModeIndicator
            }
        }
    }

    private var currentLocationButton: some View {
        Button(action: {
            viewModel.centerOnCurrentLocation()
        }) {
            Image(systemName: viewModel.isTrackingEnabled ? "location.fill" : "location")
                .font(.system(size: 20))
                .foregroundColor(viewModel.isTrackingEnabled ? .blue : .primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }

    private var trackingModeIndicator: some View {
        Text("추적 중")
            .font(.caption2)
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
    }
}
```

### 2. MapViewModel에 추적 모드 추가

```swift
// MapViewModel.swift 업데이트

class MapViewModel: ObservableObject {
    // MARK: - Properties
    @Published var isTrackingEnabled = true // 자동 추적 모드

    // MARK: - Methods
    func centerOnCurrentLocation() {
        guard let location = currentLocation else { return }
        region = MKCoordinateRegion(center: location, span: defaultSpan)
        shouldUpdateRegion = true
        isTrackingEnabled = true
    }

    func disableTracking() {
        isTrackingEnabled = false
    }

    private func updateLocation(_ location: CLLocation) {
        currentLocation = location.coordinate
        currentHeading = location.course >= 0 ? location.course : currentHeading
        currentSpeed = max(0, location.speed * 3.6)

        // 추적 모드일 때만 지도 중심 업데이트
        if isTrackingEnabled {
            region = MKCoordinateRegion(center: location.coordinate, span: region.span)
            shouldUpdateRegion = true
        }
    }
}
```

### 3. MapViewRepresentable에서 사용자 제스처 감지

```swift
// MapViewRepresentable.swift 업데이트

class Coordinator: NSObject, MKMapViewDelegate {
    var parent: MapViewRepresentable

    init(_ parent: MapViewRepresentable) {
        self.parent = parent
    }

    // 사용자가 지도를 드래그하면 추적 모드 비활성화
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // 사용자 제스처로 인한 변경인지 확인
        if let gestureRecognizers = mapView.subviews.first?.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer.state == .began || recognizer.state == .changed {
                    parent.viewModel.disableTracking()
                    break
                }
            }
        }
    }
}
```

### 4. MapContainerView에 컨트롤 버튼 배치

```swift
// MapContainerView.swift 업데이트

struct MapContainerView: View {
    // ...

    var body: some View {
        ZStack {
            MapViewRepresentable(viewModel: mapViewModel, routeManager: routeManager)
                .ignoresSafeArea(edges: .top)

            VStack {
                topNavigationBar

                Spacer()

                // 우측에 컨트롤 버튼 배치
                HStack {
                    Spacer()
                    MapControlsView(viewModel: mapViewModel)
                        .padding(.trailing, 16)
                        .padding(.bottom, 200) // 정보 오버레이 위에 배치
                }

                MapInfoOverlayView(meterViewModel: meterViewModel, onStop: handleStop)
            }
        }
    }

    // 상단 네비게이션에서 현재위치 버튼 제거 (MapControlsView로 이동)
    private var topNavigationBar: some View {
        HStack {
            Button(action: { isPresented = false }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("미터기")
                }
            }

            Spacer()

            Text("지도보기")
                .font(.headline)

            Spacer()

            // 빈 공간 (균형 맞추기)
            Color.clear
                .frame(width: 60)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
```

---

## ✅ 수락 기준

- [ ] 우측에 현재 위치 버튼 (📍) 표시
- [ ] 버튼 탭 시 현재 위치로 지도 중심 이동
- [ ] 부드러운 애니메이션으로 이동
- [ ] 사용자가 지도 스크롤 시 추적 모드 비활성화
- [ ] 현재 위치 버튼 탭 시 추적 모드 재활성화
- [ ] 추적 모드 상태가 아이콘으로 표시됨 (location / location.fill)

---

## 📁 생성/수정할 파일

```
HoguMeter/
├── Presentation/
│   ├── Views/
│   │   └── Map/
│   │       ├── Components/
│   │       │   └── MapControlsView.swift     # 신규
│   │       └── MapContainerView.swift        # 수정
│   └── ViewModels/
│       └── MapViewModel.swift                # 수정
```

---

## 🧪 테스트

1. 지도 화면 진입 시 현재 위치 버튼 표시 확인
2. 지도 드래그 후 버튼 탭 → 현재 위치로 이동 확인
3. 이동 애니메이션이 부드러운지 확인
4. 지도 스크롤 시 추적 모드 비활성화 확인
5. 버튼 탭 시 추적 모드 재활성화 확인

---

## 📎 참고

- MKMapView regionWillChangeAnimated
- SwiftUI gesture detection
