//
//  AutoZoomLevel.swift
//  HoguMeter
//
//  Created on 2025-12-15.
//

import MapKit

/// 자동 줌 레벨 설정
enum AutoZoomLevel: CaseIterable {
    case stationary     // 정차 (0-5 km/h)
    case slow           // 서행 (5-20 km/h)
    case city           // 시내 (20-40 km/h)
    case suburban       // 외곽 (40-60 km/h)
    case highway        // 간선도로 (60-80 km/h)
    case expressway     // 고속도로 (80+ km/h)

    /// 속도 범위 (km/h)
    var speedRange: ClosedRange<Double> {
        switch self {
        case .stationary:  return 0...5
        case .slow:        return 5...20
        case .city:        return 20...40
        case .suburban:    return 40...60
        case .highway:     return 60...80
        case .expressway:  return 80...200
        }
    }

    /// 지도 축척 (latitudeDelta)
    var span: MKCoordinateSpan {
        switch self {
        case .stationary:  return MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)   // ~300m
        case .slow:        return MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)   // ~500m
        case .city:        return MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)   // ~800m
        case .suburban:    return MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)   // ~1.2km
        case .highway:     return MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)   // ~1.8km
        case .expressway:  return MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)   // ~2.5km
        }
    }

    /// 속도로부터 줌 레벨 결정
    static func from(speed: Double) -> AutoZoomLevel {
        for level in AutoZoomLevel.allCases {
            if level.speedRange.contains(speed) {
                return level
            }
        }
        return .expressway
    }
}
