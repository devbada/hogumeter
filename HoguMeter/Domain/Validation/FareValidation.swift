//
//  FareValidation.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import Foundation

/// 지역 요금 유효성 검사
struct FareValidation {

    /// 지역 요금의 유효성을 검사하고 에러 메시지 배열 반환
    static func validate(_ fare: RegionFare) -> [String] {
        var errors: [String] = []

        // 지역명 검사
        if fare.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("지역명을 입력해주세요")
        }

        // 기본요금 검사
        if fare.baseFare < 0 {
            errors.append("기본요금은 0원 이상이어야 합니다")
        }
        if fare.baseFare > 100000 {
            errors.append("기본요금이 너무 높습니다 (최대 100,000원)")
        }

        // 기본거리 검사
        if fare.baseDistance <= 0 {
            errors.append("기본거리는 1m 이상이어야 합니다")
        }
        if fare.baseDistance > 10000 {
            errors.append("기본거리가 너무 큽니다 (최대 10,000m)")
        }

        // 거리요금 검사
        if fare.distanceFare < 0 {
            errors.append("거리요금은 0원 이상이어야 합니다")
        }
        if fare.distanceFare > 10000 {
            errors.append("거리요금이 너무 높습니다 (최대 10,000원)")
        }

        // 거리단위 검사
        if fare.distanceUnit <= 0 {
            errors.append("거리단위는 1m 이상이어야 합니다")
        }
        if fare.distanceUnit > 1000 {
            errors.append("거리단위가 너무 큽니다 (최대 1,000m)")
        }

        // 시간요금 검사
        if fare.timeFare < 0 {
            errors.append("시간요금은 0원 이상이어야 합니다")
        }
        if fare.timeFare > 10000 {
            errors.append("시간요금이 너무 높습니다 (최대 10,000원)")
        }

        // 시간단위 검사
        if fare.timeUnit <= 0 {
            errors.append("시간단위는 1초 이상이어야 합니다")
        }
        if fare.timeUnit > 300 {
            errors.append("시간단위가 너무 큽니다 (최대 300초)")
        }

        // 야간할증 배율 검사
        if fare.nightSurchargeRate < 1.0 {
            errors.append("야간할증 배율은 1.0 이상이어야 합니다")
        }
        if fare.nightSurchargeRate > 3.0 {
            errors.append("야간할증 배율이 너무 높습니다 (최대 3.0)")
        }

        // 야간 시간 형식 검사
        if !isValidTimeFormat(fare.nightStartTime) {
            errors.append("야간 시작 시간 형식이 올바르지 않습니다 (HH:mm)")
        }
        if !isValidTimeFormat(fare.nightEndTime) {
            errors.append("야간 종료 시간 형식이 올바르지 않습니다 (HH:mm)")
        }

        return errors
    }

    /// 시간 형식 검사 (HH:mm)
    private static func isValidTimeFormat(_ time: String) -> Bool {
        let pattern = "^([0-1][0-9]|2[0-3]):[0-5][0-9]$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: time.utf16.count)
        return regex?.firstMatch(in: time, options: [], range: range) != nil
    }

    /// 유효성 검사 성공 여부
    static func isValid(_ fare: RegionFare) -> Bool {
        return validate(fare).isEmpty
    }
}
