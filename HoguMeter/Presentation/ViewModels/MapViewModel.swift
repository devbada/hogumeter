//
//  MapViewModel.swift
//  HoguMeter
//
//  Created on 2025-12-12.
//

import Foundation
import MapKit
import Combine

/// 지도 추적 모드
enum MapTrackingMode {
    case none              // 추적 없음 (자유 이동)
    case follow            // 현재 위치 추적
    case followWithHeading // 현재 위치 + 방향 추적 (지도 회전)
}

@MainActor
class MapViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var region: MKCoordinateRegion
    @Published var shouldUpdateRegion = false
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentHeading: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var trackingMode: MapTrackingMode = .follow
    @Published var shouldUpdateTrackingMode = false

    var isTrackingEnabled: Bool {
        trackingMode != .none
    }

    // MARK: - Auto Zoom
    private let autoZoomManager = AutoZoomManager()

    var isAutoZoomEnabled: Bool {
        autoZoomManager.isAutoZoomEnabled
    }

    // MARK: - Dependencies
    private let locationService: LocationServiceProtocol
    private let routeManager: RouteManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Constants
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    // MARK: - Route Properties (from RouteManager)
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

        // 기본 위치 (서울)
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        self.region = MKCoordinateRegion(center: defaultCoordinate, span: defaultSpan)

        setupBindings()
    }

    // Note: Cancellables are auto-cleaned when Set is deallocated
    // deinit just logs for verification
    nonisolated deinit {
        Logger.gps.debug("[MapVM] MapViewModel deinit")
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
        currentSpeed = max(0, location.speed * 3.6) // m/s -> km/h

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

    /// 한 번 탭: 현재 위치로 이동 + follow 모드
    func centerOnCurrentLocation() {
        // 우선순위: 현재 위치 > 경로의 마지막 좌표 > 시작 위치
        let targetLocation: CLLocationCoordinate2D? = currentLocation
            ?? routeCoordinates.last
            ?? startLocation

        guard let location = targetLocation else {
            // 위치 정보가 없으면 햅틱 피드백으로 알림
            HapticManager.warning()
            return
        }

        region = MKCoordinateRegion(center: location, span: defaultSpan)
        shouldUpdateRegion = true
        trackingMode = .follow
        shouldUpdateTrackingMode = true
        HapticManager.light()
    }

    /// 두 번 탭: 방향 추적 모드 활성화 (지도 회전)
    func enableHeadingTracking() {
        // 우선순위: 현재 위치 > 경로의 마지막 좌표 > 시작 위치
        let targetLocation: CLLocationCoordinate2D? = currentLocation
            ?? routeCoordinates.last
            ?? startLocation

        guard let location = targetLocation else {
            HapticManager.warning()
            return
        }

        region = MKCoordinateRegion(center: location, span: defaultSpan)
        shouldUpdateRegion = true
        trackingMode = .followWithHeading
        shouldUpdateTrackingMode = true
        HapticManager.medium()
    }

    func initializeMapCenter() {
        // 우선순위: 현재 위치 > 경로의 마지막 좌표 > 시작 위치
        let targetLocation: CLLocationCoordinate2D? = currentLocation
            ?? routeCoordinates.last
            ?? startLocation

        if let location = targetLocation {
            region = MKCoordinateRegion(center: location, span: defaultSpan)
            shouldUpdateRegion = true
        }
    }

    func disableTracking() {
        trackingMode = .none
        shouldUpdateTrackingMode = true
    }

    /// 사용자가 지도를 직접 조작했음을 알림
    func userDidInteractWithMap() {
        autoZoomManager.userDidInteract()
    }

    /// 자동 줌 토글
    func toggleAutoZoom() {
        autoZoomManager.toggleAutoZoom()
        objectWillChange.send()
    }
}
