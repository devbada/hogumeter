//
//  TripStatisticsServiceTests.swift
//  HoguMeterTests
//

import CoreLocation
import XCTest
@testable import HoguMeter

final class TripStatisticsServiceTests: XCTestCase {
    private var calendar: Calendar!
    private var service: TripStatisticsService!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        service = TripStatisticsService(calendar: calendar, gridSizeMeters: 500)
    }

    override func tearDown() {
        service = nil
        calendar = nil
        super.tearDown()
    }

    func testMonthlyAggregationSumsDistanceAndFare() {
        let trips = [
            makeTrip(date: makeDate(2026, 5, 1), distance: 10.5, fare: 15_000),
            makeTrip(date: makeDate(2026, 5, 31), distance: 4.5, fare: 8_000),
            makeTrip(date: makeDate(2026, 4, 30), distance: 3, fare: 5_000)
        ]

        let result = service.aggregate(trips, by: .monthly)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].tripCount, 2)
        XCTAssertEqual(result[0].totalDistance, 15, accuracy: 0.001)
        XCTAssertEqual(result[0].totalFare, 23_000)
    }

    func testWeeklyAggregationStartsOnMonday() {
        let trips = [
            makeTrip(date: makeDate(2026, 6, 8), distance: 2, fare: 5_000),
            makeTrip(date: makeDate(2026, 6, 14), distance: 3, fare: 6_000),
            makeTrip(date: makeDate(2026, 6, 15), distance: 4, fare: 7_000)
        ]

        let result = service.aggregate(trips, by: .weekly)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].tripCount, 1)
        XCTAssertEqual(result[1].tripCount, 2)
        XCTAssertEqual(calendar.component(.weekday, from: result[1].startDate), 2)
    }

    func testGridCountsEachTripOncePerCell() {
        let sameCellPoints = [
            makeRoutePoint(latitude: 37.5665, longitude: 126.9780),
            makeRoutePoint(latitude: 37.5666, longitude: 126.9781)
        ]

        let result = service.makeGridCells(from: [sameCellPoints, sameCellPoints])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].visitCount, 2)
        XCTAssertEqual(result[0].intensity, 1, accuracy: 0.001)
    }

    func testOverviewUsesFullUsagePeriod() {
        let trips = [
            makeTrip(date: makeDate(2026, 1, 1), distance: 2, fare: 5_000),
            makeTrip(date: makeDate(2026, 6, 1), distance: 3, fare: 7_000)
        ]

        let result = service.overview(for: trips)

        XCTAssertEqual(result.tripCount, 2)
        XCTAssertEqual(result.totalDistance, 5, accuracy: 0.001)
        XCTAssertEqual(result.totalFare, 12_000)
        XCTAssertEqual(result.usageStartDate, trips[0].startTime)
        XCTAssertEqual(result.usageEndDate, trips[1].endTime)
    }

    private func makeTrip(date: Date, distance: Double, fare: Int) -> TripSummary {
        TripSummary(
            id: UUID(),
            startTime: date,
            endTime: date.addingTimeInterval(3_600),
            totalFare: fare,
            distance: distance,
            duration: 3_600,
            startRegion: "출발지",
            endRegion: "도착지",
            regionChanges: 0,
            isNightTrip: false,
            fareBreakdown: FareBreakdown(
                baseFare: fare,
                distanceFare: 0,
                timeFare: 0,
                regionSurcharge: 0,
                nightSurcharge: 0
            ),
            driverQuote: nil,
            surchargeMode: .realistic,
            surchargeRate: 0,
            hasRouteData: true
        )
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeRoutePoint(latitude: Double, longitude: Double) -> RoutePoint {
        RoutePoint(
            location: CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                altitude: 0,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                timestamp: Date()
            )
        )
    }
}
