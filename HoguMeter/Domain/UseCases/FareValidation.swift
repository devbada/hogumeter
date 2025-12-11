//
//  FareValidation.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import Foundation

/// 지역 요금 검증
struct FareValidation {
    /// 요금 정보 유효성 검증
    static func validate(_ fare: RegionFare) -> [String] {
        var errors: [String] = []

        // 지역명 검증
        if fare.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("지역명을 입력해주세요.")
        }

        // 기본 요금 검증
        if fare.baseFare < 1000 || fare.baseFare > 50000 {
            errors.append("기본요금은 1,000원 ~ 50,000원 사이여야 합니다.")
        }

        // 기본 거리 검증
        if fare.baseDistance < 100 || fare.baseDistance > 10000 {
            errors.append("기본거리는 100m ~ 10,000m 사이여야 합니다.")
        }

        // 거리당 요금 검증
        if fare.distanceFare < 10 || fare.distanceFare > 1000 {
            errors.append("거리당 요금은 10원 ~ 1,000원 사이여야 합니다.")
        }

        // 거리 단위 검증
        if fare.distanceUnit < 10 || fare.distanceUnit > 1000 {
            errors.append("거리 단위는 10m ~ 1,000m 사이여야 합니다.")
        }

        // 시간당 요금 검증
        if fare.timeFare < 10 || fare.timeFare > 1000 {
            errors.append("시간당 요금은 10원 ~ 1,000원 사이여야 합니다.")
        }

        // 시간 단위 검증
        if fare.timeUnit < 10 || fare.timeUnit > 300 {
            errors.append("시간 단위는 10초 ~ 300초 사이여야 합니다.")
        }

        // 야간 할증 배율 검증
        if fare.nightSurchargeRate < 1.0 || fare.nightSurchargeRate > 3.0 {
            errors.append("야간 할증 배율은 1.0배 ~ 3.0배 사이여야 합니다.")
        }

        // 시간 형식 검증
        if !isValidTimeFormat(fare.nightStartTime) {
            errors.append("야간 시작 시간 형식이 올바르지 않습니다. (HH:mm)")
        }

        if !isValidTimeFormat(fare.nightEndTime) {
            errors.append("야간 종료 시간 형식이 올바르지 않습니다. (HH:mm)")
        }

        return errors
    }

    /// 시간 형식 검증 (HH:mm)
    private static func isValidTimeFormat(_ time: String) -> Bool {
        let pattern = "^([0-1][0-9]|2[0-3]):[0-5][0-9]$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: time.utf16.count)
        return regex?.firstMatch(in: time, range: range) != nil
    }
}
