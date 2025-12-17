//
//  Trip.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

struct Trip: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let totalFare: Int
    let distance: Double        // km
    let duration: TimeInterval  // seconds
    let startRegion: String
    let endRegion: String
    let regionChanges: Int
    let isNightTrip: Bool
    let fareBreakdown: FareBreakdown
    let routePoints: [RoutePoint]  // 경로 좌표 (영수증 지도용)
    let driverQuote: String?       // 택시기사 한마디 (영수증용)
    let mapImageData: Data?        // 지도 스냅샷 이미지 (JPEG)
    let passengerCount: Int        // N빵 승객 수 (1~6명)

    /// 1인당 요금 (올림 처리)
    var farePerPerson: Int {
        guard passengerCount > 1 else { return totalFare }
        return Int(ceil(Double(totalFare) / Double(passengerCount)))
    }

    /// 기존 코드 호환을 위한 이니셜라이저
    init(
        id: UUID,
        startTime: Date,
        endTime: Date,
        totalFare: Int,
        distance: Double,
        duration: TimeInterval,
        startRegion: String,
        endRegion: String,
        regionChanges: Int,
        isNightTrip: Bool,
        fareBreakdown: FareBreakdown,
        routePoints: [RoutePoint] = [],
        driverQuote: String? = nil,
        mapImageData: Data? = nil,
        passengerCount: Int = 1
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.totalFare = totalFare
        self.distance = distance
        self.duration = duration
        self.startRegion = startRegion
        self.endRegion = endRegion
        self.regionChanges = regionChanges
        self.isNightTrip = isNightTrip
        self.fareBreakdown = fareBreakdown
        self.routePoints = routePoints
        self.driverQuote = driverQuote
        self.mapImageData = mapImageData
        self.passengerCount = passengerCount
    }
}
