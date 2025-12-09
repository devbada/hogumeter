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

    static let location = OSLog(subsystem: subsystem, category: "Location")
    static let fare = OSLog(subsystem: subsystem, category: "Fare")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let general = OSLog(subsystem: subsystem, category: "General")

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
