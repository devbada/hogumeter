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

    // MARK: - Init
    init(meterViewModel: MeterViewModel, locationService: LocationServiceProtocol, isPresented: Binding<Bool>) {
        self.meterViewModel = meterViewModel
        self._isPresented = isPresented
        self._mapViewModel = StateObject(wrappedValue: MapViewModel(locationService: locationService))
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // 지도 뷰
            MapViewRepresentable(viewModel: mapViewModel)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // 상단 네비게이션 바
                topNavigationBar

                Spacer()

                // 우측 컨트롤 버튼
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        currentLocationButton
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)

                // 하단 정보 오버레이
                bottomInfoOverlay
            }
        }
        .onAppear {
            mapViewModel.initializeMapCenter()
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            // 뒤로가기 버튼
            Button(action: { isPresented = false }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("미터기")
                }
                .foregroundColor(.primary)
            }

            Spacer()

            Text("지도보기")
                .font(.headline)

            Spacer()

            // 균형을 위한 빈 공간
            Color.clear
                .frame(width: 70)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Current Location Button
    private var currentLocationButton: some View {
        Button(action: {
            mapViewModel.centerOnCurrentLocation()
        }) {
            Image(systemName: mapViewModel.isTrackingEnabled ? "location.fill" : "location")
                .font(.system(size: 20))
                .foregroundColor(mapViewModel.isTrackingEnabled ? .blue : .primary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }

    // MARK: - Bottom Info Overlay
    private var bottomInfoOverlay: some View {
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
