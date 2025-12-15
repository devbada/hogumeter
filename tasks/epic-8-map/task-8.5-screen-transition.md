# Task 8.5: 화면 전환 연동

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.5 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P0 |
| 상태 | 🔲 대기 |
| 의존성 | TASK-8.1 ~ TASK-8.4 |

---

## 🎯 목표

미터기 화면과 지도 화면 간의 자연스러운 전환을 구현한다. 화면 전환 중에도 미터기가 계속 작동하고, 부드러운 애니메이션으로 전환된다.

---

## 📝 구현 내용

### 1. MainMeterView에 지도보기 버튼 추가

```swift
// Presentation/Views/Main/MainMeterView.swift 수정

struct MainMeterView: View {
    @StateObject private var viewModel: MeterViewModel
    @State private var showMapView = false

    var body: some View {
        ZStack {
            // 기존 미터기 UI...

            VStack {
                // 상단에 지도보기 버튼 (미터기 작동 중에만 표시)
                if viewModel.isRunning {
                    HStack {
                        Spacer()
                        mapButton
                    }
                    .padding()
                }

                Spacer()

                // 기존 미터기 컨트롤...
            }
        }
        .fullScreenCover(isPresented: $showMapView) {
            MapContainerView(
                meterViewModel: viewModel,
                routeManager: viewModel.routeManager,
                isPresented: $showMapView
            )
        }
    }

    private var mapButton: some View {
        Button(action: { showMapView = true }) {
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                Text("지도")
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
    }
}
```

### 2. MeterViewModel에 RouteManager 연동

```swift
// Presentation/ViewModels/MeterViewModel.swift 수정

class MeterViewModel: ObservableObject {
    // MARK: - Properties
    let routeManager = RouteManager()

    // MARK: - Methods
    func startMeter() {
        // 기존 코드...

        // 경로 기록 시작
        if let currentLocation = locationService.currentLocation {
            routeManager.startNewRoute(at: currentLocation)
        }
    }

    func stopMeter() {
        // 기존 코드...

        // 경로는 유지 (영수증에서 사용 가능)
    }

    func resetMeter() {
        // 기존 코드...

        // 경로 초기화
        routeManager.clearRoute()
    }
}
```

### 3. MapContainerView 초기화 수정

```swift
// Presentation/Views/Map/MapContainerView.swift 수정

struct MapContainerView: View {
    @ObservedObject var meterViewModel: MeterViewModel
    @ObservedObject var routeManager: RouteManager
    @Binding var isPresented: Bool

    @StateObject private var mapViewModel: MapViewModel

    init(meterViewModel: MeterViewModel, routeManager: RouteManager, isPresented: Binding<Bool>) {
        self.meterViewModel = meterViewModel
        self.routeManager = routeManager
        self._isPresented = isPresented

        // MapViewModel 초기화 - AppState에서 locationService 가져오기
        _mapViewModel = StateObject(wrappedValue: MapViewModel(
            locationService: meterViewModel.locationService,
            routeManager: routeManager
        ))
    }

    var body: some View {
        ZStack {
            MapViewRepresentable(viewModel: mapViewModel, routeManager: routeManager)
                .ignoresSafeArea(edges: .top)

            VStack {
                topNavigationBar
                Spacer()
                MapInfoOverlayView(meterViewModel: meterViewModel, onStop: handleStop)
            }
        }
        .onAppear {
            mapViewModel.initializeMapCenter()
        }
    }

    // ... 기존 코드
}
```

### 4. 전환 애니메이션 커스텀 (선택)

```swift
// 커스텀 트랜지션 (필요시)
extension AnyTransition {
    static var mapTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
}

// 사용
.fullScreenCover(isPresented: $showMapView) {
    MapContainerView(...)
        .transition(.mapTransition)
}
```

---

## ✅ 수락 기준

- [ ] 미터기 화면에서 "지도보기" 버튼이 표시됨 (작동 중에만)
- [ ] 버튼 탭 시 지도 화면으로 전환됨
- [ ] 지도 화면에서 "← 미터기" 버튼으로 복귀 가능
- [ ] 화면 전환 중에도 미터기가 계속 작동함
- [ ] 부드러운 전환 애니메이션
- [ ] 지도 화면에서 "정지하기" 시 미터기 정지 + 화면 복귀

---

## 📁 수정할 파일

```
HoguMeter/
├── Presentation/
│   ├── Views/
│   │   ├── Main/
│   │   │   └── MainMeterView.swift    # 지도보기 버튼 추가
│   │   └── Map/
│   │       └── MapContainerView.swift # 초기화 수정
│   └── ViewModels/
│       └── MeterViewModel.swift       # RouteManager 연동
```

---

## 🧪 테스트

1. 미터기 시작 전 - 지도보기 버튼이 숨겨져 있는지 확인
2. 미터기 시작 후 - 지도보기 버튼 표시 확인
3. 지도보기 버튼 탭 → 지도 화면 전환 확인
4. 지도 화면에서 요금이 계속 올라가는지 확인
5. "← 미터기" 버튼 → 미터기 화면 복귀 확인
6. 미터기가 계속 작동 중인지 확인
7. 지도 화면에서 "정지하기" → 미터기 정지 + 복귀 확인

---

## 📎 참고

- SwiftUI fullScreenCover
- ObservableObject 공유
