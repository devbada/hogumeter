//
//  RouteOptimizerTests.swift
//  HoguMeterTests
//
//  Created on 2026-01-19.
//

import XCTest
import CoreLocation
@testable import HoguMeter

final class RouteOptimizerTests: XCTestCase {

    // MARK: - Test Data

    /// Generate mock route points with 1-second intervals
    private func generateMockRoutePoints(count: Int, interval: TimeInterval = 1.0) -> [RoutePoint] {
        var points: [RoutePoint] = []
        let baseTime = Date()
        let baseLatitude = 37.5665  // Seoul
        let baseLongitude = 126.9780

        for i in 0..<count {
            let point = RoutePoint(
                latitude: baseLatitude + Double(i) * 0.0001,
                longitude: baseLongitude + Double(i) * 0.0001,
                timestamp: baseTime.addingTimeInterval(TimeInterval(i) * interval),
                speed: 30.0,
                accuracy: 10.0
            )
            points.append(point)
        }
        return points
    }

    // MARK: - Downsampling Tests

    /// TC-001: 5-second sampling reduces coordinates by 80%
    func testDownsamplingReducesPointsBy80Percent() {
        // Given: 60 points at 1-second intervals (60 seconds of data)
        let originalPoints = generateMockRoutePoints(count: 60, interval: 1.0)

        // When: Downsample to 5-second intervals
        let downsampledPoints = RouteOptimizer.downsample(originalPoints)

        // Then: Should have ~12 points (60/5 = 12), plus first and last
        // Actual range: 11-14 points depending on edge cases
        XCTAssertLessThanOrEqual(downsampledPoints.count, 14)
        XCTAssertGreaterThanOrEqual(downsampledPoints.count, 11)

        // Verify ~80% reduction
        let reductionPercent = Double(originalPoints.count - downsampledPoints.count) / Double(originalPoints.count) * 100
        XCTAssertGreaterThan(reductionPercent, 75.0, "Should achieve at least 75% reduction")
    }

    /// Test that downsampling preserves first and last points
    func testDownsamplingPreservesFirstAndLastPoints() {
        // Given: 100 points
        let originalPoints = generateMockRoutePoints(count: 100, interval: 1.0)

        // When: Downsample
        let downsampledPoints = RouteOptimizer.downsample(originalPoints)

        // Then: First and last points should be preserved
        XCTAssertEqual(downsampledPoints.first?.timestamp, originalPoints.first?.timestamp)
        XCTAssertEqual(downsampledPoints.last?.timestamp, originalPoints.last?.timestamp)
    }

    /// Test that downsampling handles empty array
    func testDownsamplingHandlesEmptyArray() {
        let result = RouteOptimizer.downsample([])
        XCTAssertTrue(result.isEmpty)
    }

    /// Test that downsampling handles single point
    func testDownsamplingHandlesSinglePoint() {
        let points = generateMockRoutePoints(count: 1)
        let result = RouteOptimizer.downsample(points)
        XCTAssertEqual(result.count, 1)
    }

    /// Test that downsampling handles two points
    func testDownsamplingHandlesTwoPoints() {
        let points = generateMockRoutePoints(count: 2, interval: 10.0)  // 10 seconds apart
        let result = RouteOptimizer.downsample(points)
        XCTAssertEqual(result.count, 2)  // Both should be preserved
    }

    // MARK: - Simplification Tests

    /// TC-002: Douglas-Peucker preserves curve accuracy
    func testSimplificationPreservesCurves() {
        // Given: Points forming a curve (L-shape)
        var points: [RoutePoint] = []
        let baseTime = Date()

        // Straight segment
        for i in 0..<10 {
            points.append(RoutePoint(
                latitude: 37.5665,
                longitude: 126.9780 + Double(i) * 0.001,
                timestamp: baseTime.addingTimeInterval(TimeInterval(i)),
                speed: 30.0,
                accuracy: 10.0
            ))
        }

        // Turn point (corner of L)
        points.append(RoutePoint(
            latitude: 37.5665,
            longitude: 126.9880,
            timestamp: baseTime.addingTimeInterval(10),
            speed: 30.0,
            accuracy: 10.0
        ))

        // Second segment going north
        for i in 1..<10 {
            points.append(RoutePoint(
                latitude: 37.5665 + Double(i) * 0.001,
                longitude: 126.9880,
                timestamp: baseTime.addingTimeInterval(TimeInterval(10 + i)),
                speed: 30.0,
                accuracy: 10.0
            ))
        }

        // When: Simplify with 5m tolerance
        let simplified = RouteOptimizer.simplify(points, tolerance: 5.0)

        // Then: Corner point should be preserved
        XCTAssertLessThan(simplified.count, points.count, "Should reduce point count")
        XCTAssertGreaterThan(simplified.count, 2, "Should preserve more than just endpoints")

        // First and last should be preserved
        XCTAssertEqual(simplified.first?.latitude, points.first?.latitude)
        XCTAssertEqual(simplified.last?.latitude, points.last?.latitude)
    }

    /// Test simplification handles straight line
    func testSimplificationOnStraightLine() {
        // Given: Perfectly straight line points
        var points: [RoutePoint] = []
        let baseTime = Date()

        for i in 0..<20 {
            points.append(RoutePoint(
                latitude: 37.5665,
                longitude: 126.9780 + Double(i) * 0.001,
                timestamp: baseTime.addingTimeInterval(TimeInterval(i)),
                speed: 30.0,
                accuracy: 10.0
            ))
        }

        // When: Simplify
        let simplified = RouteOptimizer.simplify(points, tolerance: 10.0)

        // Then: Should keep only first and last (straight line)
        XCTAssertEqual(simplified.count, 2, "Straight line should simplify to 2 points")
    }

    // MARK: - Combined Optimization Tests

    /// Test full optimization pipeline
    func testFullOptimizationPipeline() {
        // Given: 600 points at 1-second intervals (10 minutes of data)
        let originalPoints = generateMockRoutePoints(count: 600, interval: 1.0)

        // When: Apply full optimization
        let optimizedPoints = RouteOptimizer.optimizeForStorage(originalPoints)

        // Then: Should achieve significant reduction (typically 80-95%)
        let reductionPercent = Double(originalPoints.count - optimizedPoints.count) / Double(originalPoints.count) * 100
        XCTAssertGreaterThan(reductionPercent, 70.0, "Should achieve at least 70% total reduction")

        print("Original: \(originalPoints.count), Optimized: \(optimizedPoints.count), Reduction: \(String(format: "%.1f", reductionPercent))%")
    }
}
