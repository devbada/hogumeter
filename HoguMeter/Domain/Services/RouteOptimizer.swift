//
//  RouteOptimizer.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation
import CoreLocation

/// Route optimization utilities for storage efficiency
enum RouteOptimizer {

    // MARK: - Configuration

    /// Sampling interval in seconds when saving trip
    static let saveInterval: TimeInterval = 5.0

    /// Default Douglas-Peucker tolerance in meters
    static let defaultTolerance: Double = 10.0

    // MARK: - Public Methods

    /// Downsample route points to 5-second intervals
    /// - Parameter points: Original route points (collected at ~1 second intervals)
    /// - Returns: Downsampled route points
    static func downsample(_ points: [RoutePoint]) -> [RoutePoint] {
        guard points.count > 2 else { return points }

        var result: [RoutePoint] = []
        var lastTimestamp: Date?

        // Always keep first point
        result.append(points[0])
        lastTimestamp = points[0].timestamp

        for point in points.dropFirst() {
            guard let last = lastTimestamp else { continue }

            // Keep point if 5+ seconds have passed
            if point.timestamp.timeIntervalSince(last) >= saveInterval {
                result.append(point)
                lastTimestamp = point.timestamp
            }
        }

        // Always keep last point
        if let lastPoint = points.last, result.last?.timestamp != lastPoint.timestamp {
            result.append(lastPoint)
        }

        return result
    }

    /// Apply Douglas-Peucker simplification for curve preservation
    /// - Parameters:
    ///   - points: Route points to simplify
    ///   - tolerance: Distance tolerance in meters
    /// - Returns: Simplified route points
    static func simplify(_ points: [RoutePoint], tolerance: Double = defaultTolerance) -> [RoutePoint] {
        guard points.count > 2 else { return points }

        var keep = [Bool](repeating: false, count: points.count)
        keep[0] = true
        keep[points.count - 1] = true

        var stack: [(Int, Int)] = [(0, points.count - 1)]

        while !stack.isEmpty {
            let (start, end) = stack.removeLast()
            guard end - start > 1 else { continue }

            var maxDistance: Double = 0
            var maxIndex = start

            let startCoord = points[start].coordinate
            let endCoord = points[end].coordinate

            for i in (start + 1)..<end {
                let distance = perpendicularDistance(
                    point: points[i].coordinate,
                    lineStart: startCoord,
                    lineEnd: endCoord
                )
                if distance > maxDistance {
                    maxDistance = distance
                    maxIndex = i
                }
            }

            if maxDistance > tolerance {
                keep[maxIndex] = true
                stack.append((start, maxIndex))
                stack.append((maxIndex, end))
            }
        }

        return points.enumerated().compactMap { keep[$0.offset] ? $0.element : nil }
    }

    /// Optimize route for storage (downsample + simplify)
    /// - Parameter points: Original route points
    /// - Returns: Optimized route points for storage
    static func optimizeForStorage(_ points: [RoutePoint]) -> [RoutePoint] {
        let downsampled = downsample(points)
        return simplify(downsampled, tolerance: defaultTolerance)
    }

    // MARK: - Private Helpers

    /// Calculate perpendicular distance from a point to a line segment
    private static func perpendicularDistance(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> Double {
        let lineLength = distance(from: lineStart, to: lineEnd)
        if lineLength == 0 { return distance(from: point, to: lineStart) }

        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude
        let t = max(0, min(1, (
            (point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy
        ) / (dx * dx + dy * dy)))

        let closest = CLLocationCoordinate2D(
            latitude: lineStart.latitude + t * dy,
            longitude: lineStart.longitude + t * dx
        )
        return distance(from: point, to: closest)
    }

    /// Calculate distance between two coordinates in meters
    private static func distance(from c1: CLLocationCoordinate2D, to c2: CLLocationCoordinate2D) -> Double {
        let l1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
        let l2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
        return l1.distance(from: l2)
    }
}
