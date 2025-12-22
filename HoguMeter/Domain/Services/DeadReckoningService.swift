//
//  DeadReckoningService.swift
//  HoguMeter
//
//  Created on 2025-12-22.
//

import Foundation
import Combine

/// Dead Reckoning 설정 상수
enum DeadReckoningConfig {
    /// 최대 추정 시간 (초) - 3분
    static let maxDuration: TimeInterval = 180.0

    /// 최소 속도 임계값 (m/s) - 5 km/h 미만은 정차로 간주
    static let minSpeedThreshold: Double = 5.0 / 3.6  // 1.39 m/s

    /// 최대 속도 임계값 (m/s) - 200 km/h 초과는 무시
    static let maxSpeedThreshold: Double = 200.0 / 3.6  // 55.56 m/s

    /// 업데이트 간격 (초)
    static let updateInterval: TimeInterval = 1.0

    /// 로그 출력 간격 (초)
    static let logInterval: TimeInterval = 10.0
}

/// Dead Reckoning 상태
enum DeadReckoningState: Equatable {
    case inactive           // 비활성 (GPS 정상)
    case active             // 활성 (GPS 손실, 추정 중)
    case expired            // 만료됨 (180초 초과)
}

/// Dead Reckoning 결과
struct DeadReckoningResult {
    let estimatedDistance: Double       // 추정 거리 (meters)
    let elapsedTime: TimeInterval       // 경과 시간 (seconds)
    let lastKnownSpeed: Double          // 마지막 속도 (m/s)
    let isExpired: Bool                 // 만료 여부 (180초 초과)

    /// 추정 거리 (km 단위)
    var estimatedDistanceKm: Double {
        return estimatedDistance / 1000.0
    }

    /// 마지막 속도 (km/h 단위)
    var lastKnownSpeedKmh: Double {
        return lastKnownSpeed * 3.6
    }
}

/// Dead Reckoning 서비스
/// GPS 신호 손실 시 마지막 속도와 경과 시간을 기반으로 거리 추정
final class DeadReckoningService {

    // MARK: - Published Properties

    /// 현재 Dead Reckoning 상태
    private(set) var state: DeadReckoningState = .inactive

    /// 추정 거리 (meters)
    private(set) var estimatedDistance: Double = 0

    /// 추정 중 여부
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

    // MARK: - Private Properties

    private var updateTimer: Timer?
    private var startTime: Date?
    private var lastKnownSpeed: Double = 0
    private var lastLogTime: Date?
    private var totalEstimatedDistance: Double = 0  // 최종 누적 거리

    // MARK: - Public Methods

    /// Dead Reckoning 시작
    /// - Parameter locationInfo: 마지막으로 유효한 위치 정보
    func start(with locationInfo: LastKnownLocationInfo) {
        // 이미 활성 상태면 무시
        guard state == .inactive else {
            Logger.gps.debug("[DR] 이미 Dead Reckoning 활성 상태")
            return
        }

        let speed = locationInfo.speed

        // 속도 유효성 검사
        guard isValidSpeed(speed) else {
            Logger.gps.info("[DR] Dead Reckoning 시작 불가 - 속도 부적합: \(String(format: "%.1f", speed * 3.6)) km/h")
            return
        }

        lastKnownSpeed = min(speed, DeadReckoningConfig.maxSpeedThreshold)
        estimatedDistance = 0
        startTime = Date()
        lastLogTime = Date()

        state = .active
        stateSubject.send(.active)

        startUpdateTimer()

        Logger.gps.info("[DR] Dead Reckoning 시작 - 속도: \(String(format: "%.1f", lastKnownSpeed * 3.6)) km/h")
    }

    /// Dead Reckoning 중지 및 결과 반환
    /// - Returns: 추정 결과 (nil이면 비활성 상태였음)
    @discardableResult
    func stop() -> DeadReckoningResult? {
        guard state != .inactive else {
            return nil
        }

        stopUpdateTimer()

        let elapsedTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
        let isExpired = state == .expired

        let result = DeadReckoningResult(
            estimatedDistance: estimatedDistance,
            elapsedTime: elapsedTime,
            lastKnownSpeed: lastKnownSpeed,
            isExpired: isExpired
        )

        // 최종 누적 거리 저장
        totalEstimatedDistance = estimatedDistance

        Logger.gps.info("[DR] Dead Reckoning 종료 - 추정 거리: \(String(format: "%.0f", estimatedDistance))m, 경과 시간: \(String(format: "%.0f", elapsedTime))초")

        // 상태 초기화
        state = .inactive
        stateSubject.send(.inactive)
        estimatedDistance = 0
        estimatedDistanceSubject.send(0)
        startTime = nil
        lastKnownSpeed = 0

        return result
    }

    /// 리셋 (새 주행 시작 시)
    func reset() {
        stop()
        totalEstimatedDistance = 0
    }

    /// 마지막 Dead Reckoning에서 추정된 총 거리
    func getLastEstimatedDistance() -> Double {
        return totalEstimatedDistance
    }

    // MARK: - Private Methods

    private func isValidSpeed(_ speed: Double) -> Bool {
        // 속도가 음수이거나 최소 임계값 미만이면 무효
        guard speed >= DeadReckoningConfig.minSpeedThreshold else {
            return false
        }
        return true
    }

    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: DeadReckoningConfig.updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateEstimation()
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateEstimation() {
        guard state == .active, let start = startTime else { return }

        let elapsedTime = Date().timeIntervalSince(start)

        // 시간 제한 확인
        if elapsedTime >= DeadReckoningConfig.maxDuration {
            handleExpiration()
            return
        }

        // 거리 추정: 속도 × 시간 (1초마다 업데이트)
        let distanceIncrement = lastKnownSpeed * DeadReckoningConfig.updateInterval
        estimatedDistance += distanceIncrement
        estimatedDistanceSubject.send(estimatedDistance)

        // 주기적 로그 출력
        logPeriodically()
    }

    private func handleExpiration() {
        Logger.gps.warning("[DR] Dead Reckoning 만료 (180초 초과) - 추정 거리: \(String(format: "%.0f", estimatedDistance))m")

        stopUpdateTimer()

        state = .expired
        stateSubject.send(.expired)

        // 만료 후에도 마지막 추정 거리는 유지 (GPS 복구 시 사용)
        totalEstimatedDistance = estimatedDistance
    }

    private func logPeriodically() {
        guard let lastLog = lastLogTime else {
            lastLogTime = Date()
            return
        }

        let timeSinceLastLog = Date().timeIntervalSince(lastLog)
        if timeSinceLastLog >= DeadReckoningConfig.logInterval {
            let elapsedTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
            Logger.gps.info("[DR] 추정 중 - 거리: \(String(format: "%.0f", estimatedDistance))m, 경과: \(String(format: "%.0f", elapsedTime))초")
            lastLogTime = Date()
        }
    }
}
