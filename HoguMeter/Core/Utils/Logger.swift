//
//  Logger.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import os.log

enum Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.hogumeter"

    // MARK: - Log Categories (OSLog)
    static let location = OSLog(subsystem: subsystem, category: "Location")
    static let fare = OSLog(subsystem: subsystem, category: "Fare")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let general = OSLog(subsystem: subsystem, category: "General")

    // MARK: - Category Loggers
    static let gps = CategoryLogger(category: "GPS")
    static let meter = CategoryLogger(category: "Meter")
    static let network = CategoryLogger(category: "Network")

    // MARK: - Legacy Methods (Backward Compatibility)
    static func log(_ message: String, log: OSLog = Logger.general, type: OSLogType = .default) {
        os_log("%{public}@", log: log, type: type, message)
    }

    static func error(_ message: String, log: OSLog = Logger.general) {
        os_log("%{public}@", log: log, type: .error, message)
    }

    static func debug(_ message: String, log: OSLog = Logger.general) {
        #if DEBUG
        os_log("%{public}@", log: log, type: .debug, message)
        #endif
    }
}

// MARK: - Category Logger

/// 카테고리별 로거 - 더 편리한 API 제공
struct CategoryLogger {
    private let osLog: OSLog

    init(category: String) {
        let subsystem = Bundle.main.bundleIdentifier ?? "com.hogumeter"
        self.osLog = OSLog(subsystem: subsystem, category: category)
    }

    /// 정보 로그
    func info(_ message: String) {
        os_log("%{public}@", log: osLog, type: .info, message)
    }

    /// 디버그 로그 (DEBUG 빌드에서만 출력)
    func debug(_ message: String) {
        #if DEBUG
        os_log("%{public}@", log: osLog, type: .debug, message)
        #endif
    }

    /// 경고 로그
    func warning(_ message: String) {
        os_log("%{public}@", log: osLog, type: .default, "⚠️ " + message)
    }

    /// 에러 로그
    func error(_ message: String) {
        os_log("%{public}@", log: osLog, type: .error, "❌ " + message)
    }

    /// 기본 로그
    func log(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: osLog, type: type, message)
    }
}
