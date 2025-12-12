//
//  LocationService.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import CoreLocation
import Combine

protocol LocationServiceProtocol {
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    var totalDistance: Double { get }
    var lowSpeedDuration: TimeInterval { get }

    func startTracking()
    func stopTracking()
}

final class LocationService: NSObject, LocationServiceProtocol {

    // MARK: - Publishers
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    // MARK: - Properties
    private(set) var totalDistance: Double = 0              // meters
    private(set) var lowSpeedDuration: TimeInterval = 0     // seconds

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastUpdateTime: Date?

    // 저속 기준 속도 (m/s) - RegionFare의 lowSpeedThreshold(km/h)를 사용
    private var lowSpeedThreshold: Double = 15.72 / 3.6     // 기본값: 서울 15.72 km/h

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository

    // MARK: - Init
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Public Methods
    func startTracking() {
        totalDistance = 0
        lowSpeedDuration = 0
        lastLocation = nil
        lastUpdateTime = nil

        // 현재 지역 요금의 저속 기준 속도 적용
        let currentFare = settingsRepository.currentRegionFare
        lowSpeedThreshold = currentFare.lowSpeedThreshold / 3.6  // km/h → m/s

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // 정확도 필터링
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else {
            return
        }

        // 거리 계산
        if let lastLocation = lastLocation {
            let delta = location.distance(from: lastLocation)

            // 비정상적인 점프 필터링
            if delta < 100 {
                totalDistance += delta
            }
        }

        // 저속 시간 계산
        if let lastTime = lastUpdateTime {
            let timeDelta = location.timestamp.timeIntervalSince(lastTime)

            if location.speed >= 0 && location.speed < lowSpeedThreshold {
                lowSpeedDuration += timeDelta
            }
        }

        lastLocation = location
        lastUpdateTime = location.timestamp

        locationSubject.send(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
