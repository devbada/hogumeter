//
//  IdleDetectionService.swift
//  HoguMeter
//
//  무이동 감지 서비스
//  미터기 실행 중 일정 시간 동안 이동이 없으면 알림을 표시
//

import Foundation
import CoreLocation
import Combine

// MARK: - Configuration

/// 무이동 감지 설정
enum IdleDetectionConfig {
    /// 무이동 판단 기준 시간 (초)
    static let idleThreshold: TimeInterval = 600  // 10분

    /// 이동으로 판단하는 최소 거리 (미터)
    static let movementThreshold: Double = 50.0

    /// 무이동 체크 주기 (초)
    static let checkInterval: TimeInterval = 30.0
}

// MARK: - State

/// 무이동 감지 상태
enum IdleDetectionState: Equatable {
    /// 모니터링 중 (이동 감지됨)
    case monitoring

    /// 무이동 상태 감지됨 (알림 대기)
    case idle

    /// 알림 표시됨 (사용자 응답 대기)
    case alerted

    /// 알림 해제됨 (사용자가 "계속" 선택)
    case dismissed

    /// 비활성 상태
    case inactive
}

// MARK: - Protocol

protocol IdleDetectionServiceProtocol {
    var statePublisher: AnyPublisher<IdleDetectionState, Never> { get }
    var state: IdleDetectionState { get }
    var idleDuration: TimeInterval { get }

    func startMonitoring()
    func stopMonitoring()
    func updateLocation(_ location: CLLocation)
    func dismissAlert()
    func reset()

    /// Dead Reckoning 활성화 여부 설정
    func setDeadReckoningActive(_ active: Bool)
}

// MARK: - IdleDetectionService

final class IdleDetectionService: IdleDetectionServiceProtocol {

    // MARK: - Publishers

    private let stateSubject = CurrentValueSubject<IdleDetectionState, Never>(.inactive)
    var statePublisher: AnyPublisher<IdleDetectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var state: IdleDetectionState {
        stateSubject.value
    }

    // MARK: - Properties

    /// 마지막 유효 이동 시점
    private var lastMovementTime: Date?

    /// 마지막 위치 (이동 거리 계산용)
    private var lastLocation: CLLocation?

    /// 무이동 체크 타이머
    private var checkTimer: Timer?

    /// Dead Reckoning 활성화 여부
    private var isDeadReckoningActive: Bool = false

    /// 현재 무이동 시간 (초)
    private(set) var idleDuration: TimeInterval = 0

    // MARK: - Init

    init() {}

    deinit {
        stopCheckTimer()
        Logger.gps.debug("[IdleDetection] IdleDetectionService deinit")
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard state == .inactive || state == .dismissed else { return }

        lastMovementTime = Date()
        lastLocation = nil
        idleDuration = 0
        isDeadReckoningActive = false
        stateSubject.send(.monitoring)

        startCheckTimer()
        Logger.gps.info("[IdleDetection] 모니터링 시작")
    }

    func stopMonitoring() {
        stopCheckTimer()
        stateSubject.send(.inactive)
        Logger.gps.info("[IdleDetection] 모니터링 중지")
    }

    func updateLocation(_ location: CLLocation) {
        // 비활성 상태거나 Dead Reckoning 중이면 무시
        guard state == .monitoring || state == .dismissed else { return }
        guard !isDeadReckoningActive else { return }

        // 첫 위치인 경우
        guard let lastLoc = lastLocation else {
            lastLocation = location
            lastMovementTime = Date()
            return
        }

        // 이동 거리 계산
        let distance = location.distance(from: lastLoc)

        // 최소 이동 거리 이상 이동한 경우
        if distance >= IdleDetectionConfig.movementThreshold {
            lastMovementTime = Date()
            lastLocation = location
            idleDuration = 0

            // 무이동 상태였다면 모니터링으로 전환
            if state != .monitoring {
                stateSubject.send(.monitoring)
                Logger.gps.info("[IdleDetection] 이동 감지 - 모니터링 재개")
            }
        } else {
            // 위치는 업데이트하되 이동 시간은 갱신하지 않음
            lastLocation = location
        }
    }

    func dismissAlert() {
        guard state == .idle || state == .alerted else { return }

        stateSubject.send(.dismissed)
        lastMovementTime = Date()
        idleDuration = 0

        // 모니터링 상태로 전환
        stateSubject.send(.monitoring)

        Logger.gps.info("[IdleDetection] 알림 해제 - 모니터링 재개")
    }

    func reset() {
        stopCheckTimer()
        lastMovementTime = nil
        lastLocation = nil
        idleDuration = 0
        isDeadReckoningActive = false
        stateSubject.send(.inactive)
    }

    func setDeadReckoningActive(_ active: Bool) {
        isDeadReckoningActive = active

        if active {
            // Dead Reckoning 중에는 무이동 타이머 일시 정지
            Logger.gps.debug("[IdleDetection] Dead Reckoning 활성화 - 무이동 감지 일시 중지")
        } else {
            // Dead Reckoning 해제 시 타이머 재시작
            if state == .monitoring {
                lastMovementTime = Date()
                Logger.gps.debug("[IdleDetection] Dead Reckoning 해제 - 무이동 감지 재개")
            }
        }
    }

    // MARK: - Private Methods

    private func startCheckTimer() {
        stopCheckTimer()

        checkTimer = Timer.scheduledTimer(
            withTimeInterval: IdleDetectionConfig.checkInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    private func stopCheckTimer() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func checkIdleState() {
        // Dead Reckoning 중이면 체크하지 않음
        guard !isDeadReckoningActive else { return }

        // 모니터링 중일 때만 체크
        guard state == .monitoring else { return }

        guard let lastMovement = lastMovementTime else { return }

        // 무이동 시간 계산
        idleDuration = Date().timeIntervalSince(lastMovement)

        // 임계값 초과 시 무이동 상태로 전환
        if idleDuration >= IdleDetectionConfig.idleThreshold {
            stateSubject.send(.idle)
            Logger.gps.info("[IdleDetection] 무이동 감지 - \(Int(idleDuration / 60))분 경과")
        }
    }
}
