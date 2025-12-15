//
//  RoutePoint.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import CoreLocation

struct RoutePoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double       // km/h
    let accuracy: Double    // meters

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = max(0, location.speed * 3.6)
        self.accuracy = location.horizontalAccuracy
    }
}
