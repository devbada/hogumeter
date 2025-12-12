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

        // 주간 요금 검증
        errors.append(contentsOf: validateTimeZoneFare(
            timeZoneName: "주간",
            baseFare: fare.dayBaseFare,
            baseDistance: fare.dayBaseDistance,
            distanceFare: fare.dayDistanceFare,
            distanceUnit: fare.dayDistanceUnit,
            timeFare: fare.dayTimeFare,
            timeUnit: fare.dayTimeUnit
        ))

        // 심야1 요금 검증
        errors.append(contentsOf: validateTimeZoneFare(
            timeZoneName: "심야1",
            baseFare: fare.night1BaseFare,
            baseDistance: fare.night1BaseDistance,
            distanceFare: fare.night1DistanceFare,
            distanceUnit: fare.night1DistanceUnit,
            timeFare: fare.night1TimeFare,
            timeUnit: fare.night1TimeUnit
        ))

        // 심야2 요금 검증
        errors.append(contentsOf: validateTimeZoneFare(
            timeZoneName: "심야2",
            baseFare: fare.night2BaseFare,
            baseDistance: fare.night2BaseDistance,
            distanceFare: fare.night2DistanceFare,
            distanceUnit: fare.night2DistanceUnit,
            timeFare: fare.night2TimeFare,
            timeUnit: fare.night2TimeUnit
        ))

        return errors
    }

    /// 시간대별 요금 검증
    private static func validateTimeZoneFare(
        timeZoneName: String,
        baseFare: Int,
        baseDistance: Int,
        distanceFare: Int,
        distanceUnit: Int,
        timeFare: Int,
        timeUnit: Int
    ) -> [String] {
        var errors: [String] = []

        // 기본 요금 검증
        if baseFare < 1000 || baseFare > 50000 {
            errors.append("[\(timeZoneName)] 기본요금은 1,000원 ~ 50,000원 사이여야 합니다.")
        }

        // 기본 거리 검증
        if baseDistance < 100 || baseDistance > 10000 {
            errors.append("[\(timeZoneName)] 기본거리는 100m ~ 10,000m 사이여야 합니다.")
        }

        // 거리당 요금 검증
        if distanceFare < 10 || distanceFare > 1000 {
            errors.append("[\(timeZoneName)] 거리당 요금은 10원 ~ 1,000원 사이여야 합니다.")
        }

        // 거리 단위 검증
        if distanceUnit < 10 || distanceUnit > 1000 {
            errors.append("[\(timeZoneName)] 거리 단위는 10m ~ 1,000m 사이여야 합니다.")
        }

        // 시간당 요금 검증
        if timeFare < 10 || timeFare > 1000 {
            errors.append("[\(timeZoneName)] 시간당 요금은 10원 ~ 1,000원 사이여야 합니다.")
        }

        // 시간 단위 검증
        if timeUnit < 10 || timeUnit > 300 {
            errors.append("[\(timeZoneName)] 시간 단위는 10초 ~ 300초 사이여야 합니다.")
        }

        return errors
    }
}
