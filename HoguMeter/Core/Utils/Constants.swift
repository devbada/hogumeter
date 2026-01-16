//
//  Constants.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

enum Constants {

    // MARK: - App
    enum App {
        static let name = "호구미터"
        static let version = "1.1.1"
        static let slogan = "내 차 탔으면 내놔"
    }

    // MARK: - Location
    enum Location {
        static let lowSpeedThreshold: Double = 15.0  // km/h
        static let gpsUpdateInterval: TimeInterval = 1.0  // seconds
        static let distanceFilter: Double = 10.0  // meters
    }

    // MARK: - Fare
    enum Fare {
        static let defaultRegionCode = "seoul"
        static let defaultRegionSurcharge = 2000  // 원
    }

    // MARK: - Animation
    enum Animation {
        static let transitionDuration: Double = 0.3
        static let targetFPS: Double = 60.0
    }
}
