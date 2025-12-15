//
//  MapViewModel.swift
//  HoguMeter
//
//  Created on 2025-12-12.
//

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

    // MARK: - Setup
    private func setupBindings() {
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateLocation(location)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods
    private func updateLocation(_ location: CLLocation) {
        currentLocation = location.coordinate
        currentHeading = location.course >= 0 ? location.course : currentHeading
        currentSpeed = max(0, location.speed * 3.6) // m/s -> km/h

        // 추적 모드일 때만 지도 중심 업데이트
        if isTrackingEnabled {
            region = MKCoordinateRegion(center: location.coordinate, span: region.span)
            shouldUpdateRegion = true
        }
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
}
