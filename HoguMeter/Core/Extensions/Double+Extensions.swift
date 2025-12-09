//
//  Double+Extensions.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

extension Double {

    /// 미터를 킬로미터로 변환
    var metersToKilometers: Double {
        self / 1000.0
    }

    /// m/s를 km/h로 변환
    var metersPerSecondToKilometersPerHour: Double {
        self * 3.6
    }

    /// 소수점 자릿수 지정 포맷
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    /// 천단위 구분자 포함 문자열
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
