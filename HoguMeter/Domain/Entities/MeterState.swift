//
//  MeterState.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

enum MeterState {
    case idle       // 대기 중
    case running    // 주행 중
    case stopped    // 정지됨
}

enum HorseSpeed {
    case idle           // 0 km/h
    case walk           // 1-20 km/h
    case trot           // 21-40 km/h
    case run            // 41-60 km/h
    case gallop         // 61-80 km/h
    case sprint         // 80+ km/h
}
