//
//  StatisticsModels.swift
//  HoguMeter
//

import Foundation

enum StatisticsPeriod: String, CaseIterable, Identifiable {
    case monthly
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            return "월별"
        case .weekly:
            return "주간"
        }
    }
}

struct TripStatistics: Identifiable, Equatable {
    let period: StatisticsPeriod
    let startDate: Date
    let endDate: Date
    let totalDistance: Double
    let totalFare: Int
    let tripCount: Int

    var id: String {
        "\(period.rawValue)-\(startDate.timeIntervalSince1970)"
    }
}

struct StatisticsOverview: Equatable {
    let totalDistance: Double
    let totalFare: Int
    let tripCount: Int
    let usageStartDate: Date?
    let usageEndDate: Date?

    static let empty = StatisticsOverview(
        totalDistance: 0,
        totalFare: 0,
        tripCount: 0,
        usageStartDate: nil,
        usageEndDate: nil
    )
}

struct StatisticsGridCell: Identifiable, Equatable {
    let xIndex: Int
    let yIndex: Int
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double
    let visitCount: Int
    let intensity: Double

    var id: String {
        "\(xIndex)-\(yIndex)"
    }
}
