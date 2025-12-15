//
//  TaxiHorseAnnotation.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import MapKit

class TaxiHorseAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var heading: Double // 진행 방향 (0-360도)
    var speed: Double   // 속도 (km/h)

    init(coordinate: CLLocationCoordinate2D, heading: Double = 0, speed: Double = 0) {
        self.coordinate = coordinate
        self.heading = heading
        self.speed = speed
        super.init()
    }

    func update(coordinate: CLLocationCoordinate2D, heading: Double, speed: Double) {
        self.coordinate = coordinate
        self.heading = heading
        self.speed = speed
    }
}
