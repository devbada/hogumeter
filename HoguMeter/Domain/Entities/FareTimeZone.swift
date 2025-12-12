//
//  FareTimeZone.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import Foundation

/// 택시 요금 시간대 구분
enum FareTimeZone: String, CaseIterable, Codable {
    case day = "day"            // 주간: 04:00 ~ 22:00
    case night1 = "night1"      // 심야1: 22:00 ~ 23:00, 02:00 ~ 04:00 (20% 할증)
    case night2 = "night2"      // 심야2: 23:00 ~ 02:00 (40% 할증)

    /// 시간대 표시명
    var displayName: String {
        switch self {
        case .day: return "주간"
        case .night1: return "심야 (20%)"
        case .night2: return "심야 (40%)"
        }
    }

    /// 시간대 범위
    var timeRange: String {
        switch self {
        case .day: return "04:00 ~ 22:00"
        case .night1: return "22:00 ~ 23:00, 02:00 ~ 04:00"
        case .night2: return "23:00 ~ 02:00"
        }
    }

    /// 할증률
    var surchargeRate: Double {
        switch self {
        case .day: return 0.0
        case .night1: return 0.2    // 20%
        case .night2: return 0.4    // 40%
        }
    }

    /// 이모지 아이콘
    var icon: String {
        switch self {
        case .day: return "☀️"
        case .night1: return "🌙"
        case .night2: return "🌑"
        }
    }

    /// 현재 시간에 해당하는 시간대 계산
    /// - Parameter date: 기준 날짜 (기본값: 현재 시간)
    /// - Returns: 해당하는 FareTimeZone
    static func current(from date: Date = Date()) -> FareTimeZone {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 4..<22:
            return .day           // 04:00 ~ 22:00
        case 22..<23:
            return .night1        // 22:00 ~ 23:00
        case 23, 0, 1:
            return .night2        // 23:00 ~ 02:00
        case 2..<4:
            return .night1        // 02:00 ~ 04:00
        default:
            return .day
        }
    }

    /// 특정 시간이 이 시간대에 속하는지 확인
    /// - Parameter date: 확인할 날짜
    /// - Returns: 속하면 true
    func contains(date: Date) -> Bool {
        return FareTimeZone.current(from: date) == self
    }
}
