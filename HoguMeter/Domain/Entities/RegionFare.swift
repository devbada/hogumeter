//
//  RegionFare.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

struct RegionFare: Identifiable, Codable {
    let id: UUID
    var code: String
    var name: String
    var baseFare: Int           // 기본요금 (원)
    var baseDistance: Int       // 기본거리 (m)
    var distanceFare: Int       // 거리요금 (원)
    var distanceUnit: Int       // 거리단위 (m)
    var timeFare: Int           // 시간요금 (원)
    var timeUnit: Int           // 시간단위 (초)
    var nightSurchargeRate: Double  // 야간할증 배율
    var nightStartTime: String  // 야간 시작 (HH:mm)
    var nightEndTime: String    // 야간 종료 (HH:mm)

    init(
        id: UUID = UUID(),
        code: String,
        name: String,
        baseFare: Int,
        baseDistance: Int,
        distanceFare: Int,
        distanceUnit: Int,
        timeFare: Int,
        timeUnit: Int,
        nightSurchargeRate: Double,
        nightStartTime: String,
        nightEndTime: String
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.baseFare = baseFare
        self.baseDistance = baseDistance
        self.distanceFare = distanceFare
        self.distanceUnit = distanceUnit
        self.timeFare = timeFare
        self.timeUnit = timeUnit
        self.nightSurchargeRate = nightSurchargeRate
        self.nightStartTime = nightStartTime
        self.nightEndTime = nightEndTime
    }
}
