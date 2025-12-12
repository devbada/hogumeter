//
//  RegionFare.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

/// 지역별 택시 요금 정보
/// 서울시 택시요금 체계를 기반으로 주간/심야1/심야2 시간대별 요금 관리
struct RegionFare: Identifiable, Codable, Equatable {
    let id: UUID
    var code: String                    // "seoul", "custom_1" 등
    var name: String                    // "서울", "내 지역" 등
    var isDefault: Bool                 // 기본 제공 지역 여부
    var isUserCreated: Bool             // 사용자 생성 여부
    var createdAt: Date
    var updatedAt: Date

    // MARK: - 주간 요금 (04:00 ~ 22:00)

    var dayBaseFare: Int                // 기본요금 (원)
    var dayBaseDistance: Int            // 기본거리 (m)
    var dayDistanceFare: Int            // 거리요금 (원)
    var dayDistanceUnit: Int            // 거리단위 (m)
    var dayTimeFare: Int                // 시간요금 (원)
    var dayTimeUnit: Int                // 시간단위 (초)

    // MARK: - 심야1 요금 (22:00 ~ 23:00, 02:00 ~ 04:00) - 20% 할증

    var night1BaseFare: Int             // 기본요금 (원)
    var night1BaseDistance: Int         // 기본거리 (m)
    var night1DistanceFare: Int         // 거리요금 (원)
    var night1DistanceUnit: Int         // 거리단위 (m)
    var night1TimeFare: Int             // 시간요금 (원)
    var night1TimeUnit: Int             // 시간단위 (초)

    // MARK: - 심야2 요금 (23:00 ~ 02:00) - 40% 할증

    var night2BaseFare: Int             // 기본요금 (원)
    var night2BaseDistance: Int         // 기본거리 (m)
    var night2DistanceFare: Int         // 거리요금 (원)
    var night2DistanceUnit: Int         // 거리단위 (m)
    var night2TimeFare: Int             // 시간요금 (원)
    var night2TimeUnit: Int             // 시간단위 (초)

    // MARK: - 기타 설정

    var lowSpeedThreshold: Double       // 시간·거리 병산 기준 속도 (km/h)
    var outsideCitySurcharge: Double    // 시계외 할증률 (0.2 = 20%)
    var maxCombinedSurcharge: Double    // 최대 중복할증률 (0.6 = 60%)
    var roundingUnit: Int               // 반올림 단위 (10 = 십원단위)

    // MARK: - Computed Properties

    /// 삭제 가능 여부
    var canDelete: Bool {
        !isDefault
    }

    /// 특정 시간대의 요금 정보 가져오기
    func getFare(for timeZone: FareTimeZone) -> FareComponents {
        switch timeZone {
        case .day:
            return FareComponents(
                baseFare: dayBaseFare,
                baseDistance: dayBaseDistance,
                distanceFare: dayDistanceFare,
                distanceUnit: dayDistanceUnit,
                timeFare: dayTimeFare,
                timeUnit: dayTimeUnit
            )
        case .night1:
            return FareComponents(
                baseFare: night1BaseFare,
                baseDistance: night1BaseDistance,
                distanceFare: night1DistanceFare,
                distanceUnit: night1DistanceUnit,
                timeFare: night1TimeFare,
                timeUnit: night1TimeUnit
            )
        case .night2:
            return FareComponents(
                baseFare: night2BaseFare,
                baseDistance: night2BaseDistance,
                distanceFare: night2DistanceFare,
                distanceUnit: night2DistanceUnit,
                timeFare: night2TimeFare,
                timeUnit: night2TimeUnit
            )
        }
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        code: String,
        name: String,
        isDefault: Bool = false,
        isUserCreated: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        // 주간 요금
        dayBaseFare: Int,
        dayBaseDistance: Int,
        dayDistanceFare: Int,
        dayDistanceUnit: Int,
        dayTimeFare: Int,
        dayTimeUnit: Int,
        // 심야1 요금
        night1BaseFare: Int,
        night1BaseDistance: Int,
        night1DistanceFare: Int,
        night1DistanceUnit: Int,
        night1TimeFare: Int,
        night1TimeUnit: Int,
        // 심야2 요금
        night2BaseFare: Int,
        night2BaseDistance: Int,
        night2DistanceFare: Int,
        night2DistanceUnit: Int,
        night2TimeFare: Int,
        night2TimeUnit: Int,
        // 기타
        lowSpeedThreshold: Double = 15.72,
        outsideCitySurcharge: Double = 0.2,
        maxCombinedSurcharge: Double = 0.6,
        roundingUnit: Int = 10
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.isDefault = isDefault
        self.isUserCreated = isUserCreated
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        self.dayBaseFare = dayBaseFare
        self.dayBaseDistance = dayBaseDistance
        self.dayDistanceFare = dayDistanceFare
        self.dayDistanceUnit = dayDistanceUnit
        self.dayTimeFare = dayTimeFare
        self.dayTimeUnit = dayTimeUnit

        self.night1BaseFare = night1BaseFare
        self.night1BaseDistance = night1BaseDistance
        self.night1DistanceFare = night1DistanceFare
        self.night1DistanceUnit = night1DistanceUnit
        self.night1TimeFare = night1TimeFare
        self.night1TimeUnit = night1TimeUnit

        self.night2BaseFare = night2BaseFare
        self.night2BaseDistance = night2BaseDistance
        self.night2DistanceFare = night2DistanceFare
        self.night2DistanceUnit = night2DistanceUnit
        self.night2TimeFare = night2TimeFare
        self.night2TimeUnit = night2TimeUnit

        self.lowSpeedThreshold = lowSpeedThreshold
        self.outsideCitySurcharge = outsideCitySurcharge
        self.maxCombinedSurcharge = maxCombinedSurcharge
        self.roundingUnit = roundingUnit
    }

    /// 서울 기본 요금으로 생성 (factory method)
    static func seoul() -> RegionFare {
        RegionFare(
            code: "seoul",
            name: "서울",
            isDefault: true,
            isUserCreated: false,
            // 주간 요금
            dayBaseFare: 4800,
            dayBaseDistance: 1600,
            dayDistanceFare: 100,
            dayDistanceUnit: 131,
            dayTimeFare: 100,
            dayTimeUnit: 30,
            // 심야1 요금 (20% 할증)
            night1BaseFare: 5800,
            night1BaseDistance: 1600,
            night1DistanceFare: 120,
            night1DistanceUnit: 131,
            night1TimeFare: 120,
            night1TimeUnit: 30,
            // 심야2 요금 (40% 할증)
            night2BaseFare: 6700,
            night2BaseDistance: 1600,
            night2DistanceFare: 140,
            night2DistanceUnit: 131,
            night2TimeFare: 140,
            night2TimeUnit: 30
        )
    }
}

/// 시간대별 요금 구성 요소
struct FareComponents {
    let baseFare: Int           // 기본요금
    let baseDistance: Int       // 기본거리
    let distanceFare: Int       // 거리요금
    let distanceUnit: Int       // 거리단위
    let timeFare: Int           // 시간요금
    let timeUnit: Int           // 시간단위
}
