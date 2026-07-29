import Foundation
import os.signpost

/// 개인정보 없이 호구게이션 hot path의 시간과 횟수만 Instruments에 남긴다.
final class HoguNavigationPerformanceMonitor {
    static let shared = HoguNavigationPerformanceMonitor()

    enum Span {
        case locationCallback, routeProjection, guidance, speedCamera, mapUpdate, overlayRebuild, cameraUpdate

        var signpostName: StaticString {
            switch self {
            case .locationCallback: "locationCallback"
            case .routeProjection: "routeProjection"
            case .guidance: "guidance"
            case .speedCamera: "speedCamera"
            case .mapUpdate: "mapUpdate"
            case .overlayRebuild: "overlayRebuild"
            case .cameraUpdate: "cameraUpdate"
            }
        }
    }

    private let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.hogumeter.app", category: "HoguNavigationPerformance")
    private static let isEnabled = _isDebugAssertConfiguration()
    private init() {}

    func begin(_ span: Span) -> OSSignpostID {
        guard Self.isEnabled else { return .invalid }
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: span.signpostName, signpostID: id)
        return id
    }

    func end(_ span: Span, id: OSSignpostID) {
        guard Self.isEnabled else { return }
        os_signpost(.end, log: log, name: span.signpostName, signpostID: id)
    }

    func event(_ name: StaticString, count: Int = 1) {
        guard Self.isEnabled else { return }
        os_signpost(.event, log: log, name: name, "%{public}d", count)
    }

    func thermalStateChanged(level: Int) {
        guard Self.isEnabled else { return }
        os_signpost(.event, log: log, name: "thermalState", "%{public}d", level)
    }
}
