//
//  SpeedCamera.swift
//  HoguMeter
//
//  Created on 2026-06-23.
//

import CoreLocation
import Foundation

struct SpeedCamera: Identifiable, Equatable {
    let id: String
    let name: String
    let cameraType: String
    let limitKmh: Int?
    let sido: String?
    let sigungu: String?
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: SpeedCamera, rhs: SpeedCamera) -> Bool {
        lhs.id == rhs.id
    }
}

struct SpeedCameraWarning: Equatable {
    let camera: SpeedCamera
    let distanceM: CLLocationDistance
    let currentSpeedKmh: Double

    var overspeedKmh: Int {
        guard let limitKmh = camera.limitKmh else { return 0 }
        return max(0, Int(currentSpeedKmh.rounded()) - limitKmh)
    }

    var isSpeeding: Bool {
        overspeedKmh >= 3
    }

    var title: String {
        if let limitKmh = camera.limitKmh {
            return "\(limitKmh)km/h 단속 카메라"
        }
        return "단속 카메라"
    }

    var message: String {
        if isSpeeding, let limitKmh = camera.limitKmh {
            return "\(Int(distanceM))m 앞 · 현재 \(Int(currentSpeedKmh))km/h · 제한 \(limitKmh)km/h 초과"
        }
        return "\(Int(distanceM))m 앞 안전운전"
    }
}
