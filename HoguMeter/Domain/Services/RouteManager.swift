//
//  RouteManager.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import CoreLocation
import Combine

// MARK: - Route Configuration

/// 경로 관리 설정 상수
enum RouteConfig {
    /// 최대 포인트 수 (장거리 지원을 위해 증가)
    static let maxPoints: Int = 10000

    /// 단순화 실행 임계값 (이 개수 초과 시 Douglas-Peucker 실행)
    static let simplificationThreshold: Int = 5000

    /// 단순화 목표 포인트 수
    static let simplificationTarget: Int = 3000

    /// 거리별 포인트 간격 (meters)
    static func pointInterval(for totalDistance: Double) -> Double {
        switch totalDistance {
        case ..<10_000:     return 5.0    // < 10km: 5m 간격
        case ..<50_000:     return 20.0   // 10-50km: 20m 간격
        case ..<100_000:    return 50.0   // 50-100km: 50m 간격
        case ..<300_000:    return 100.0  // 100-300km: 100m 간격
        default:            return 200.0  // > 300km: 200m 간격
        }
    }

    /// 거리별 Douglas-Peucker 허용 오차 (meters)
    static func simplificationTolerance(for totalDistance: Double) -> Double {
        switch totalDistance {
        case ..<100_000:    return 10.0   // < 100km: 10m 오차
        case ..<300_000:    return 20.0   // 100-300km: 20m 오차
        default:            return 30.0   // > 300km: 30m 오차
        }
    }
}

// MARK: - RouteManager

class RouteManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var routePoints: [RoutePoint] = []
    @Published private(set) var startLocation: CLLocationCoordinate2D?

    // MARK: - Private Properties

    /// 누적 총 거리 (미터) - 단순화 전 정확한 거리 유지
    private var accumulatedDistance: Double = 0

    /// 현재 적용 중인 포인트 간격
    private var currentPointInterval: Double = 5.0

    /// 마지막 추가된 포인트 위치 (간격 계산용)
    private var lastAddedLocation: CLLocation?

    // MARK: - Cached Coordinates (성능 최적화)
    private var cachedCoordinates: [CLLocationCoordinate2D] = []

    // MARK: - Lifecycle

    deinit {
        let pointCount = routePoints.count
        routePoints.removeAll()
        cachedCoordinates.removeAll()
        Logger.gps.debug("[RouteManager] RouteManager deinit - cleared \(pointCount) points")
    }

    // MARK: - Computed Properties

    var coordinates: [CLLocationCoordinate2D] {
        cachedCoordinates
    }

    /// 누적 총 거리 (단순화와 무관하게 정확한 값)
    var totalDistance: Double {
        accumulatedDistance
    }

    /// 현재 포인트 수
    var pointCount: Int {
        routePoints.count
    }

    // MARK: - Public Methods

    func startNewRoute(at location: CLLocation) {
        routePoints = []
        cachedCoordinates = []
        accumulatedDistance = 0
        currentPointInterval = RouteConfig.pointInterval(for: 0)
        lastAddedLocation = nil
        startLocation = location.coordinate

        // 시작점 추가
        addPointInternal(location, isStartPoint: true)
    }

    func addPoint(_ location: CLLocation) {
        // 첫 포인트인 경우 시작점으로 추가
        guard lastAddedLocation != nil else {
            addPointInternal(location, isStartPoint: true)
            return
        }

        // 마지막 추가 위치와의 거리 계산
        guard let lastLocation = lastAddedLocation else { return }
        let distanceFromLast = location.distance(from: lastLocation)

        // 누적 거리 업데이트 (항상 정확한 거리 유지)
        accumulatedDistance += distanceFromLast
        lastAddedLocation = location

        // 동적 간격 업데이트 (거리에 따라 간격 증가)
        let newInterval = RouteConfig.pointInterval(for: accumulatedDistance)
        if newInterval > currentPointInterval {
            currentPointInterval = newInterval
            Logger.gps.info("[Route] 포인트 간격 변경: \(Int(currentPointInterval))m (총 거리: \(String(format: "%.1f", accumulatedDistance / 1000))km)")
        }

        // 마지막 저장된 포인트와의 거리 확인
        if let lastSavedPoint = routePoints.last {
            let lastSavedLocation = CLLocation(
                latitude: lastSavedPoint.latitude,
                longitude: lastSavedPoint.longitude
            )
            let distanceFromLastSaved = location.distance(from: lastSavedLocation)

            // 현재 간격 이상 이동했을 때만 포인트 추가
            guard distanceFromLastSaved >= currentPointInterval else { return }
        }

        // 포인트 추가
        addPointInternal(location, isStartPoint: false)

        // 단순화 필요 여부 확인
        if routePoints.count > RouteConfig.simplificationThreshold {
            simplifyRoute()
        }
    }

    func clearRoute() {
        routePoints = []
        cachedCoordinates = []
        accumulatedDistance = 0
        currentPointInterval = 5.0
        lastAddedLocation = nil
        startLocation = nil
    }

    // MARK: - Private Methods

    private func addPointInternal(_ location: CLLocation, isStartPoint: Bool) {
        let newPoint = RoutePoint(location: location)
        routePoints.append(newPoint)
        cachedCoordinates.append(newPoint.coordinate)

        if isStartPoint {
            lastAddedLocation = location
        }

        // 최대 포인트 수 초과 시 단순화
        if routePoints.count > RouteConfig.maxPoints {
            simplifyRoute()
        }
    }

    /// Douglas-Peucker 알고리즘을 사용한 경로 단순화
    private func simplifyRoute() {
        guard routePoints.count > RouteConfig.simplificationTarget else { return }

        let tolerance = RouteConfig.simplificationTolerance(for: accumulatedDistance)
        let originalCount = routePoints.count

        // Douglas-Peucker 알고리즘 적용
        let simplifiedPoints = douglasPeucker(
            points: routePoints,
            tolerance: tolerance
        )

        // 목표보다 많으면 허용 오차를 높여서 재시도
        var finalPoints = simplifiedPoints
        var currentTolerance = tolerance

        while finalPoints.count > RouteConfig.simplificationTarget && currentTolerance < 100 {
            currentTolerance *= 1.5
            finalPoints = douglasPeucker(points: routePoints, tolerance: currentTolerance)
        }

        // 결과 적용
        routePoints = finalPoints
        cachedCoordinates = finalPoints.map { $0.coordinate }

        Logger.gps.info("[Route] 경로 단순화: \(originalCount) → \(routePoints.count) 포인트 (허용오차: \(String(format: "%.1f", currentTolerance))m)")
    }

    // MARK: - Douglas-Peucker Algorithm

    /// Douglas-Peucker 경로 단순화 알고리즘
    /// - Parameters:
    ///   - points: 원본 포인트 배열
    ///   - tolerance: 허용 오차 (미터)
    /// - Returns: 단순화된 포인트 배열
    private func douglasPeucker(points: [RoutePoint], tolerance: Double) -> [RoutePoint] {
        guard points.count > 2 else { return points }

        // 스택 기반 반복 구현 (재귀 대신 스택 오버플로우 방지)
        var result = [Bool](repeating: false, count: points.count)
        result[0] = true  // 시작점 유지
        result[points.count - 1] = true  // 끝점 유지

        var stack: [(start: Int, end: Int)] = [(0, points.count - 1)]

        while !stack.isEmpty {
            let (start, end) = stack.removeLast()

            guard end - start > 1 else { continue }

            // 최대 거리를 가진 포인트 찾기
            var maxDistance: Double = 0
            var maxIndex = start

            let startCoord = CLLocationCoordinate2D(
                latitude: points[start].latitude,
                longitude: points[start].longitude
            )
            let endCoord = CLLocationCoordinate2D(
                latitude: points[end].latitude,
                longitude: points[end].longitude
            )

            for i in (start + 1)..<end {
                let pointCoord = CLLocationCoordinate2D(
                    latitude: points[i].latitude,
                    longitude: points[i].longitude
                )
                let distance = perpendicularDistance(
                    point: pointCoord,
                    lineStart: startCoord,
                    lineEnd: endCoord
                )

                if distance > maxDistance {
                    maxDistance = distance
                    maxIndex = i
                }
            }

            // 허용 오차 초과 시 해당 포인트 유지
            if maxDistance > tolerance {
                result[maxIndex] = true
                stack.append((start, maxIndex))
                stack.append((maxIndex, end))
            }
        }

        // 유지할 포인트만 반환
        return points.enumerated().compactMap { index, point in
            result[index] ? point : nil
        }
    }

    /// 점에서 선분까지의 수직 거리 계산
    /// - Parameters:
    ///   - point: 대상 점
    ///   - lineStart: 선분 시작점
    ///   - lineEnd: 선분 끝점
    /// - Returns: 수직 거리 (미터)
    private func perpendicularDistance(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> Double {
        // 선분의 길이가 0인 경우 점과 시작점 사이의 거리 반환
        let lineLength = distance(from: lineStart, to: lineEnd)
        if lineLength == 0 {
            return distance(from: point, to: lineStart)
        }

        // 선분 위의 가장 가까운 점까지의 파라미터 t 계산
        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude
        let t = max(0, min(1, (
            (point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy
        ) / (dx * dx + dy * dy)))

        // 선분 위의 가장 가까운 점
        let closestPoint = CLLocationCoordinate2D(
            latitude: lineStart.latitude + t * dy,
            longitude: lineStart.longitude + t * dx
        )

        return distance(from: point, to: closestPoint)
    }

    /// 두 좌표 사이의 거리 계산 (미터)
    private func distance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
}
