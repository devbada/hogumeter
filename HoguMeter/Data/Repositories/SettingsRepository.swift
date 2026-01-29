//
//  SettingsRepository.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

// MARK: - Protocol for testability

protocol SettingsRepositoryProtocol {
    var currentRegionFare: RegionFare { get }
    var isRegionSurchargeEnabled: Bool { get set }
    var regionalSurchargeMode: RegionalSurchargeMode { get set }
    var regionSurchargeAmount: Int { get set }
    var isSoundEnabled: Bool { get set }
}

// MARK: - Implementation

final class SettingsRepository: SettingsRepositoryProtocol {

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let currentRegionCode = "currentRegionCode"
        static let isNightSurchargeEnabled = "isNightSurchargeEnabled"
        static let isRegionSurchargeEnabled = "isRegionSurchargeEnabled"
        static let regionSurchargeAmount = "regionSurchargeAmount"
        static let regionalSurchargeMode = "regionalSurchargeMode"
        static let isSoundEnabled = "isSoundEnabled"
        static let colorSchemePreference = "colorSchemePreference"
        static let dataManagementSettings = "dataManagementSettings"
        static let receiptTemplate = "receiptTemplate"
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

    /// 지역 할증 모드 (리얼/재미/끄기)
    var regionalSurchargeMode: RegionalSurchargeMode {
        get {
            let rawValue = userDefaults.string(forKey: Keys.regionalSurchargeMode) ?? RegionalSurchargeMode.realistic.rawValue
            return RegionalSurchargeMode(rawValue: rawValue) ?? .realistic
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.regionalSurchargeMode)
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

    // MARK: - Data Management Settings
    var dataManagementSettings: DataManagementSettings {
        get {
            guard let data = userDefaults.data(forKey: Keys.dataManagementSettings) else {
                return DataManagementSettings.default
            }
            do {
                return try JSONDecoder().decode(DataManagementSettings.self, from: data)
            } catch {
                return DataManagementSettings.default
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                userDefaults.set(data, forKey: Keys.dataManagementSettings)
            } catch {
                print("[SettingsRepository] Failed to encode data management settings: \(error)")
            }
        }
    }

    // MARK: - Receipt Template
    var receiptTemplate: ReceiptTemplate {
        get {
            let rawValue = userDefaults.string(forKey: Keys.receiptTemplate) ?? ReceiptTemplate.classic.rawValue
            return ReceiptTemplate(rawValue: rawValue) ?? .classic
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.receiptTemplate)
        }
    }
}
