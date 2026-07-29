import Foundation

enum HoguNavigationOptimizationFlag: String, CaseIterable {
    case sharedLocationSession = "navigationSharedLocationSessionEnabled"
    case routeIndex = "navigationRouteIndexEnabled"
    case cameraIndex = "navigationCameraIndexEnabled"
    case thermalAdaptation = "navigationThermalAdaptationEnabled"
}

struct HoguNavigationOptimizationFlags {
    let values: [HoguNavigationOptimizationFlag: Bool]

    init(userDefaults: UserDefaults = .standard) {
        values = Dictionary(uniqueKeysWithValues: HoguNavigationOptimizationFlag.allCases.map { flag in
            let stored = userDefaults.object(forKey: flag.rawValue) as? Bool
            return (flag, stored ?? true)
        })
    }

    subscript(_ flag: HoguNavigationOptimizationFlag) -> Bool { values[flag] ?? true }
}
