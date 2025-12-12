//
//  FareCalculator.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class FareCalculator {

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository

    // MARK: - Init
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    // MARK: - Public Methods

    /// 실시간 요금 계산 (현재 시간 기준)
    func calculate(
        distance: Double,           // meters
        lowSpeedDuration: TimeInterval,  // seconds
        regionChanges: Int,
        isNightTime: Bool = false   // Deprecated, 호환성 유지용
    ) -> Int {
        return calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: Date()
        )
    }

    /// 특정 시간 기준 요금 계산
    func calculate(
        distance: Double,           // meters
        lowSpeedDuration: TimeInterval,  // seconds
        regionChanges: Int,
        at date: Date
    ) -> Int {
        let fare = settingsRepository.currentRegionFare
        let timeZone = FareTimeZone.current(from: date)

        // 시간대별 요금 선택
        let fareComponents = fare.getFare(for: timeZone)

        // 기본요금
        var totalFare = fareComponents.baseFare

        // 거리요금 (기본거리 초과분)
        let extraDistance = max(0, distance - Double(fareComponents.baseDistance))
        let distanceUnits = Int(extraDistance / Double(fareComponents.distanceUnit))
        totalFare += distanceUnits * fareComponents.distanceFare

        // 시간요금 (저속 시간)
        let timeUnits = Int(lowSpeedDuration / Double(fareComponents.timeUnit))
        totalFare += timeUnits * fareComponents.timeFare

        // 지역 할증 (시계외)
        if settingsRepository.isRegionSurchargeEnabled {
            let surcharge = Double(totalFare - fareComponents.baseFare) * fare.outsideCitySurcharge
            totalFare += Int(surcharge) * regionChanges
        }

        // 반올림
        totalFare = roundToUnit(totalFare, unit: fare.roundingUnit)

        return totalFare
    }

    /// 요금 상세 내역 계산
    func breakdown(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        isNightTime: Bool = false   // Deprecated, 호환성 유지용
    ) -> FareBreakdown {
        return breakdown(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: regionChanges,
            at: Date()
        )
    }

    /// 특정 시간 기준 요금 상세 내역 계산
    func breakdown(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        at date: Date
    ) -> FareBreakdown {
        let fare = settingsRepository.currentRegionFare
        let timeZone = FareTimeZone.current(from: date)
        let fareComponents = fare.getFare(for: timeZone)

        let baseFare = fareComponents.baseFare

        // 거리요금
        let extraDistance = max(0, distance - Double(fareComponents.baseDistance))
        let distanceUnits = Int(extraDistance / Double(fareComponents.distanceUnit))
        let distanceFare = distanceUnits * fareComponents.distanceFare

        // 시간요금
        let timeUnits = Int(lowSpeedDuration / Double(fareComponents.timeUnit))
        let timeFare = timeUnits * fareComponents.timeFare

        // 지역 할증
        var regionSurcharge = 0
        if settingsRepository.isRegionSurchargeEnabled {
            let surcharge = Double(distanceFare + timeFare) * fare.outsideCitySurcharge
            regionSurcharge = Int(surcharge) * regionChanges
        }

        // 심야 할증 (시간대별 요금에 이미 반영되어 있으므로, 별도 할증은 0)
        // 시간대별로 기본요금이 다르기 때문에 추가 할증 계산 불필요
        let nightSurcharge = 0

        let totalBeforeRounding = baseFare + distanceFare + timeFare + regionSurcharge
        let totalFare = roundToUnit(totalBeforeRounding, unit: fare.roundingUnit)

        return FareBreakdown(
            baseFare: baseFare,
            distanceFare: distanceFare,
            timeFare: timeFare,
            regionSurcharge: regionSurcharge,
            nightSurcharge: nightSurcharge
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
