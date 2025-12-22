//
//  GPSSignalState.swift
//  HoguMeter
//
//  Created on 2025-12-22.
//

import Foundation
import CoreLocation

/// GPS 신호 상태
enum GPSSignalState: Equatable {
    case normal     // 정상: horizontalAccuracy < 30m
    case weak       // 약함: horizontalAccuracy 30-100m
    case lost       // 손실: horizontalAccuracy > 100m, 음수, 또는 업데이트 없음

    /// 신호 상태 표시명
    var displayName: String {
        switch self {
        case .normal: return "정상"
        case .weak: return "약함"
        case .lost: return "손실"
        }
    }

    /// 신호 상태 아이콘
    var icon: String {
        switch self {
        case .normal: return "location.fill"
        case .weak: return "location"
        case .lost: return "location.slash"
        }
    }

    /// horizontalAccuracy 값으로 신호 상태 판단
    /// - Parameter accuracy: CLLocation의 horizontalAccuracy 값 (미터)
    /// - Returns: 해당하는 GPSSignalState
    static func from(accuracy: CLLocationAccuracy) -> GPSSignalState {
        // 음수: GPS 신호 없음
        if accuracy < 0 {
            return .lost
        }
        // 30m 미만: 정상
        if accuracy < 30 {
            return .normal
        }
        // 30-100m: 약함
        if accuracy < 100 {
            return .weak
        }
        // 100m 이상: 손실로 간주
        return .lost
    }
}

/// GPS 신호 손실 시 저장되는 마지막 유효 위치 정보
struct LastKnownLocationInfo {
    let location: CLLocation
    let speed: Double           // m/s
    let signalLostAt: Date

    /// 신호 손실 후 경과 시간 (초)
    var elapsedSinceSignalLost: TimeInterval {
        return Date().timeIntervalSince(signalLostAt)
    }

    /// 추정 이동 거리 (마지막 속도 × 경과 시간)
    var estimatedDistance: Double {
        guard speed > 0 else { return 0 }
        return speed * elapsedSinceSignalLost
    }
}
