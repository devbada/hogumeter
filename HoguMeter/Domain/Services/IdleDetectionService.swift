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
            notificationSent = false
            cancelScheduledNotification()

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

        cancelScheduledNotification()
        notificationSent = false
        stateSubject.send(.dismissed)
        lastMovementTime = Date()
        idleDuration = 0

        // 모니터링 상태로 전환
        stateSubject.send(.monitoring)

        Logger.gps.info("[IdleDetection] 알림 해제 - 모니터링 재개")
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

    // MARK: - App Lifecycle

    func handleAppBecameActive() {
        isInBackground = false

        // 모니터링 중이 아니면 무시
        guard state == .monitoring || state == .alerted else { return }

        // Dead Reckoning 중이면 무시
        guard !isDeadReckoningActive else { return }

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

            // 백그라운드인 경우 로컬 알림 전송
            if isInBackground && !notificationSent {
                sendIdleNotification()
            }

            Logger.gps.info("[IdleDetection] 무이동 감지 - \(Int(idleDuration / 60))분 경과")
        }
    }

    // MARK: - Notification Methods

    private func scheduleBackgroundNotification() {
        guard hasNotificationPermission else {
            Logger.gps.debug("[IdleDetection] 알림 권한 없음 - 백그라운드 알림 스킵")
            return
        }

        guard let lastMovement = lastMovementTime else { return }

        // 남은 시간 계산
        let elapsed = Date().timeIntervalSince(lastMovement)
        let remaining = IdleDetectionConfig.idleThreshold - elapsed

        guard remaining > 0 else {
            // 이미 임계값 초과 - 즉시 알림
            sendIdleNotification()
            return
        }

        // 남은 시간 후 알림 예약
        let content = createNotificationContent()
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
