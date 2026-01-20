//
//  TripSummary.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation

/// Lightweight trip model for list display (no route data)
/// Used for efficient pagination and reduced memory usage
struct TripSummary: Identifiable, Codable, Equatable {
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
    let driverQuote: String?
    let surchargeMode: RegionalSurchargeMode
    let surchargeRate: Double
    let hasRouteData: Bool

    // MARK: - Codable (backward compatibility)

    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, totalFare, distance, duration
        case startRegion, endRegion, regionChanges, isNightTrip
        case fareBreakdown, driverQuote
        case surchargeMode, surchargeRate, hasRouteData
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
        driverQuote = try container.decodeIfPresent(String.self, forKey: .driverQuote)

        // Backward compatibility: provide defaults for new fields
        surchargeMode = try container.decodeIfPresent(RegionalSurchargeMode.self, forKey: .surchargeMode) ?? .fun
        surchargeRate = try container.decodeIfPresent(Double.self, forKey: .surchargeRate) ?? 0
        hasRouteData = try container.decodeIfPresent(Bool.self, forKey: .hasRouteData) ?? true
    }

    /// Initialize from Trip summary data
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
        driverQuote: String?,
        surchargeMode: RegionalSurchargeMode,
        surchargeRate: Double,
        hasRouteData: Bool
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
        self.driverQuote = driverQuote
        self.surchargeMode = surchargeMode
        self.surchargeRate = surchargeRate
        self.hasRouteData = hasRouteData
    }

    /// Convert from full Trip (for migration and saving)
    init(from trip: Trip, hasRouteData: Bool = true) {
        self.id = trip.id
        self.startTime = trip.startTime
        self.endTime = trip.endTime
        self.totalFare = trip.totalFare
        self.distance = trip.distance
        self.duration = trip.duration
        self.startRegion = trip.startRegion
        self.endRegion = trip.endRegion
        self.regionChanges = trip.regionChanges
        self.isNightTrip = trip.isNightTrip
        self.fareBreakdown = trip.fareBreakdown
        self.driverQuote = trip.driverQuote
        self.surchargeMode = trip.surchargeMode
        self.surchargeRate = trip.surchargeRate
        self.hasRouteData = hasRouteData
    }

    /// Create full Trip by loading route data
    /// - Parameter routePoints: Route points loaded from separate storage
    /// - Returns: Full Trip object
    func toTrip(routePoints: [RoutePoint] = []) -> Trip {
        Trip(
            id: id,
            startTime: startTime,
            endTime: endTime,
            totalFare: totalFare,
            distance: distance,
            duration: duration,
            startRegion: startRegion,
            endRegion: endRegion,
            regionChanges: regionChanges,
            isNightTrip: isNightTrip,
            fareBreakdown: fareBreakdown,
            routePoints: routePoints,
            driverQuote: driverQuote,
            surchargeMode: surchargeMode,
            surchargeRate: surchargeRate
        )
    }

    /// Computed property: Check if surcharge mode is realistic
    var isRealisticMode: Bool {
        surchargeMode == .realistic
    }

    /// Computed property: Display string for surcharge rate
    var surchargeRateDisplay: String {
        "\(Int(surchargeRate * 100))%"
    }
}
