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

    /// 실시간 요금 계산
    func calculate(
        distance: Double,           // meters
        lowSpeedDuration: TimeInterval,  // seconds
        regionChanges: Int,
        isNightTime: Bool
    ) -> Int {
        let settings = settingsRepository.currentRegionFare

        // 기본요금
        var fare = settings.baseFare

        // 거리요금 (기본거리 초과분)
        let extraDistance = max(0, distance - Double(settings.baseDistance))
        let distanceUnits = Int(extraDistance / Double(settings.distanceUnit))
        var distanceFare = distanceUnits * settings.distanceFare

        // 시간요금 (저속 시간)
        let timeUnits = Int(lowSpeedDuration / Double(settings.timeUnit))
        var timeFare = timeUnits * settings.timeFare

        // 야간 할증
        if isNightTime && settingsRepository.isNightSurchargeEnabled {
            let rate = settings.nightSurchargeRate
            distanceFare = Int(Double(distanceFare) * rate)
            timeFare = Int(Double(timeFare) * rate)
        }

        fare += distanceFare + timeFare

        // 지역 할증
        if settingsRepository.isRegionSurchargeEnabled {
            fare += regionChanges * settingsRepository.regionSurchargeAmount
        }

        return fare
    }

    /// 요금 상세 내역 계산
    func breakdown(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        isNightTime: Bool
    ) -> FareBreakdown {
        let settings = settingsRepository.currentRegionFare

        let baseFare = settings.baseFare

        let extraDistance = max(0, distance - Double(settings.baseDistance))
        let distanceUnits = Int(extraDistance / Double(settings.distanceUnit))
        var distanceFare = distanceUnits * settings.distanceFare

        let timeUnits = Int(lowSpeedDuration / Double(settings.timeUnit))
        var timeFare = timeUnits * settings.timeFare

        var nightSurcharge = 0
        if isNightTime && settingsRepository.isNightSurchargeEnabled {
            let rate = settings.nightSurchargeRate - 1.0
            nightSurcharge = Int(Double(distanceFare + timeFare) * rate)
            distanceFare = Int(Double(distanceFare) * settings.nightSurchargeRate)
            timeFare = Int(Double(timeFare) * settings.nightSurchargeRate)
        }

        var regionSurcharge = 0
        if settingsRepository.isRegionSurchargeEnabled {
            regionSurcharge = regionChanges * settingsRepository.regionSurchargeAmount
        }

        return FareBreakdown(
            baseFare: baseFare,
            distanceFare: distanceFare,
            timeFare: timeFare,
            regionSurcharge: regionSurcharge,
            nightSurcharge: nightSurcharge
        )
    }

    /// 야간 시간대 확인
    func isNightTime() -> Bool {
        let settings = settingsRepository.currentRegionFare

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let startTime = formatter.date(from: settings.nightStartTime),
              let endTime = formatter.date(from: settings.nightEndTime) else {
            return false
        }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)

        // 야간이 자정을 넘는 경우 (예: 22:00 ~ 04:00)
        if startHour > endHour {
            return currentHour >= startHour || currentHour < endHour
        } else {
            return currentHour >= startHour && currentHour < endHour
        }
    }
}
