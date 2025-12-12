# Task 8.4: 하단 정보 오버레이

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-8.4 |
| Epic | Epic 8 - 지도보기 기능 |
| 우선순위 | P0 |
| 상태 | 🔲 대기 |
| 의존성 | TASK-8.1 |

---

## 🎯 목표

지도 화면 하단에 현재 요금, 속도, 거리, 시간 정보를 표시하는 오버레이 패널을 구현한다. 실시간으로 정보가 업데이트되고, "정지하기" 버튼으로 미터기를 종료할 수 있다.

---

## 📝 구현 내용

### 1. MapInfoOverlayView 구현

```swift
// Presentation/Views/Map/Components/MapInfoOverlayView.swift

import SwiftUI

struct MapInfoOverlayView: View {
    @ObservedObject var meterViewModel: MeterViewModel
    var onStop: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 정보 그리드
            infoGrid

            // 정지 버튼
            stopButton
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
    }

    // MARK: - Info Grid
    private var infoGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // 요금
                InfoItem(
                    icon: "💰",
                    title: "요금",
                    value: "\(meterViewModel.currentFare.formatted())원",
                    valueColor: .green
                )

                Divider()
                    .frame(height: 40)

                // 속도
                InfoItem(
                    icon: "🚗",
                    title: "속도",
                    value: "\(Int(meterViewModel.currentSpeed)) km/h",
                    valueColor: .primary
                )
            }

            Divider()

            HStack(spacing: 16) {
                // 거리
                InfoItem(
                    icon: "📍",
                    title: "거리",
                    value: String(format: "%.1f km", meterViewModel.totalDistance / 1000),
                    valueColor: .primary
                )

                Divider()
                    .frame(height: 40)

                // 시간
                InfoItem(
                    icon: "⏱️",
                    title: "시간",
                    value: meterViewModel.formattedDuration,
                    valueColor: .primary
                )
            }
        }
    }

    // MARK: - Stop Button
    private var stopButton: some View {
        Button(action: onStop) {
            HStack {
                Image(systemName: "stop.fill")
                Text("정지하기")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Info Item Component
struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
    }
}
```

### 2. MapContainerView에 오버레이 추가

```swift
// MapContainerView.swift 업데이트

struct MapContainerView: View {
    @StateObject private var viewModel: MapViewModel
    @ObservedObject var meterViewModel: MeterViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // 지도 뷰
            MapViewRepresentable(viewModel: viewModel)
                .ignoresSafeArea(edges: .top)

            VStack {
                // 상단 네비게이션 바
                topNavigationBar

                Spacer()

                // 하단 정보 오버레이
                MapInfoOverlayView(
                    meterViewModel: meterViewModel,
                    onStop: handleStop
                )
            }
        }
    }

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

            Button(action: { viewModel.centerOnCurrentLocation() }) {
                Image(systemName: "location.fill")
                    .padding(8)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func handleStop() {
        meterViewModel.stopMeter()
        isPresented = false
    }
}
```

### 3. MeterViewModel 확장 (필요시)

```swift
// MeterViewModel.swift - formattedDuration 추가 (없다면)

var formattedDuration: String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

---

## ✅ 수락 기준

- [ ] 반투명 배경의 정보 패널이 하단에 표시됨
- [ ] 현재 요금이 녹색으로 강조되어 표시됨
- [ ] 현재 속도, 총 거리, 주행 시간이 표시됨
- [ ] 정보가 실시간으로 업데이트됨 (1초 간격)
- [ ] "정지하기" 버튼 탭 시 미터기 정지 및 화면 복귀
- [ ] 다크모드 지원

---

## 📁 생성할 파일

```
HoguMeter/
├── Presentation/
│   └── Views/
│       └── Map/
│           └── Components/
│               └── MapInfoOverlayView.swift
```

---

## 🧪 테스트

1. 지도 화면 진입 시 하단 패널 표시 확인
2. 요금, 속도, 거리, 시간 정보 표시 확인
3. 미터기 작동 중 정보가 실시간 업데이트되는지 확인
4. "정지하기" 버튼 탭 시 미터기 정지 확인
5. 다크모드에서 가독성 확인

---

## 📎 참고

- SwiftUI Material backgrounds
- Clean Architecture - ViewModel 연동
