//
//  EasterEggManager.swift
//  HoguMeter
//
//  Created on 2025-12-15.
//

import Foundation
import Observation

/// 이스터에그 감지 및 관리 서비스
@Observable
final class EasterEggManager {

    // MARK: - Published State

    /// 현재 발동된 이스터에그 (nil이면 표시 안함)
    private(set) var triggeredEasterEgg: EasterEgg?

    // MARK: - Private State

    /// 주행 중 발동된 이스터에그 타입 (중복 방지)
    private var triggeredTypes: Set<EasterEggType> = []

    /// 88km/h 유지 시작 시간 (백 투 더 퓨처용)
    private var backToFutureStartTime: Date?

    /// 이스터에그 표시 중 여부
    private var isDisplaying = false

    // MARK: - Constants

    private let backToFutureSpeed: Double = 88.0      // km/h
    private let backToFutureDuration: TimeInterval = 3.0  // 3초 유지
    private let rocketSpeed: Double = 100.0           // km/h
    private let marathonDistance: Double = 42.195     // km
    private let marathonTolerance: Double = 0.010     // ±10m 허용

    // MARK: - Public Methods

    /// 주행 시작 시 호출 - 상태 초기화 및 신데렐라 체크
    func onTripStart(at date: Date = Date()) {
        reset()
        checkCinderella(startTime: date)
    }

    /// 주행 종료 시 호출 - 상태 초기화
    func onTripEnd() {
        reset()
    }

    /// 속도 변경 시 호출
    func checkSpeed(_ speed: Double) {
        guard !isDisplaying else { return }

        // 백 투 더 퓨처 (88km/h 3초 유지)
        checkBackToTheFuture(speed: speed)

        // 광속 호구 (100km/h 이상)
        checkRocketSpeed(speed: speed)
    }

    /// 요금 변경 시 호출
    func checkFare(_ fare: Int) {
        guard !isDisplaying else { return }

        // 연속 숫자 (12,345원)
        if fare == 12345 {
            trigger(.sequentialNumber)
        }

        // 행운의 숫자 (4,444원)
        if fare == 4444 {
            trigger(.luckyNumber)
        }

        // 만원의 행복 (10,000원)
        if fare == 10000 {
            trigger(.perfectTenK)
        }
    }

    /// 거리 변경 시 호출 (km 단위)
    func checkDistance(_ distance: Double) {
        guard !isDisplaying else { return }

        // 마라톤 완주 (42.195km)
        let diff = abs(distance - marathonDistance)
        if diff <= marathonTolerance {
            trigger(.marathon)
        }
    }

    /// 이스터에그 표시 완료 (UI에서 호출)
    func dismissEasterEgg() {
        triggeredEasterEgg = nil
        isDisplaying = false
    }

    // MARK: - Private Methods

    private func reset() {
        triggeredTypes.removeAll()
        triggeredEasterEgg = nil
        backToFutureStartTime = nil
        isDisplaying = false
    }

    private func trigger(_ type: EasterEggType) {
        // 이미 발동된 타입이면 스킵
        guard !triggeredTypes.contains(type) else { return }
        guard !isDisplaying else { return }

        // 이스터에그 데이터 조회
        guard let easterEgg = EasterEgg.get(type) else { return }

        // 발동
        triggeredTypes.insert(type)
        triggeredEasterEgg = easterEgg
        isDisplaying = true

        // 햅틱 피드백
        HapticManager.success()
    }

    // MARK: - Condition Checks

    private func checkCinderella(startTime: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        let minute = calendar.component(.minute, from: startTime)

        // 00:00 ~ 00:01 사이 출발
        if hour == 0 && minute == 0 {
            trigger(.cinderella)
        }
    }

    private func checkBackToTheFuture(speed: Double) {
        if speed >= backToFutureSpeed {
            // 88km/h 이상 - 타이머 시작 또는 유지 체크
            if backToFutureStartTime == nil {
                backToFutureStartTime = Date()
            } else if let startTime = backToFutureStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed >= backToFutureDuration {
                    trigger(.backToTheFuture)
                    backToFutureStartTime = nil
                }
            }
        } else if speed < backToFutureSpeed - 3 {
            // 85km/h 미만이면 리셋 (히스테리시스)
            backToFutureStartTime = nil
        }
    }

    private func checkRocketSpeed(speed: Double) {
        if speed >= rocketSpeed {
            trigger(.rocketSpeed)
        }
    }
}
