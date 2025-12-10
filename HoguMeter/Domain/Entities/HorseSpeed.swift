//
//  HorseSpeed.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import Foundation

/// 속도 구간별 말의 상태를 정의하는 Enum (5단계)
enum HorseSpeed: String, CaseIterable {
    case walk = "walk"           // 0 ~ 5 km/h
    case trot = "trot"           // 5 ~ 10 km/h
    case run = "run"             // 10 ~ 30 km/h
    case gallop = "gallop"       // 30 ~ 100 km/h
    case rocket = "rocket"       // 100+ km/h

    /// 한글 표시명
    var displayName: String {
        switch self {
        case .walk: return "걷기"
        case .trot: return "빠른 걸음"
        case .run: return "달리기"
        case .gallop: return "질주본능 발휘"
        case .rocket: return "로켓포 발사"
        }
    }

    /// 이모지 아이콘
    var emoji: String {
        switch self {
        case .walk: return "🐴"
        case .trot: return "🐎"
        case .run: return "🏃‍♂️🐴"
        case .gallop: return "🔥🐴💨"
        case .rocket: return "🚀🐴💥"
        }
    }

    /// 속도로부터 HorseSpeed 결정
    static func from(speed: Double) -> HorseSpeed {
        switch speed {
        case 0..<5: return .walk
        case 5..<10: return .trot
        case 10..<30: return .run
        case 30..<100: return .gallop
        default: return .rocket
        }
    }

    /// 애니메이션 속도 (초당 발걸음 수)
    var animationSpeed: Double {
        switch self {
        case .walk: return 1.0      // 1초에 1걸음
        case .trot: return 2.0      // 1초에 2걸음
        case .run: return 4.0       // 1초에 4걸음
        case .gallop: return 8.0    // 1초에 8걸음
        case .rocket: return 16.0   // 1초에 16걸음 (초고속)
        }
    }

    /// 특수 효과 필요 여부
    var needsSpecialEffects: Bool {
        switch self {
        case .walk, .trot, .run:
            return false
        case .gallop, .rocket:
            return true
        }
    }

    /// 로켓 모드 여부
    var isRocketMode: Bool {
        self == .rocket
    }
}
