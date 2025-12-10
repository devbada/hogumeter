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
    case walk           // 0-5 km/h
    case trot           // 5-10 km/h
    case run            // 10-30 km/h
    case gallop         // 30-100 km/h
    case rocket         // 100+ km/h
}
