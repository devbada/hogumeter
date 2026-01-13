//
//  IdleDetectionService.swift
//  HoguMeter
//
//  무이동 감지 서비스
//  미터기 실행 중 일정 시간 동안 이동이 없으면 알림을 표시
//  백그라운드에서도 로컬 알림을 통해 사용자에게 알림
//

import Foundation
import CoreLocation
import Combine
import UserNotifications

// MARK: - Configuration

/// 무이동 감지 설정
enum IdleDetectionConfig {
    /// 무이동 판단 기준 시간 (초)
    static let idleThreshold: TimeInterval = 600  // 10분

    /// 이동으로 판단하는 최소 거리 (미터)
    static let movementThreshold: Double = 50.0

    /// 무이동 체크 주기 (초)
    static let checkInterval: TimeInterval = 30.0

    // MARK: - GPS Accuracy & Jump Filtering

    /// 이동으로 인정하기 위한 최소 GPS 정확도 (미터)
    /// 이 값보다 정확도가 나쁘면 (horizontalAccuracy > 값) 이동으로 인정하지 않음
    /// 실내 GPS 점프 방지를 위해 30m로 설정 (GPSSignalState.normal 기준과 동일)
    static let minGPSAccuracyForMovement: Double = 30.0

    /// GPS 점프로 판단하는 최대 속도 (km/h)
    /// 이 속도를 초과하는 이동은 GPS 점프로 간주하여 무시
    /// 200km/h 이상은 현실적으로 불가능한 속도
    static let maxRealisticSpeedKmh: Double = 200.0

    // MARK: - Notification Config

    /// 알림 카테고리 식별자
    static let notificationCategoryIdentifier = "IDLE_ALERT"

    /// 알림 식별자
    static let notificationIdentifier = "idle-detection-alert"

    /// 계속 액션 식별자
    static let continueActionIdentifier = "CONTINUE"

    /// 종료 액션 식별자
    static let stopActionIdentifier = "STOP"
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
    func markAlerted()
    func reset()

    /// Dead Reckoning 활성화 여부 설정
    func setDeadReckoningActive(_ active: Bool)

    /// 앱이 포그라운드로 돌아왔을 때 호출
    func handleAppBecameActive()

    /// 앱이 백그라운드로 전환될 때 호출
    func handleAppEnteredBackground()

    /// 알림 권한 요청
    func requestNotificationPermission()

    /// 알림 카테고리 설정
    static func setupNotificationCategories()
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

    /// 앱이 백그라운드에 있는지 여부
    private var isInBackground: Bool = false

    /// 알림 권한 상태
    private var hasNotificationPermission: Bool = false

    /// 알림이 전송되었는지 여부 (중복 방지)
    private var notificationSent: Bool = false

    // MARK: - Init

    init() {
        checkNotificationPermission()
    }

    deinit {
        stopCheckTimer()
        cancelScheduledNotification()
        Logger.gps.debug("[IdleDetection] IdleDetectionService deinit")
    }

    // MARK: - Static Methods

    /// 알림 카테고리 설정 (앱 시작 시 호출)
    static func setupNotificationCategories() {
        let continueAction = UNNotificationAction(
            identifier: IdleDetectionConfig.continueActionIdentifier,
            title: "계속",
            options: [.foreground]
        )

        let stopAction = UNNotificationAction(
            identifier: IdleDetectionConfig.stopActionIdentifier,
            title: "종료",
            options: [.foreground, .destructive]
        )

        let category = UNNotificationCategory(
            identifier: IdleDetectionConfig.notificationCategoryIdentifier,
            actions: [continueAction, stopAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
        Logger.gps.info("[IdleDetection] 알림 카테고리 설정 완료")
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard state == .inactive || state == .dismissed else { return }

        lastMovementTime = Date()
        lastLocation = nil
        idleDuration = 0
        isDeadReckoningActive = false
        notificationSent = false
        stateSubject.send(.monitoring)

        startCheckTimer()
        Logger.gps.info("[IdleDetection] 모니터링 시작")
    }

    func stopMonitoring() {
        stopCheckTimer()
        cancelScheduledNotification()
        notificationSent = false
        stateSubject.send(.inactive)
        Logger.gps.info("[IdleDetection] 모니터링 중지")
    }

    func updateLocation(_ location: CLLocation) {
        // 비활성 상태거나 Dead Reckoning 중이면 무시
        guard state == .monitoring || state == .dismissed else { return }
        guard !isDeadReckoningActive else { return }

        // 첫 위치인 경우 - GPS 정확도가 좋을 때만 저장
        guard let lastLoc = lastLocation else {
            // 정확도가 좋은 위치만 기준점으로 저장
            if isAccuracyGoodForMovement(location) {
                lastLocation = location
                lastMovementTime = Date()
                Logger.gps.debug("[IdleDetection] 첫 위치 저장 (정확도: \(String(format: "%.0f", location.horizontalAccuracy))m)")
            } else {
                Logger.gps.debug("[IdleDetection] 첫 위치 무시 - 정확도 불량 (\(String(format: "%.0f", location.horizontalAccuracy))m)")
            }
            return
        }

        // 이동 거리 계산
        let distance = location.distance(from: lastLoc)

        // 이동으로 인정되는지 검사 (거리 + GPS 정확도 + 속도 검증)
        if shouldRecordMovement(from: lastLoc, to: location, distance: distance) {
            lastMovementTime = Date()
            lastLocation = location
            idleDuration = 0
            notificationSent = false
            cancelScheduledNotification()

            // 무이동 상태였다면 모니터링으로 전환
            if state != .monitoring {
                stateSubject.send(.monitoring)
                Logger.gps.info("[IdleDetection] 이동 감지 - 모니터링 재개")
            }

            Logger.gps.debug("[IdleDetection] 이동 감지 (거리: \(String(format: "%.0f", distance))m, 정확도: \(String(format: "%.0f", location.horizontalAccuracy))m) - 타이머 리셋")
        }
        // else: 이동 거리가 threshold 미만이거나 GPS 정확도/속도 검증 실패 시
        // lastLocation을 업데이트하지 않음 - 작은 이동들이 누적될 수 있도록
    }

    // MARK: - Movement Validation

    /// 이동으로 기록해야 하는지 검사
    /// - Parameters:
    ///   - lastLocation: 이전 위치
    ///   - newLocation: 새 위치
    ///   - distance: 계산된 거리 (미터)
    /// - Returns: 이동으로 인정되면 true
    private func shouldRecordMovement(from lastLocation: CLLocation, to newLocation: CLLocation, distance: Double) -> Bool {
        // 1. 거리 임계값 검사
        guard distance >= IdleDetectionConfig.movementThreshold else {
            return false
        }

        // 2. 새 위치의 GPS 정확도 검사
        guard isAccuracyGoodForMovement(newLocation) else {
            Logger.gps.debug("[IdleDetection] 이동 무시 - 새 위치 정확도 불량 (\(String(format: "%.0f", newLocation.horizontalAccuracy))m, 거리: \(String(format: "%.0f", distance))m)")
            return false
        }

        // 3. 이전 위치의 GPS 정확도 검사
        guard isAccuracyGoodForMovement(lastLocation) else {
            // 이전 위치 정확도가 불량하면, 새 위치를 기준점으로 업데이트
            // 하지만 이동으로 인정하지는 않음 (타이머 리셋 안 함)
            Logger.gps.debug("[IdleDetection] 이동 무시 - 이전 위치 정확도 불량, 기준점 갱신만 수행")
            return false
        }

        // 4. GPS 점프 검사 (비현실적 속도 필터링)
        if isLikelyGPSJump(from: lastLocation, to: newLocation, distance: distance) {
            Logger.gps.debug("[IdleDetection] 이동 무시 - GPS 점프로 판단 (거리: \(String(format: "%.0f", distance))m)")
            return false
        }

        return true
    }

    /// GPS 정확도가 이동 인정 기준을 충족하는지 검사
    /// - Parameter location: 검사할 위치
    /// - Returns: 정확도가 좋으면 true
    private func isAccuracyGoodForMovement(_ location: CLLocation) -> Bool {
        // 음수는 유효하지 않은 정확도
        guard location.horizontalAccuracy >= 0 else { return false }
        // 설정된 임계값보다 정확도가 좋아야 함 (값이 작을수록 정확)
        return location.horizontalAccuracy < IdleDetectionConfig.minGPSAccuracyForMovement
    }

    /// GPS 점프인지 검사 (비현실적으로 빠른 이동 감지)
    /// - Parameters:
    ///   - lastLocation: 이전 위치
    ///   - newLocation: 새 위치
    ///   - distance: 계산된 거리 (미터)
    /// - Returns: GPS 점프로 판단되면 true
    private func isLikelyGPSJump(from lastLocation: CLLocation, to newLocation: CLLocation, distance: Double) -> Bool {
        // 시간 차이 계산
        let timeDelta = newLocation.timestamp.timeIntervalSince(lastLocation.timestamp)

        // 시간 차이가 너무 작으면 (0.1초 미만) 속도 계산 불가
        guard timeDelta >= 0.1 else { return false }

        // 속도 계산 (km/h)
        let speedMs = distance / timeDelta  // m/s
        let speedKmh = speedMs * 3.6        // km/h

        // 최대 현실적 속도 초과 시 GPS 점프로 판단
        if speedKmh > IdleDetectionConfig.maxRealisticSpeedKmh {
            Logger.gps.debug("[IdleDetection] GPS 점프 감지 - 속도: \(String(format: "%.0f", speedKmh))km/h (거리: \(String(format: "%.0f", distance))m, 시간: \(String(format: "%.1f", timeDelta))초)")
            return true
        }

        return false
    }

    func dismissAlert() {
        guard state == .idle || state == .alerted else { return }

        cancelScheduledNotification()
        notificationSent = false
        stateSubject.send(.dismissed)
        lastMovementTime = Date()
        idleDuration = 0

        // 모니터링 상태로 전환
        stateSubject.send(.monitoring)

        Logger.gps.info("[IdleDetection] 알림 해제 - 모니터링 재개")
    }

    func markAlerted() {
        guard state == .idle else { return }
        stateSubject.send(.alerted)
        Logger.gps.info("[IdleDetection] 알림 표시됨 - 사용자 응답 대기")
    }

    func reset() {
        stopCheckTimer()
        cancelScheduledNotification()
        lastMovementTime = nil
        lastLocation = nil
        idleDuration = 0
        isDeadReckoningActive = false
        notificationSent = false
        stateSubject.send(.inactive)
    }

    func setDeadReckoningActive(_ active: Bool) {
        isDeadReckoningActive = active

        if active {
            Logger.gps.debug("[IdleDetection] Dead Reckoning 활성화 - 무이동 감지는 계속됨")
        } else {
            // Dead Reckoning 해제 시에도 타이머 리셋 안 함
            // GPS 복구 후 실제 이동이 감지되면 updateLocation()에서 리셋됨
            Logger.gps.debug("[IdleDetection] Dead Reckoning 해제")
        }
    }

    // MARK: - App Lifecycle

    func handleAppBecameActive() {
        isInBackground = false

        // 모니터링 중이 아니면 무시
        guard state == .monitoring || state == .alerted else { return }

        // Note: Dead Reckoning 중에도 처리 수행
        // GPS 신호가 없어도 무이동 체크 필요

        // 마지막 이동 시간이 없으면 무시
        guard let lastMovement = lastMovementTime else { return }

        // 무이동 시간 재계산
        idleDuration = Date().timeIntervalSince(lastMovement)

        Logger.gps.info("[IdleDetection] 앱 활성화 - 무이동 시간 재계산: \(Int(idleDuration / 60))분")

        // 임계값 초과 시 즉시 알림
        if idleDuration >= IdleDetectionConfig.idleThreshold && state != .idle && state != .alerted {
            stateSubject.send(.idle)
            Logger.gps.info("[IdleDetection] 백그라운드에서 무이동 감지 - 알림 표시")
        }

        // 타이머 재시작
        startCheckTimer()
    }

    func handleAppEnteredBackground() {
        isInBackground = true

        // 모니터링 중이면 백그라운드 알림 예약
        if state == .monitoring && !notificationSent {
            scheduleBackgroundNotification()
        }

        Logger.gps.debug("[IdleDetection] 앱 백그라운드 진입")
    }

    // MARK: - Notification Permission

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasNotificationPermission = granted
                if granted {
                    Logger.gps.info("[IdleDetection] 알림 권한 허용됨")
                } else {
                    Logger.gps.warning("[IdleDetection] 알림 권한 거부됨: \(error?.localizedDescription ?? "unknown")")
                }
            }
        }
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasNotificationPermission = settings.authorizationStatus == .authorized
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
        // 모니터링 중일 때만 체크
        // Note: Dead Reckoning 중에도 idle 체크 수행
        // GPS 신호가 없어도 사용자가 정지해 있으면 알림 필요
        guard state == .monitoring else { return }

        guard let lastMovement = lastMovementTime else { return }

        // 무이동 시간 계산
        idleDuration = Date().timeIntervalSince(lastMovement)

        // 디버그 로그 (5분마다)
        let minutes = Int(idleDuration / 60)
        let seconds = Int(idleDuration) % 60
        if seconds == 0 && minutes > 0 && minutes % 5 == 0 {
            Logger.gps.debug("[IdleDetection] 무이동 경과: \(minutes)분 (임계값: \(Int(IdleDetectionConfig.idleThreshold / 60))분)")
        }

        // 임계값 초과 시 무이동 상태로 전환
        if idleDuration >= IdleDetectionConfig.idleThreshold {
            stateSubject.send(.idle)

            // 백그라운드인 경우 로컬 알림 전송 (실시간 권한 확인)
            if isInBackground && !notificationSent {
                sendIdleNotificationDirectly()
            }

            Logger.gps.info("[IdleDetection] 무이동 감지 - \(minutes)분 경과")
        }
    }

    // MARK: - Notification Methods

    private func scheduleBackgroundNotification() {
        guard let lastMovement = lastMovementTime else {
            Logger.gps.debug("[IdleDetection] lastMovementTime 없음 - 백그라운드 알림 스킵")
            return
        }

        // 남은 시간 계산
        let elapsed = Date().timeIntervalSince(lastMovement)
        let remaining = IdleDetectionConfig.idleThreshold - elapsed

        guard remaining > 0 else {
            // 이미 임계값 초과 - 즉시 알림
            sendIdleNotificationDirectly()
            return
        }

        // 알림 권한을 직접 확인 후 예약 (캐시된 값 대신 실시간 확인)
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            guard settings.authorizationStatus == .authorized else {
                Logger.gps.debug("[IdleDetection] 알림 권한 없음 - 백그라운드 알림 스킵 (status: \(settings.authorizationStatus.rawValue))")
                return
            }

            // 남은 시간 후 알림 예약
            let content = self.createNotificationContent()
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: remaining,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: IdleDetectionConfig.notificationIdentifier,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    Logger.gps.error("[IdleDetection] 알림 예약 실패: \(error.localizedDescription)")
                } else {
                    Logger.gps.info("[IdleDetection] 백그라운드 알림 예약됨 - \(Int(remaining))초 후")
                }
            }
        }
    }

    /// 알림을 직접 전송 (권한 실시간 확인)
    private func sendIdleNotificationDirectly() {
        guard !notificationSent else { return }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            guard settings.authorizationStatus == .authorized else {
                Logger.gps.debug("[IdleDetection] 알림 권한 없음 - 즉시 알림 스킵")
                return
            }

            self.notificationSent = true

            let content = self.createNotificationContent()

            let request = UNNotificationRequest(
                identifier: IdleDetectionConfig.notificationIdentifier,
                content: content,
                trigger: nil  // 즉시 전송
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    Logger.gps.error("[IdleDetection] 즉시 알림 전송 실패: \(error.localizedDescription)")
                } else {
                    Logger.gps.info("[IdleDetection] 무이동 즉시 알림 전송됨")
                }
            }
        }
    }

    private func sendIdleNotification() {
        guard hasNotificationPermission else { return }
        guard !notificationSent else { return }

        notificationSent = true

        let content = createNotificationContent()

        let request = UNNotificationRequest(
            identifier: IdleDetectionConfig.notificationIdentifier,
            content: content,
            trigger: nil  // 즉시 전송
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.gps.error("[IdleDetection] 알림 전송 실패: \(error.localizedDescription)")
            } else {
                Logger.gps.info("[IdleDetection] 무이동 알림 전송됨")
            }
        }
    }

    private func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "이동이 감지되지 않습니다"
        content.body = "10분 동안 이동이 없습니다. 미터기를 계속 실행하시겠습니까?"
        content.sound = .default
        content.categoryIdentifier = IdleDetectionConfig.notificationCategoryIdentifier
        return content
    }

    private func cancelScheduledNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [IdleDetectionConfig.notificationIdentifier]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [IdleDetectionConfig.notificationIdentifier]
        )
    }
}
