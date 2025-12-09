//
//  CLLocation+Extensions.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import CoreLocation

extension CLLocation {

    /// 현재 속도를 km/h로 반환
    var speedInKilometersPerHour: Double {
        max(0, speed * 3.6)
    }

    /// 위치 정확도가 유효한지 확인
    var isAccurate: Bool {
        horizontalAccuracy >= 0 && horizontalAccuracy < 50
    }
}
