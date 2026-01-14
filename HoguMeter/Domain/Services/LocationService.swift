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
    var gpsSignalStatePublisher: AnyPublisher<GPSSignalState, Never> { get }
    var totalDistance: Double { get }
    var highSpeedDistance: Double { get }    // 고속 구간 이동 거리 (병산제용)
    var lowSpeedDuration: TimeInterval { get }
    var gpsSignalState: GPSSignalState { get }
    var lastKnownLocationInfo: LastKnownLocationInfo? { get }

    // Dead Reckoning
    var isEstimatedDistance: Bool { get }
    var deadReckoningState: DeadReckoningState { get }
    var estimatedDistance: Double { get }

    func startTracking()
    func stopTracking()
}

final class LocationService: NSObject, LocationServiceProtocol {

    // MARK: - Publishers
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    private let gpsSignalStateSubject = CurrentValueSubject<GPSSignalState, Never>(.normal)
    var gpsSignalStatePublisher: AnyPublisher<GPSSignalState, Never> {
        gpsSignalStateSubject.eraseToAnyPublisher()
    }

    // MARK: - Properties
    private(set) var totalDistance: Double = 0              // meters (UI 표시용 총 거리)
    private(set) var highSpeedDistance: Double = 0          // meters (요금 계산용 고속구간 거리)
    private(set) var lowSpeedDuration: TimeInterval = 0     // seconds (요금 계산용 저속구간 시간)

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastUpdateTime: Date?

    // 저속 기준 속도 (m/s) - RegionFare의 lowSpeedThreshold(km/h)를 사용
    private var lowSpeedThreshold: Double = 15.72 / 3.6     // 기본값: 서울 15.72 km/h

    // MARK: - GPS Signal State Tracking
    private(set) var gpsSignalState: GPSSignalState = .normal {
        didSet {
            if oldValue != gpsSignalState {
                gpsSignalStateSubject.send(gpsSignalState)
                logGPSStateChange(from: oldValue, to: gpsSignalState)
                handleGPSStateTransition(from: oldValue, to: gpsSignalState)
            }
        }
    }

    /// 마지막으로 유효한 위치 정보 (신호 손실 시 Dead Reckoning용)
    private(set) var lastKnownLocationInfo: LastKnownLocationInfo?

    /// 마지막 유효한 위치 (정확도 좋은 위치)
    private var lastValidLocation: CLLocation?
    private var lastValidSpeed: Double = 0

    /// 마지막 위치 업데이트 시간 (신호 손실 감지용)
    private var lastLocationUpdateTimestamp: Date?

    /// 신호 손실 판단 타이머
    private var signalLossCheckTimer: Timer?

    /// 신호 손실로 판단하는 시간 (초)
    private let signalLossTimeout: TimeInterval = 5.0

    // MARK: - Dead Reckoning

    /// Dead Reckoning 서비스
    private let deadReckoningService = DeadReckoningService()

    /// 현재 Dead Reckoning 상태
    var deadReckoningState: DeadReckoningState {
        return deadReckoningService.state
    }

    /// Dead Reckoning 추정 거리
    var estimatedDistance: Double {
        return deadReckoningService.estimatedDistance
    }

    /// 현재 거리가 추정치인지 여부
    var isEstimatedDistance: Bool {
        return deadReckoningService.isEstimating
    }

    /// Dead Reckoning으로 추정된 총 거리 (GPS 복구 전까지의 누적)
    private var accumulatedEstimatedDistance: Double = 0

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository

    // MARK: - Init
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
        super.init()
        setupLocationManager()
        setupDeadReckoningBindings()
    }

    deinit {
        signalLossCheckTimer?.invalidate()
        signalLossCheckTimer = nil
        deadReckoningService.reset()
        locationManager.delegate = nil
        Logger.gps.debug("[GPS] LocationService deinit")
    }

    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    private func setupDeadReckoningBindings() {
        // Dead Reckoning 추정 거리 업데이트 시 totalDistance에 반영
        // (실시간 업데이트는 estimatedDistance 프로퍼티로 접근)
    }

    // MARK: - Public Methods
    func startTracking() {
        totalDistance = 0
        highSpeedDistance = 0
        lowSpeedDuration = 0
        lastLocation = nil
        lastUpdateTime = nil

        // GPS 신호 상태 초기화
        gpsSignalState = .normal
        lastKnownLocationInfo = nil
        lastValidLocation = nil
        lastValidSpeed = 0
        lastLocationUpdateTimestamp = nil

        // Dead Reckoning 초기화
        deadReckoningService.reset()
        accumulatedEstimatedDistance = 0

        // 현재 지역 요금의 저속 기준 속도 적용
        let currentFare = settingsRepository.currentRegionFare
        lowSpeedThreshold = currentFare.lowSpeedThreshold / 3.6  // km/h → m/s

        // 백그라운드 위치 추적을 위해 Always 권한 요청
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        // 신호 손실 감지 타이머 시작
        startSignalLossCheckTimer()

        Logger.gps.info("[GPS] 위치 추적 시작")
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        signalLossCheckTimer?.invalidate()
        signalLossCheckTimer = nil

        // Dead Reckoning 중지 및 최종 거리 반영
        if let result = deadReckoningService.stop() {
            finalizeDeadReckoningDistance(result)
        }

        Logger.gps.info("[GPS] 위치 추적 중지")
    }

    // MARK: - Signal Loss Check Timer

    private func startSignalLossCheckTimer() {
        signalLossCheckTimer?.invalidate()
        signalLossCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForSignalLoss()
        }
    }

    private func checkForSignalLoss() {
        guard let lastUpdate = lastLocationUpdateTimestamp else {
            // 아직 위치 업데이트를 받은 적이 없음
            return
        }

        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)

        if timeSinceLastUpdate > signalLossTimeout {
            // 일정 시간 동안 업데이트 없음 → 신호 손실
            if gpsSignalState != .lost {
                handleSignalLoss(reason: "위치 업데이트 타임아웃 (\(Int(timeSinceLastUpdate))초)")
            }
        }
    }

    // MARK: - Signal State Management

    private func updateGPSSignalState(from location: CLLocation) {
        let newState = GPSSignalState.from(accuracy: location.horizontalAccuracy)

        switch newState {
        case .normal:
            handleSignalRestored(with: location)
        case .weak:
            handleWeakSignal(with: location)
        case .lost:
            handleSignalLoss(reason: "정확도 불량 (\(Int(location.horizontalAccuracy))m)")
        }
    }

    private func handleSignalRestored(with location: CLLocation) {
        let wasNotNormal = gpsSignalState != .normal

        if wasNotNormal {
            Logger.gps.info("[GPS] 신호 복구됨 - 정확도: \(Int(location.horizontalAccuracy))m")
        }

        gpsSignalState = .normal

        // 마지막 유효 위치 업데이트
        lastValidLocation = location
        if location.speed >= 0 {
            lastValidSpeed = location.speed
        }

        // 신호 손실 정보 초기화
        lastKnownLocationInfo = nil
    }

    private func handleWeakSignal(with location: CLLocation) {
        if gpsSignalState == .normal {
            Logger.gps.warning("[GPS] 신호 약화됨 - 정확도: \(Int(location.horizontalAccuracy))m")

            // 마지막 유효 위치 저장 (아직 손실은 아님)
            if let validLocation = lastValidLocation {
                lastKnownLocationInfo = LastKnownLocationInfo(
                    location: validLocation,
                    speed: lastValidSpeed,
                    signalLostAt: Date()
                )
            }
        }

        gpsSignalState = .weak
    }

    private func handleSignalLoss(reason: String) {
        if gpsSignalState != .lost {
            Logger.gps.error("[GPS] 신호 손실 - 원인: \(reason)")

            // 마지막 유효 위치 정보 저장 (Dead Reckoning용)
            if lastKnownLocationInfo == nil, let validLocation = lastValidLocation {
                lastKnownLocationInfo = LastKnownLocationInfo(
                    location: validLocation,
                    speed: lastValidSpeed,
                    signalLostAt: Date()
                )
                Logger.gps.info("[GPS] 마지막 유효 위치 저장 - 속도: \(String(format: "%.1f", lastValidSpeed * 3.6)) km/h")
            }
        }

        gpsSignalState = .lost
    }

    // MARK: - GPS State Transition Handler

    private func handleGPSStateTransition(from oldState: GPSSignalState, to newState: GPSSignalState) {
        // 정상 → 손실: Dead Reckoning 시작
        if oldState == .normal && (newState == .weak || newState == .lost) {
            startDeadReckoning()
        }
        // 약함 → 손실: Dead Reckoning이 아직 시작 안 됐으면 시작
        else if oldState == .weak && newState == .lost {
            if deadReckoningService.state == .inactive {
                startDeadReckoning()
            }
        }
        // 손실/약함 → 정상: Dead Reckoning 중지 및 거리 반영
        else if newState == .normal && (oldState == .weak || oldState == .lost) {
            stopDeadReckoningAndApply()
        }
    }

    // MARK: - Dead Reckoning Control

    private func startDeadReckoning() {
        guard let locationInfo = lastKnownLocationInfo else {
            Logger.gps.warning("[DR] Dead Reckoning 시작 불가 - 마지막 위치 정보 없음")
            return
        }

        deadReckoningService.start(with: locationInfo)
    }

    private func stopDeadReckoningAndApply() {
        guard let result = deadReckoningService.stop() else {
            return
        }

        finalizeDeadReckoningDistance(result)
    }

    private func finalizeDeadReckoningDistance(_ result: DeadReckoningResult) {
        let estimatedDist = result.estimatedDistance

        if estimatedDist > 0 {
            // 추정 거리를 총 거리에 반영
            totalDistance += estimatedDist

            // 마지막 속도가 고속 기준 이상이었다면 고속 거리에도 반영
            if result.lastKnownSpeed >= lowSpeedThreshold {
                highSpeedDistance += estimatedDist
                Logger.gps.info("[DR] 추정 거리 반영 (고속): \(String(format: "%.0f", estimatedDist))m")
            } else {
                // 저속이었다면 시간 요금으로 계산
                lowSpeedDuration += result.elapsedTime
                Logger.gps.info("[DR] 추정 시간 반영 (저속): \(String(format: "%.0f", result.elapsedTime))초")
            }

            accumulatedEstimatedDistance += estimatedDist

            if result.isExpired {
                Logger.gps.warning("[DR] Dead Reckoning 만료로 인한 최종 반영 - 총 추정 거리: \(String(format: "%.0f", accumulatedEstimatedDistance))m")
            }
        }
    }

    // MARK: - Logging

    private func logGPSStateChange(from oldState: GPSSignalState, to newState: GPSSignalState) {
        Logger.gps.info("[GPS] 신호 상태 변경: \(oldState.displayName) → \(newState.displayName)")
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // 위치 업데이트 타임스탬프 기록 (신호 손실 감지용)
        lastLocationUpdateTimestamp = Date()

        // GPS 신호 상태 업데이트
        updateGPSSignalState(from: location)

        // 정확도 필터링 - 정확도가 좋지 않으면 요금 계산에서 제외
        // (하지만 신호 상태 업데이트는 위에서 이미 처리됨)
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else {
            Logger.gps.debug("[GPS] 위치 업데이트 무시 (정확도: \(Int(location.horizontalAccuracy))m)")
            return
        }

        // 병산제: 고속이면 거리만, 저속이면 시간만 계산
        let isHighSpeed = location.speed >= lowSpeedThreshold

        if let lastLocation = lastLocation {
            let delta = location.distance(from: lastLocation)

            // 비정상적인 점프 필터링
            if delta < 100 {
                totalDistance += delta  // UI 표시용 총 거리

                // 고속 구간에서만 거리 추가 (병산제)
                if isHighSpeed {
                    highSpeedDistance += delta
                }
            }
        }

        // 저속/정차 시에만 시간 추가 (병산제)
        if let lastTime = lastUpdateTime {
            let timeDelta = location.timestamp.timeIntervalSince(lastTime)

            if !isHighSpeed && location.speed >= 0 {
                lowSpeedDuration += timeDelta
            }
        }

        lastLocation = location
        lastUpdateTime = location.timestamp

        locationSubject.send(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.gps.error("[GPS] 위치 서비스 오류: \(error.localizedDescription)")

        // CLError 타입별 처리
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                Logger.gps.error("[GPS] 위치 권한 거부됨")
            case .locationUnknown:
                // 일시적 오류 - 신호 손실로 처리
                handleSignalLoss(reason: "위치 확인 불가 (locationUnknown)")
            case .network:
                Logger.gps.warning("[GPS] 네트워크 오류")
                handleSignalLoss(reason: "네트워크 오류")
            default:
                handleSignalLoss(reason: "오류 코드: \(clError.code.rawValue)")
            }
        } else {
            handleSignalLoss(reason: error.localizedDescription)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            // 권한만 확인하고, 실제 추적은 startTracking()에서 시작
            Logger.gps.info("[GPS] 위치 권한 승인됨 (Always)")
        case .authorizedWhenInUse:
            // When In Use 권한만 있으면 Always로 업그레이드 요청
            manager.requestAlwaysAuthorization()
            Logger.gps.info("[GPS] 위치 권한 승인됨 (When In Use) - Always 권한 요청 중")
        case .denied, .restricted:
            Logger.gps.warning("[GPS] 위치 권한 거부/제한됨")
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
}
