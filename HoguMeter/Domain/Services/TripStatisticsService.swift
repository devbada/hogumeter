//
//  TripStatisticsService.swift
//  HoguMeter
//

import Foundation

struct TripStatisticsService {
    private struct StatisticsAccumulator {
        var totalDistance: Double = 0
        var totalFare: Int = 0
        var tripCount: Int = 0
        var endDate: Date = .distantPast
    }

    private struct GridKey: Hashable {
        let x: Int
        let y: Int
    }

    private let calendar: Calendar
    private let gridSizeMeters: Double
    private let earthRadiusMeters = 6_378_137.0
    private let maximumMercatorLatitude = 85.05112878

    init(calendar: Calendar = .current, gridSizeMeters: Double = 500) {
        var configuredCalendar = calendar
        configuredCalendar.firstWeekday = 2
        configuredCalendar.minimumDaysInFirstWeek = 4
        self.calendar = configuredCalendar
        self.gridSizeMeters = max(gridSizeMeters, 100)
    }

    func overview(for trips: [TripSummary]) -> StatisticsOverview {
        guard !trips.isEmpty else { return .empty }

        return StatisticsOverview(
            totalDistance: trips.reduce(0) { $0 + $1.distance },
            totalFare: trips.reduce(0) { $0 + $1.totalFare },
            tripCount: trips.count,
            usageStartDate: trips.map(\.startTime).min(),
            usageEndDate: trips.map(\.endTime).max()
        )
    }

    func aggregate(_ trips: [TripSummary], by period: StatisticsPeriod) -> [TripStatistics] {
        let grouped = trips.reduce(into: [Date: StatisticsAccumulator]()) { result, trip in
            guard let interval = dateInterval(containing: trip.startTime, period: period) else {
                return
            }

            var accumulator = result[interval.start] ?? StatisticsAccumulator()
            accumulator.totalDistance += trip.distance
            accumulator.totalFare += trip.totalFare
            accumulator.tripCount += 1
            accumulator.endDate = interval.end.addingTimeInterval(-1)
            result[interval.start] = accumulator
        }

        return grouped.map { startDate, accumulator in
            TripStatistics(
                period: period,
                startDate: startDate,
                endDate: accumulator.endDate,
                totalDistance: accumulator.totalDistance,
                totalFare: accumulator.totalFare,
                tripCount: accumulator.tripCount
            )
        }
        .sorted { $0.startDate > $1.startDate }
    }

    func makeGridCells(from routes: [[RoutePoint]]) -> [StatisticsGridCell] {
        var visitCounts: [GridKey: Int] = [:]

        routes.forEach { route in
            let visitedCells = Set(route.compactMap(gridKey))
            visitedCells.forEach { visitCounts[$0, default: 0] += 1 }
        }

        guard let maximumVisitCount = visitCounts.values.max(), maximumVisitCount > 0 else {
            return []
        }

        return visitCounts.map { key, count in
            let bounds = coordinateBounds(for: key)
            return StatisticsGridCell(
                xIndex: key.x,
                yIndex: key.y,
                minLatitude: bounds.minLatitude,
                maxLatitude: bounds.maxLatitude,
                minLongitude: bounds.minLongitude,
                maxLongitude: bounds.maxLongitude,
                visitCount: count,
                intensity: Double(count) / Double(maximumVisitCount)
            )
        }
        .sorted {
            if $0.visitCount == $1.visitCount {
                return $0.id < $1.id
            }
            return $0.visitCount > $1.visitCount
        }
    }

    private func dateInterval(containing date: Date, period: StatisticsPeriod) -> DateInterval? {
        switch period {
        case .monthly:
            return calendar.dateInterval(of: .month, for: date)
        case .weekly:
            return calendar.dateInterval(of: .weekOfYear, for: date)
        }
    }

    private func gridKey(for point: RoutePoint) -> GridKey? {
        guard point.latitude.isFinite,
              point.longitude.isFinite,
              (-90...90).contains(point.latitude),
              (-180...180).contains(point.longitude) else {
            return nil
        }

        let latitude = min(max(point.latitude, -maximumMercatorLatitude), maximumMercatorLatitude)
        let xMeters = earthRadiusMeters * point.longitude * .pi / 180
        let yMeters = earthRadiusMeters * log(tan(.pi / 4 + latitude * .pi / 360))

        return GridKey(
            x: Int(floor(xMeters / gridSizeMeters)),
            y: Int(floor(yMeters / gridSizeMeters))
        )
    }

    private func coordinateBounds(
        for key: GridKey
    ) -> (minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) {
        let minXMeters = Double(key.x) * gridSizeMeters
        let maxXMeters = Double(key.x + 1) * gridSizeMeters
        let minYMeters = Double(key.y) * gridSizeMeters
        let maxYMeters = Double(key.y + 1) * gridSizeMeters

        return (
            minLatitude: latitude(fromMercatorY: minYMeters),
            maxLatitude: latitude(fromMercatorY: maxYMeters),
            minLongitude: minXMeters / earthRadiusMeters * 180 / .pi,
            maxLongitude: maxXMeters / earthRadiusMeters * 180 / .pi
        )
    }

    private func latitude(fromMercatorY yMeters: Double) -> Double {
        (2 * atan(exp(yMeters / earthRadiusMeters)) - .pi / 2) * 180 / .pi
    }
}
