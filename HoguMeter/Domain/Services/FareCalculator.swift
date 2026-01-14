//
//  FareCalculator.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class FareCalculator {

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepositoryProtocol

    // MARK: - Init
    init(settingsRepository: SettingsRepositoryProtocol) {
        self.settingsRepository = settingsRepository
    }

    // MARK: - Public Methods

    /// 실시간 요금 계산 (현재 시간 기준)
    /// - Parameters:
    ///   - highSpeedDistance: 고속 구간 이동 거리 (meters) - 병산제에서 거리로 계산되는 부분
    ///   - lowSpeedDuration: 저속/정차 시간 (seconds) - 병산제에서 시간으로 계산되는 부분
    func calculate(
        highSpeedDistance: Double,       // meters (고속 구간만)
        lowSpeedDuration: TimeInterval,  // seconds (저속 구간만)
        regionChanges: Int,
        isNightTime: Bool = false   // Deprecated, 호환성 유지용
    ) -> Int {
        return calculate(
            highSpeedDistance: highSpeedDistance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: Date()
        )
    }

    /// 특정 시간 기준 요금 계산 (병산제 적용)
    /// - Parameters:
    ///   - highSpeedDistance: 고속 구간 이동 거리 (meters)
    ///   - lowSpeedDuration: 저속/정차 시간 (seconds)
    ///   - regionChanges: 지역 변경 횟수 (재미 모드용)
    ///   - surchargeStatus: 할증 상태 (리얼 모드용, nil이면 재미 모드로 동작)
    func calculate(
        highSpeedDistance: Double,       // meters (고속 구간만)
        lowSpeedDuration: TimeInterval,  // seconds (저속 구간만)
        regionChanges: Int,
        at date: Date,
        surchargeStatus: SurchargeStatus? = nil
    ) -> Int {
        let fare = settingsRepository.currentRegionFare
        let timeZone = FareTimeZone.current(from: date)

        // 시간대별 요금 선택
        let fareComponents = fare.getFare(for: timeZone)

        // 기본요금
        var totalFare = fareComponents.baseFare

        // 병산제: 고속 거리와 저속 시간을 "유닛"으로 환산
        let distanceUnits = highSpeedDistance / Double(fareComponents.distanceUnit)
        let timeUnits = lowSpeedDuration / Double(fareComponents.timeUnit)
        let totalUnits = distanceUnits + timeUnits

        // 기본 유닛 (기본거리에 해당하는 유닛 수)
        let baseUnits = Double(fareComponents.baseDistance) / Double(fareComponents.distanceUnit)

        // 추가 요금 유닛 (기본 유닛 초과분만)
        let extraUnits = Int(max(0, totalUnits - baseUnits))
        totalFare += extraUnits * fareComponents.distanceFare

        // 지역 할증 (모드에 따라 다르게 처리)
        let surchargeMode = settingsRepository.regionalSurchargeMode
        switch surchargeMode {
        case .realistic:
            // 리얼 모드: 할증 구간에서 발생한 요금에 할증률 적용
            if let status = surchargeStatus, status.isActive {
                let extraFare = extraUnits * fareComponents.distanceFare
                let surcharge = Double(extraFare) * status.rate
                totalFare += Int(surcharge)
            }

        case .fun:
            // 재미 모드: 동 변경 횟수 × 고정 금액
            if regionChanges > 0 {
                let surchargeAmount = settingsRepository.regionSurchargeAmount
                totalFare += surchargeAmount * regionChanges
            }

        case .off:
            // 끄기: 할증 없음
            break
        }

        // 반올림
        totalFare = roundToUnit(totalFare, unit: fare.roundingUnit)

        return totalFare
    }

    // MARK: - Legacy Support (기존 API 호환용)

    /// 기존 API 호환용 - 총 거리 기반 계산 (테스트용)
    func calculate(
        distance: Double,           // meters (총 거리)
        lowSpeedDuration: TimeInterval,  // seconds
        regionChanges: Int,
        isNightTime: Bool = false
    ) -> Int {
        // 기존 테스트 호환: distance를 고속 거리로 취급
        return calculate(
            highSpeedDistance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: Date()
        )
    }

    func calculate(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        at date: Date
    ) -> Int {
        return calculate(
            highSpeedDistance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: date
        )
    }

    /// 요금 상세 내역 계산 (병산제 적용)
    /// - Parameters:
    ///   - highSpeedDistance: 고속 구간 이동 거리 (meters)
    ///   - lowSpeedDuration: 저속/정차 시간 (seconds)
    func breakdown(
        highSpeedDistance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        isNightTime: Bool = false
    ) -> FareBreakdown {
        return breakdown(
            highSpeedDistance: highSpeedDistance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: Date()
        )
    }

    /// 특정 시간 기준 요금 상세 내역 계산 (병산제 적용)
    func breakdown(
        highSpeedDistance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        at date: Date
    ) -> FareBreakdown {
        let fare = settingsRepository.currentRegionFare
        let timeZone = FareTimeZone.current(from: date)
        let fareComponents = fare.getFare(for: timeZone)

        let baseFare = fareComponents.baseFare

        // 병산제: 유닛 계산
        let distanceUnitsRaw = highSpeedDistance / Double(fareComponents.distanceUnit)
        let timeUnitsRaw = lowSpeedDuration / Double(fareComponents.timeUnit)
        let totalUnitsRaw = distanceUnitsRaw + timeUnitsRaw

        // 기본 유닛
        let baseUnits = Double(fareComponents.baseDistance) / Double(fareComponents.distanceUnit)

        // 추가 유닛 (기본 유닛 초과분만)
        let extraUnitsRaw = max(0, totalUnitsRaw - baseUnits)

        // 거리/시간 비율에 따라 추가 요금 분배 (표시용)
        let totalRawUnits = distanceUnitsRaw + timeUnitsRaw
        var distanceFare = 0
        var timeFare = 0

        if totalRawUnits > 0 && extraUnitsRaw > 0 {
            let distanceRatio = distanceUnitsRaw / totalRawUnits
            let timeRatio = timeUnitsRaw / totalRawUnits

            let extraUnits = Int(extraUnitsRaw)
            let extraFare = extraUnits * fareComponents.distanceFare

            distanceFare = Int(Double(extraFare) * distanceRatio)
            timeFare = extraFare - distanceFare  // 나머지는 시간요금으로
        }

        // 지역 할증
        var regionSurcharge = 0
        if settingsRepository.isRegionSurchargeEnabled {
            let surcharge = Double(distanceFare + timeFare) * fare.outsideCitySurcharge
            regionSurcharge = Int(surcharge) * regionChanges
        }

        // 심야 할증 (시간대별 요금에 이미 반영되어 있으므로, 별도 할증은 0)
        let nightSurcharge = 0

        return FareBreakdown(
            baseFare: baseFare,
            distanceFare: distanceFare,
            timeFare: timeFare,
            regionSurcharge: regionSurcharge,
            nightSurcharge: nightSurcharge
        )
    }

    // Legacy breakdown (기존 API 호환용)
    func breakdown(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        isNightTime: Bool = false
    ) -> FareBreakdown {
        return breakdown(
            highSpeedDistance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: Date()
        )
    }

    func breakdown(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        at date: Date
    ) -> FareBreakdown {
        return breakdown(
            highSpeedDistance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: date
        )
    }

    /// 현재 시간대 확인
    func currentTimeZone() -> FareTimeZone {
        return FareTimeZone.current()
    }

    /// 야간 시간대 확인 (Deprecated - FareTimeZone 사용 권장)
    func isNightTime() -> Bool {
        let timeZone = FareTimeZone.current()
        return timeZone != .day
    }

    // MARK: - Private Methods

    /// 지정된 단위로 반올림
    private func roundToUnit(_ value: Int, unit: Int) -> Int {
        return ((value + unit / 2) / unit) * unit
    }
}
