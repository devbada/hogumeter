//
//  DataManagementSettings.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation

// MARK: - Cleanup Policy

/// Cleanup policy types for automatic data cleanup
enum CleanupPolicy: Codable, Equatable {
    case ageBased(months: Int)
    case countBased(maxCount: Int)
    case sizeBased(maxMB: Int)

    var displayName: String {
        switch self {
        case .ageBased(let months):
            return "\(months)개월 이후 삭제"
        case .countBased(let count):
            return "\(count)개 초과 시 삭제"
        case .sizeBased(let mb):
            return "\(mb)MB 초과 시 삭제"
        }
    }

    var shortDescription: String {
        switch self {
        case .ageBased:
            return "기간 기반"
        case .countBased:
            return "개수 기반"
        case .sizeBased:
            return "용량 기반"
        }
    }
}

// MARK: - Cleanup Policy Type (for UI picker)

enum CleanupPolicyType: String, CaseIterable, Identifiable {
    case ageBased = "age"
    case countBased = "count"
    case sizeBased = "size"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ageBased: return "기간 기반"
        case .countBased: return "개수 기반"
        case .sizeBased: return "용량 기반"
        }
    }

    var description: String {
        switch self {
        case .ageBased: return "일정 기간이 지난 기록 삭제"
        case .countBased: return "일정 개수 초과 시 오래된 기록 삭제"
        case .sizeBased: return "일정 용량 초과 시 오래된 기록 삭제"
        }
    }
}

// MARK: - Data Management Settings

/// Settings for data storage and cleanup
struct DataManagementSettings: Codable, Equatable {
    /// Whether to save route data (for map display)
    var saveRouteData: Bool

    /// Whether automatic cleanup is enabled
    var autoCleanupEnabled: Bool

    /// Cleanup policy
    var cleanupPolicy: CleanupPolicy

    /// Whether to delete only route data (keep metadata) when cleaning
    var deleteRouteOnly: Bool

    /// Default settings
    static let `default` = DataManagementSettings(
        saveRouteData: true,
        autoCleanupEnabled: false,
        cleanupPolicy: .ageBased(months: 6),
        deleteRouteOnly: true
    )

    /// Initialize with default values
    init(
        saveRouteData: Bool = true,
        autoCleanupEnabled: Bool = false,
        cleanupPolicy: CleanupPolicy = .ageBased(months: 6),
        deleteRouteOnly: Bool = true
    ) {
        self.saveRouteData = saveRouteData
        self.autoCleanupEnabled = autoCleanupEnabled
        self.cleanupPolicy = cleanupPolicy
        self.deleteRouteOnly = deleteRouteOnly
    }
}
