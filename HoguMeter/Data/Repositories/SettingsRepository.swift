//
//  SettingsRepository.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class SettingsRepository {

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let currentRegionCode = "currentRegionCode"
        static let isNightSurchargeEnabled = "isNightSurchargeEnabled"
        static let isRegionSurchargeEnabled = "isRegionSurchargeEnabled"
        static let regionSurchargeAmount = "regionSurchargeAmount"
        static let isSoundEnabled = "isSoundEnabled"
        static let colorSchemePreference = "colorSchemePreference"
    }

    enum ColorSchemePreference: String {
        case system
        case light
        case dark
    }

    // MARK: - Dependencies
    private let userDefaults: UserDefaults
    private let regionFareRepository: RegionFareRepository

    // MARK: - Init
    init(
        userDefaults: UserDefaults = .standard,
        regionFareRepository: RegionFareRepository = RegionFareRepository()
    ) {
        self.userDefaults = userDefaults
        self.regionFareRepository = regionFareRepository
    }

    // MARK: - Current Region Fare
    var currentRegionFare: RegionFare {
        let code = userDefaults.string(forKey: Keys.currentRegionCode) ?? "seoul"
        return regionFareRepository.getFare(byCode: code) ?? regionFareRepository.allFares.first!
    }

    func setCurrentRegion(code: String) {
        userDefaults.set(code, forKey: Keys.currentRegionCode)
    }

    // MARK: - Night Surcharge
    var isNightSurchargeEnabled: Bool {
        get {
            userDefaults.object(forKey: Keys.isNightSurchargeEnabled) as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: Keys.isNightSurchargeEnabled)
        }
    }

    // MARK: - Region Surcharge
    var isRegionSurchargeEnabled: Bool {
        get {
            userDefaults.object(forKey: Keys.isRegionSurchargeEnabled) as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: Keys.isRegionSurchargeEnabled)
        }
    }

    var regionSurchargeAmount: Int {
        get {
            let amount = userDefaults.integer(forKey: Keys.regionSurchargeAmount)
            return amount > 0 ? amount : 2000  // 기본값 2000원
        }
        set {
            userDefaults.set(newValue, forKey: Keys.regionSurchargeAmount)
        }
    }

    // MARK: - Sound
    var isSoundEnabled: Bool {
        get {
            userDefaults.object(forKey: Keys.isSoundEnabled) as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: Keys.isSoundEnabled)
        }
    }

    // MARK: - Color Scheme
    var colorSchemePreference: ColorSchemePreference {
        get {
            let rawValue = userDefaults.string(forKey: Keys.colorSchemePreference) ?? "system"
            return ColorSchemePreference(rawValue: rawValue) ?? .system
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.colorSchemePreference)
        }
    }
}
