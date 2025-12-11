//
//  FareBreakdown.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

struct FareBreakdown: Codable, Equatable {
    let baseFare: Int
    let distanceFare: Int
    let timeFare: Int
    let regionSurcharge: Int
    let nightSurcharge: Int

    var totalFare: Int {
        baseFare + distanceFare + timeFare + regionSurcharge + nightSurcharge
    }
}
