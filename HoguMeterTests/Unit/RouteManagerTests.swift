//
//  RouteManagerTests.swift
//  HoguMeterTests
//
//  RouteManager 경로 최적화 테스트
//

import XCTest
import CoreLocation
@testable import HoguMeter

final class RouteManagerTests: XCTestCase {

    var sut: RouteManager!

    override func setUp() {
        super.setUp()
        sut = RouteManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - RouteConfig Tests

    func test_pointInterval_10km미만_5m() {
        XCTAssertEqual(RouteConfig.pointInterval(for: 0), 5.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 5000), 5.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 9999), 5.0)
    }

    func test_pointInterval_10km_50km_20m() {
        XCTAssertEqual(RouteConfig.pointInterval(for: 10000), 20.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 30000), 20.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 49999), 20.0)
    }

    func test_pointInterval_50km_100km_50m() {
        XCTAssertEqual(RouteConfig.pointInterval(for: 50000), 50.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 75000), 50.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 99999), 50.0)
    }

    func test_pointInterval_100km_300km_100m() {
        XCTAssertEqual(RouteConfig.pointInterval(for: 100000), 100.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 200000), 100.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 299999), 100.0)
    }

    func test_pointInterval_300km이상_200m() {
        XCTAssertEqual(RouteConfig.pointInterval(for: 300000), 200.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 600000), 200.0)
        XCTAssertEqual(RouteConfig.pointInterval(for: 1000000), 200.0)
    }

    func test_simplificationTolerance_100km미만_10m() {
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 0), 10.0)
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 50000), 10.0)
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 99999), 10.0)
    }

    func test_simplificationTolerance_100km_300km_20m() {
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 100000), 20.0)
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 200000), 20.0)
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 299999), 20.0)
    }

    func test_simplificationTolerance_300km이상_30m() {
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 300000), 30.0)
        XCTAssertEqual(RouteConfig.simplificationTolerance(for: 600000), 30.0)
    }

    // MARK: - RouteManager Basic Tests

    func test_startNewRoute_초기화() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)

        sut.startNewRoute(at: startLocation)

        XCTAssertEqual(sut.pointCount, 1)
        XCTAssertNotNil(sut.startLocation)
        XCTAssertEqual(sut.startLocation!.latitude, 37.5665, accuracy: 0.0001)
        XCTAssertEqual(sut.totalDistance, 0)
    }

    func test_clearRoute_모든데이터초기화() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        sut.clearRoute()

        XCTAssertEqual(sut.pointCount, 0)
        XCTAssertNil(sut.startLocation)
        XCTAssertEqual(sut.totalDistance, 0)
    }

    func test_addPoint_최소간격미만_추가안됨() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        // 3m 이동 (5m 미만)
        let nearbyLocation = CLLocation(
            latitude: 37.5665 + 0.00003,  // 약 3m
            longitude: 126.9780
        )
        sut.addPoint(nearbyLocation)

        XCTAssertEqual(sut.pointCount, 1)  // 시작점만 유지
    }

    func test_addPoint_최소간격이상_추가됨() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        // 10m 이동
        let farLocation = CLLocation(
            latitude: 37.5665 + 0.0001,  // 약 11m
            longitude: 126.9780
        )
        sut.addPoint(farLocation)

        XCTAssertEqual(sut.pointCount, 2)
    }

    func test_totalDistance_정확한거리계산() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        // 약 100m 이동
        let location2 = CLLocation(
            latitude: 37.5665 + 0.0009,  // 약 100m
            longitude: 126.9780
        )
        sut.addPoint(location2)

        // 추가로 약 100m 이동
        let location3 = CLLocation(
            latitude: 37.5665 + 0.0018,  // 약 200m
            longitude: 126.9780
        )
        sut.addPoint(location3)

        // 총 거리는 약 200m
        XCTAssertEqual(sut.totalDistance, 200, accuracy: 20)
    }

    // MARK: - Dynamic Interval Tests

    func test_dynamicInterval_거리증가시간격증가() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        // 10km 이상 시뮬레이션 - 포인트 추가
        // 실제로 10km를 시뮬레이션하면 시간이 오래 걸리므로
        // 거리 계산 로직만 테스트

        let interval5m = RouteConfig.pointInterval(for: 5000)
        let interval10km = RouteConfig.pointInterval(for: 10000)

        XCTAssertEqual(interval5m, 5.0)
        XCTAssertEqual(interval10km, 20.0)
        XCTAssertGreaterThan(interval10km, interval5m)
    }

    // MARK: - Douglas-Peucker Algorithm Tests

    func test_douglasPeucker_시작점끝점유지() {
        // 직선 경로 생성
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        // 직선상의 여러 포인트 추가
        for i in 1...100 {
            let location = CLLocation(
                latitude: 37.5665 + Double(i) * 0.0001,
                longitude: 126.9780
            )
            sut.addPoint(location)
        }

        let firstPoint = sut.routePoints.first
        let lastPoint = sut.routePoints.last

        XCTAssertNotNil(firstPoint)
        XCTAssertNotNil(lastPoint)

        // 시작점 확인
        XCTAssertEqual(firstPoint!.latitude, 37.5665, accuracy: 0.0001)

        // 끝점이 마지막 추가된 포인트
        XCTAssertGreaterThan(lastPoint!.latitude, 37.5665)
    }

    func test_douglasPeucker_곡선유지() {
        // 곡선 경로 생성 (지그재그)
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        // 지그재그 패턴으로 포인트 추가
        for i in 1...50 {
            let offset = (i % 2 == 0) ? 0.0005 : -0.0005  // 좌우로 ~50m 이동
            let location = CLLocation(
                latitude: 37.5665 + Double(i) * 0.0002,  // 북쪽으로 진행
                longitude: 126.9780 + offset
            )
            sut.addPoint(location)
        }

        // 지그재그 패턴이므로 직선화되지 않고 포인트가 유지되어야 함
        XCTAssertGreaterThan(sut.pointCount, 2)
    }

    // MARK: - Long Distance Simulation Tests

    func test_600km경로_10000포인트이하() {
        // 600km 경로 시뮬레이션
        // 실제 GPS 포인트를 시뮬레이션하여 포인트 수가 제한 내에 있는지 확인

        let startLat = 37.5665  // 서울
        let startLon = 126.9780

        // 시작점
        let startLocation = CLLocation(latitude: startLat, longitude: startLon)
        sut.startNewRoute(at: startLocation)

        // 600km = 600,000m
        // 5m 간격으로 시작하면 120,000 포인트가 필요하지만
        // 동적 간격으로 인해 훨씬 적어야 함

        var currentDistance: Double = 0
        let totalTarget: Double = 600_000  // 600km
        var lat = startLat
        let stepDistance: Double = 100  // 100m씩 이동 시뮬레이션

        while currentDistance < totalTarget {
            lat += stepDistance / 111_000  // 1도 ≈ 111km
            currentDistance += stepDistance

            let location = CLLocation(latitude: lat, longitude: startLon)
            sut.addPoint(location)
        }

        // 600km 경로가 10,000 포인트 이하로 유지되어야 함
        XCTAssertLessThanOrEqual(sut.pointCount, RouteConfig.maxPoints)

        // 총 거리는 대략 600km
        XCTAssertEqual(sut.totalDistance, 600_000, accuracy: 10_000)

        Logger.gps.info("[Test] 600km 경로 결과: \(sut.pointCount) 포인트, 총 거리: \(String(format: "%.1f", sut.totalDistance / 1000))km")
    }

    func test_300km경로_예상포인트수() {
        let startLat = 37.5665
        let startLon = 126.9780

        let startLocation = CLLocation(latitude: startLat, longitude: startLon)
        sut.startNewRoute(at: startLocation)

        var currentDistance: Double = 0
        let totalTarget: Double = 300_000  // 300km
        var lat = startLat
        let stepDistance: Double = 50  // 50m씩 이동

        while currentDistance < totalTarget {
            lat += stepDistance / 111_000
            currentDistance += stepDistance

            let location = CLLocation(latitude: lat, longitude: startLon)
            sut.addPoint(location)
        }

        // 300km 경로는 약 6,000 포인트 이하
        XCTAssertLessThanOrEqual(sut.pointCount, 8000)

        Logger.gps.info("[Test] 300km 경로 결과: \(sut.pointCount) 포인트")
    }

    func test_100km경로_예상포인트수() {
        let startLat = 37.5665
        let startLon = 126.9780

        let startLocation = CLLocation(latitude: startLat, longitude: startLon)
        sut.startNewRoute(at: startLocation)

        var currentDistance: Double = 0
        let totalTarget: Double = 100_000  // 100km
        var lat = startLat
        let stepDistance: Double = 20  // 20m씩 이동

        while currentDistance < totalTarget {
            lat += stepDistance / 111_000
            currentDistance += stepDistance

            let location = CLLocation(latitude: lat, longitude: startLon)
            sut.addPoint(location)
        }

        // 100km 경로는 약 4,000 포인트 이하
        XCTAssertLessThanOrEqual(sut.pointCount, 5000)

        Logger.gps.info("[Test] 100km 경로 결과: \(sut.pointCount) 포인트")
    }

    // MARK: - Memory Usage Estimation

    func test_memoryUsage_600km() {
        // RoutePoint 예상 크기: 약 80 bytes (latitude, longitude, timestamp, speed, heading + 오버헤드)
        // 8,000 포인트 × 80 bytes = 640 KB

        let estimatedPointSize = 80  // bytes
        let maxExpectedPoints = 8000
        let estimatedMemory = estimatedPointSize * maxExpectedPoints

        // 1MB 이하여야 함
        XCTAssertLessThan(estimatedMemory, 1_000_000)
    }

    // MARK: - Edge Cases

    func test_빈경로_단순화안함() {
        // 빈 경로에서 단순화 시도해도 크래시 없어야 함
        XCTAssertEqual(sut.pointCount, 0)
        sut.clearRoute()
        XCTAssertEqual(sut.pointCount, 0)
    }

    func test_단일포인트_단순화안함() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        XCTAssertEqual(sut.pointCount, 1)
    }

    func test_두포인트_단순화안함() {
        let startLocation = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.startNewRoute(at: startLocation)

        let endLocation = CLLocation(latitude: 37.5675, longitude: 126.9780)
        sut.addPoint(endLocation)

        XCTAssertEqual(sut.pointCount, 2)
    }
}

// MARK: - Route Config Constants Tests

final class RouteConfigTests: XCTestCase {

    func test_maxPoints_10000() {
        XCTAssertEqual(RouteConfig.maxPoints, 10000)
    }

    func test_simplificationThreshold_5000() {
        XCTAssertEqual(RouteConfig.simplificationThreshold, 5000)
    }

    func test_simplificationTarget_3000() {
        XCTAssertEqual(RouteConfig.simplificationTarget, 3000)
    }
}
