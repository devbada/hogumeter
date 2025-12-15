//
//  StartPointAnnotation.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import MapKit

class StartPointAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String? = "출발"

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}
