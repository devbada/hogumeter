//
//  MockDeadReckoningService.swift
//  HoguMeterTests
//
//  DeadReckoningService Mock 클래스
//

import Foundation
import Combine
import CoreLocation
@testable import HoguMeter

/// DeadReckoningService의 Mock 클래스
/// 테스트에서 Dead Reckoning 동작을 제어하기 위해 사용
final class MockDeadReckoningService {

    // MARK: - Published Properties

    private(set) var state: DeadReckoningState = .inactive
    private(set) var estimatedDistance: Double = 0

    var isEstimating: Bool {
        return state == .active
    }

    // MARK: - Publishers

    private let stateSubject = CurrentValueSubject<DeadReckoningState, Never>(.inactive)
    var statePublisher: AnyPublisher<DeadReckoningState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private let estimatedDistanceSubject = CurrentValueSubject<Double, Never>(0)
    var estimatedDistancePublisher: AnyPublisher<Double, Never> {
        estimatedDistanceSubject.eraseToAnyPublisher()
    }

    // MARK: - Mock Control Properties

    /// start()가 호출되었는지 추적
    private(set) var startCallCount: Int = 0
    private(set) var lastStartLocationInfo: LastKnownLocationInfo?

    /// stop()이 호출되었는지 추적
    private(set) var stopCallCount: Int = 0

    /// reset()이 호출되었는지 추적
    private(set) var resetCallCount: Int = 0

    /// 시뮬레이션할 추정 거리
    var simulatedEstimatedDistance: Double = 0

    /// 시뮬레이션할 경과 시간
    var simulatedElapsedTime: TimeInterval = 0

    /// 시뮬레이션할 만료 상태
    var simulatedIsExpired: Bool = false

    /// start() 호출 시 자동으로 상태를 active로 변경할지 여부
    var shouldActivateOnStart: Bool = true

    /// stop() 호출 시 반환할 결과가 있는지 여부
    var shouldReturnResultOnStop: Bool = true

    private var storedLastKnownSpeed: Double = 0

    // MARK: - Public Methods

    func start(with locationInfo: LastKnownLocationInfo) {
        startCallCount += 1
        lastStartLocationInfo = locationInfo
        storedLastKnownSpeed = locationInfo.speed

        if shouldActivateOnStart {
            state = .active
            stateSubject.send(.active)
        }
    }

    @discardableResult
    func stop() -> DeadReckoningResult? {
        stopCallCount += 1

        guard state != .inactive && shouldReturnResultOnStop else {
            return nil
        }

        let result = DeadReckoningResult(
            estimatedDistance: simulatedEstimatedDistance,
            elapsedTime: simulatedElapsedTime,
            lastKnownSpeed: storedLastKnownSpeed,
            isExpired: simulatedIsExpired
        )

        state = .inactive
        stateSubject.send(.inactive)
        estimatedDistance = 0
        estimatedDistanceSubject.send(0)

        return result
    }

    func reset() {
        resetCallCount += 1
        _ = stop()
        simulatedEstimatedDistance = 0
        simulatedElapsedTime = 0
        simulatedIsExpired = false
    }

    func getLastEstimatedDistance() -> Double {
        return simulatedEstimatedDistance
    }

    // MARK: - Mock Control Methods

    /// 추정 거리 수동 업데이트
    func setEstimatedDistance(_ distance: Double) {
        estimatedDistance = distance
        estimatedDistanceSubject.send(distance)
    }

    /// 상태 수동 변경
    func setState(_ newState: DeadReckoningState) {
        state = newState
        stateSubject.send(newState)
    }

    /// 만료 시뮬레이션
    func simulateExpiration() {
        simulatedIsExpired = true
        state = .expired
        stateSubject.send(.expired)
    }

    /// 모든 호출 카운트 리셋
    func resetCallCounts() {
        startCallCount = 0
        stopCallCount = 0
        resetCallCount = 0
    }
}

// MARK: - Mock Location Service Protocol (테스트용)

/// LocationService의 GPS 관련 기능만 추출한 테스트용 프로토콜
protocol GPSTrackingProtocol {
    var gpsSignalState: GPSSignalState { get }
    var isEstimatedDistance: Bool { get }
    var deadReckoningState: DeadReckoningState { get }
    var estimatedDistance: Double { get }
    var lastKnownLocationInfo: LastKnownLocationInfo? { get }
}

/// MockLocationService 기본 구현
final class MockLocationServiceForGPS: GPSTrackingProtocol {

    var gpsSignalState: GPSSignalState = .normal
    var isEstimatedDistance: Bool = false
    var deadReckoningState: DeadReckoningState = .inactive
    var estimatedDistance: Double = 0
    var lastKnownLocationInfo: LastKnownLocationInfo?

    // 추가 추적 프로퍼티
    var totalDistance: Double = 0
    var highSpeedDistance: Double = 0
    var lowSpeedDuration: TimeInterval = 0

    // 메서드 호출 추적
    private(set) var startTrackingCallCount: Int = 0
    private(set) var stopTrackingCallCount: Int = 0

    func startTracking() {
        startTrackingCallCount += 1
        gpsSignalState = .normal
    }

    func stopTracking() {
        stopTrackingCallCount += 1
    }

    /// GPS 신호 상태 변경 시뮬레이션
    func simulateGPSStateChange(to state: GPSSignalState) {
        gpsSignalState = state

        switch state {
        case .normal:
            isEstimatedDistance = false
            deadReckoningState = .inactive
        case .weak, .lost:
            isEstimatedDistance = true
            deadReckoningState = .active
        }
    }

    /// 터널 진입 시뮬레이션
    func simulateTunnelEntry(lastSpeed: Double) {
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        lastKnownLocationInfo = LastKnownLocationInfo(
            location: location,
            speed: lastSpeed / 3.6,  // km/h → m/s
            signalLostAt: Date()
        )
        gpsSignalState = .lost
        isEstimatedDistance = true
        deadReckoningState = .active
    }

    /// 터널 탈출 시뮬레이션
    func simulateTunnelExit(estimatedDistanceToAdd: Double) {
        totalDistance += estimatedDistanceToAdd
        gpsSignalState = .normal
        isEstimatedDistance = false
        deadReckoningState = .inactive
        lastKnownLocationInfo = nil
    }

    /// 리셋
    func reset() {
        gpsSignalState = .normal
        isEstimatedDistance = false
        deadReckoningState = .inactive
        estimatedDistance = 0
        lastKnownLocationInfo = nil
        totalDistance = 0
        highSpeedDistance = 0
        lowSpeedDuration = 0
        startTrackingCallCount = 0
        stopTrackingCallCount = 0
    }
}
