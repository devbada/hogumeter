//
//  RouteManager.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import CoreLocation
import Combine

class RouteManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var routePoints: [RoutePoint] = []
    @Published private(set) var startLocation: CLLocationCoordinate2D?

    // MARK: - Properties
    private let minimumDistance: Double = 5.0 // 최소 5m 이동 시에만 포인트 추가

    /// 메모리 관리를 위한 최대 포인트 수 (약 10km 분량, 5m 간격 기준 2000개)
    private let maxRoutePoints: Int = 2000

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

    var totalDistance: Double {
        guard routePoints.count >= 2 else { return 0 }

        var distance: Double = 0
        for i in 1..<routePoints.count {
            let prev = CLLocation(latitude: routePoints[i-1].latitude, longitude: routePoints[i-1].longitude)
            let curr = CLLocation(latitude: routePoints[i].latitude, longitude: routePoints[i].longitude)
            distance += curr.distance(from: prev)
        }
        return distance
    }

    // MARK: - Methods
    func startNewRoute(at location: CLLocation) {
        routePoints = []
        cachedCoordinates = []
        startLocation = location.coordinate
        addPoint(location)
    }

    func addPoint(_ location: CLLocation) {
        let newPoint = RoutePoint(location: location)

        // 이전 포인트와 거리 체크
        if let lastPoint = routePoints.last {
            let lastLocation = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
            let distance = location.distance(from: lastLocation)

            // 최소 거리 이상 이동했을 때만 추가
            guard distance >= minimumDistance else { return }
        }

        routePoints.append(newPoint)
        cachedCoordinates.append(newPoint.coordinate)

        // 메모리 관리: 최대 개수 초과 시 오래된 포인트 제거 (시작점 제외)
        if routePoints.count > maxRoutePoints {
            let removeCount = routePoints.count - maxRoutePoints
            routePoints.removeFirst(removeCount)
            cachedCoordinates.removeFirst(removeCount)
        }
    }

    func clearRoute() {
        routePoints = []
        cachedCoordinates = []
        startLocation = nil
    }
}
