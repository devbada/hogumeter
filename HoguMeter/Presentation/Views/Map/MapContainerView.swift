//
//  MapContainerView.swift
//  HoguMeter
//
//  Created on 2025-12-12.
//

import SwiftUI
import MapKit

struct MapContainerView: View {
    // MARK: - Properties
    @Bindable var meterViewModel: MeterViewModel
    @Binding var isPresented: Bool
    @StateObject private var mapViewModel: MapViewModel

    // Coach Mark
    @StateObject private var coachMarkManager = CoachMarkManager.shared
    @State private var coachMarkFrames: [String: CGRect] = [:]

    // MARK: - Init
    init(meterViewModel: MeterViewModel, locationService: LocationServiceProtocol, routeManager: RouteManager, isPresented: Binding<Bool>) {
        self.meterViewModel = meterViewModel
        self._isPresented = isPresented
        self._mapViewModel = StateObject(wrappedValue: MapViewModel(locationService: locationService, routeManager: routeManager))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            MapViewRepresentable(viewModel: mapViewModel)
                .ignoresSafeArea()
                .coachMarkTarget(id: "routeMap")
                .overlay(alignment: .top) {
                    topNavigationBar
                }
                .overlay(alignment: .bottomTrailing) {
                    // 우측 버튼들 (하단 패널 위에 위치)
                    VStack(spacing: 12) {
                        autoZoomButton
                        currentLocationButton
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 250) // bottomInfoOverlay 높이만큼 위로
                }
                .overlay(alignment: .bottom) {
                    // 하단 정보 오버레이
                    bottomInfoOverlay
                }

            // Coach Mark 오버레이
            if coachMarkManager.isShowingCoachMark,
               coachMarkManager.currentScreenId == "map",
               let currentMark = coachMarkManager.currentCoachMark,
               let frame = coachMarkFrames[currentMark.targetView] {
                CoachMarkOverlay(
                    manager: coachMarkManager,
                    coachMark: currentMark,
                    targetFrame: frame
                )
            }
        }
        .onCoachMarkFramesChange($coachMarkFrames)
        .onAppear {
            mapViewModel.initializeMapCenter()
            if coachMarkManager.shouldShowCoachMarks(for: "map") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    coachMarkManager.startCoachMarks(for: "map")
                }
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        VStack(spacing: 0) {
            // Safe area 상단 영역 (status bar)
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)

            // 실제 네비게이션 바
            HStack {
                Button(action: { isPresented = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("미터기")
                    }
                    .foregroundColor(.primary)
                }
                .coachMarkTarget(id: "closeButton")

                Spacer()

                Text("지도보기")
                    .font(.headline)

                Spacer()

                Color.clear
                    .frame(width: 70)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Auto Zoom Button
    private var autoZoomButton: some View {
        Button(action: {
            mapViewModel.toggleAutoZoom()
        }) {
            ZStack {
                Image(systemName: "scope")
                    .font(.system(size: 20))
                    .foregroundColor(mapViewModel.isAutoZoomEnabled ? .blue : .gray)

                // 비활성화 시 취소선 표시
                if !mapViewModel.isAutoZoomEnabled {
                    Image(systemName: "line.diagonal")
                        .font(.system(size: 24))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }

    // MARK: - Current Location Button
    private var currentLocationButton: some View {
        // 추적 모드에 따른 아이콘 결정
        let iconName: String = {
            switch mapViewModel.trackingMode {
            case .none:
                return "location"
            case .follow:
                return "location.fill"
            case .followWithHeading:
                return "location.north.line.fill"
            }
        }()

        let iconColor: Color = {
            switch mapViewModel.trackingMode {
            case .none:
                return .primary
            case .follow, .followWithHeading:
                return .blue
            }
        }()

        return Image(systemName: iconName)
            .font(.system(size: 20))
            .foregroundColor(iconColor)
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .onTapGesture(count: 2) {
                // 두 번 탭: 방향 추적 모드
                mapViewModel.enableHeadingTracking()
            }
            .onTapGesture(count: 1) {
                // 한 번 탭: 현재 위치로 이동
                mapViewModel.centerOnCurrentLocation()
            }
    }

    // MARK: - Bottom Info Overlay
    private var bottomInfoOverlay: some View {
        VStack(spacing: 16) {
            // 정보 그리드
            infoGrid
                .coachMarkTarget(id: "mapInfoGrid")

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
                infoItem(
                    icon: "💰",
                    title: "요금",
                    value: "\(meterViewModel.currentFare.formatted())원",
                    valueColor: .green
                )

                Divider()
                    .frame(height: 40)

                // 속도
                infoItem(
                    icon: "🚗",
                    title: "속도",
                    value: "\(Int(meterViewModel.currentSpeed)) km/h",
                    valueColor: .primary
                )
            }

            Divider()

            HStack(spacing: 16) {
                // 거리
                infoItem(
                    icon: "📍",
                    title: "거리",
                    value: String(format: "%.1f km", meterViewModel.distance),
                    valueColor: .primary
                )

                Divider()
                    .frame(height: 40)

                // 시간
                infoItem(
                    icon: "⏱️",
                    title: "시간",
                    value: formattedDuration,
                    valueColor: .primary
                )
            }
        }
    }

    private func infoItem(icon: String, title: String, value: String, valueColor: Color) -> some View {
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

    // MARK: - Stop Button
    private var stopButton: some View {
        Button(action: handleStop) {
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

    // MARK: - Helpers
    private var formattedDuration: String {
        let hours = Int(meterViewModel.duration) / 3600
        let minutes = (Int(meterViewModel.duration) % 3600) / 60
        let seconds = Int(meterViewModel.duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func handleStop() {
        meterViewModel.stopMeter()
        isPresented = false
    }
}
