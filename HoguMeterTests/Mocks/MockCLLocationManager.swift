//
//  MockCLLocationManager.swift
//  HoguMeterTests
//
//  CLLocationManager Mock 클래스
//

import Foundation
import CoreLocation

/// CLLocationManager의 Mock 클래스
/// 테스트에서 GPS 신호 변화를 시뮬레이션하기 위해 사용
final class MockCLLocationManager {

    // MARK: - Properties

    weak var delegate: CLLocationManagerDelegate?

    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    var allowsBackgroundLocationUpdates: Bool = false
    var pausesLocationUpdatesAutomatically: Bool = true

    private(set) var isUpdatingLocation: Bool = false
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Mock Control Properties

    /// 시뮬레이션할 위치들의 시퀀스
    var simulatedLocations: [CLLocation] = []

    /// 시뮬레이션할 오류
    var simulatedError: Error?

    /// 시뮬레이션 간격 (초)
    var simulationInterval: TimeInterval = 1.0

    private var simulationTimer: Timer?
    private var currentLocationIndex: Int = 0

    // MARK: - Authorization Methods

    func requestWhenInUseAuthorization() {
        authorizationStatus = .authorizedWhenInUse
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            (self.delegate as? CLLocationManagerDelegate)?.locationManagerDidChangeAuthorization?(CLLocationManager())
        }
    }

    func requestAlwaysAuthorization() {
        authorizationStatus = .authorizedAlways
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            (self.delegate as? CLLocationManagerDelegate)?.locationManagerDidChangeAuthorization?(CLLocationManager())
        }
    }

    // MARK: - Location Update Methods

    func startUpdatingLocation() {
        isUpdatingLocation = true
        startSimulation()
    }

    func stopUpdatingLocation() {
        isUpdatingLocation = false
        stopSimulation()
    }

    // MARK: - Simulation Control

    private func startSimulation() {
        guard !simulatedLocations.isEmpty else { return }

        currentLocationIndex = 0
        simulationTimer = Timer.scheduledTimer(withTimeInterval: simulationInterval, repeats: true) { [weak self] _ in
            self?.sendNextLocation()
        }
        // 첫 번째 위치 즉시 전송
        sendNextLocation()
    }

    private func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    private func sendNextLocation() {
        guard isUpdatingLocation else { return }

        if let error = simulatedError {
            delegate?.locationManager?(CLLocationManager(), didFailWithError: error)
            return
        }

        guard currentLocationIndex < simulatedLocations.count else {
            // 모든 위치를 전송한 경우 마지막 위치 반복 또는 중지
            return
        }

        let location = simulatedLocations[currentLocationIndex]
        delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [location])
        currentLocationIndex += 1
    }

    // MARK: - Manual Trigger Methods

    /// 수동으로 위치 업데이트 발생
    func triggerLocationUpdate(with location: CLLocation) {
        delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [location])
    }

    /// 수동으로 위치 배열 업데이트 발생
    func triggerLocationUpdates(with locations: [CLLocation]) {
        delegate?.locationManager?(CLLocationManager(), didUpdateLocations: locations)
    }

    /// 수동으로 오류 발생
    func triggerError(_ error: Error) {
        delegate?.locationManager?(CLLocationManager(), didFailWithError: error)
    }

    /// GPS 신호 손실 시뮬레이션
    func simulateSignalLoss() {
        let clError = NSError(domain: kCLErrorDomain, code: CLError.locationUnknown.rawValue, userInfo: nil)
        delegate?.locationManager?(CLLocationManager(), didFailWithError: clError)
    }

    /// 권한 거부 시뮬레이션
    func simulateAuthorizationDenied() {
        authorizationStatus = .denied
        delegate?.locationManagerDidChangeAuthorization?(CLLocationManager())
    }
}

// MARK: - Test Location Factory

extension MockCLLocationManager {

    /// 테스트용 위치 생성 헬퍼
    static func createLocation(
        latitude: Double = 37.5665,
        longitude: Double = 126.9780,
        accuracy: CLLocationAccuracy = 10,
        speed: CLLocationSpeed = -1,
        timestamp: Date = Date()
    ) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            course: -1,
            speed: speed,
            timestamp: timestamp
        )
    }

    /// GPS 정상 신호 시퀀스 생성 (정확도 < 30m)
    static func createNormalSignalSequence(count: Int, baseSpeed: Double = 50) -> [CLLocation] {
        return (0..<count).map { index in
            createLocation(
                latitude: 37.5665 + Double(index) * 0.0001,
                longitude: 126.9780 + Double(index) * 0.0001,
                accuracy: Double.random(in: 5...25),
                speed: baseSpeed / 3.6,  // km/h → m/s
                timestamp: Date().addingTimeInterval(Double(index))
            )
        }
    }

    /// GPS 약한 신호 시퀀스 생성 (정확도 30-100m)
    static func createWeakSignalSequence(count: Int, baseSpeed: Double = 50) -> [CLLocation] {
        return (0..<count).map { index in
            createLocation(
                latitude: 37.5665 + Double(index) * 0.0001,
                longitude: 126.9780 + Double(index) * 0.0001,
                accuracy: Double.random(in: 30...99),
                speed: baseSpeed / 3.6,
                timestamp: Date().addingTimeInterval(Double(index))
            )
        }
    }

    /// GPS 손실 신호 시퀀스 생성 (정확도 >= 100m)
    static func createLostSignalSequence(count: Int) -> [CLLocation] {
        return (0..<count).map { index in
            createLocation(
                accuracy: Double.random(in: 100...500),
                speed: -1,  // 속도 정보 없음
                timestamp: Date().addingTimeInterval(Double(index))
            )
        }
    }

    /// 터널 진입/탈출 시나리오 시퀀스 생성
    static func createTunnelScenario() -> [CLLocation] {
        var locations: [CLLocation] = []

        // 터널 진입 전 (정상 신호)
        locations.append(contentsOf: createNormalSignalSequence(count: 3, baseSpeed: 80))

        // 터널 진입 (신호 약화)
        locations.append(contentsOf: createWeakSignalSequence(count: 2, baseSpeed: 80))

        // 터널 내부 (신호 손실)
        locations.append(contentsOf: createLostSignalSequence(count: 5))

        // 터널 탈출 (신호 약화)
        locations.append(contentsOf: createWeakSignalSequence(count: 2, baseSpeed: 80))

        // 터널 탈출 후 (정상 신호)
        locations.append(contentsOf: createNormalSignalSequence(count: 3, baseSpeed: 80))

        return locations
    }
}
