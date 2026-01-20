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
    let surchargeMode: RegionalSurchargeMode  // 지역 할증 모드 (v1.1 추가)
    let surchargeRate: Double     // 할증률 (리얼 모드: 0.20 = 20%, 재미 모드: 0)

    // MARK: - Codable (backward compatibility for legacy data)

    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, totalFare, distance, duration
        case startRegion, endRegion, regionChanges, isNightTrip
        case fareBreakdown, routePoints, driverQuote
        case surchargeMode, surchargeRate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        totalFare = try container.decode(Int.self, forKey: .totalFare)
        distance = try container.decode(Double.self, forKey: .distance)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        startRegion = try container.decode(String.self, forKey: .startRegion)
        endRegion = try container.decode(String.self, forKey: .endRegion)
        regionChanges = try container.decode(Int.self, forKey: .regionChanges)
        isNightTrip = try container.decode(Bool.self, forKey: .isNightTrip)
        fareBreakdown = try container.decode(FareBreakdown.self, forKey: .fareBreakdown)
        routePoints = try container.decodeIfPresent([RoutePoint].self, forKey: .routePoints) ?? []
        driverQuote = try container.decodeIfPresent(String.self, forKey: .driverQuote)

        // Backward compatibility: provide defaults for new fields
        surchargeMode = try container.decodeIfPresent(RegionalSurchargeMode.self, forKey: .surchargeMode) ?? .fun
        surchargeRate = try container.decodeIfPresent(Double.self, forKey: .surchargeRate) ?? 0
    }

    /// 리얼 모드인지 확인
    var isRealisticMode: Bool {
        return surchargeMode == .realistic
    }

    /// 할증률 퍼센트 표시 (예: "20%")
    var surchargeRateDisplay: String {
        return "\(Int(surchargeRate * 100))%"
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
        surchargeMode: RegionalSurchargeMode = .realistic,
        surchargeRate: Double = 0
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
        self.surchargeMode = surchargeMode
        self.surchargeRate = surchargeRate
    }
}
