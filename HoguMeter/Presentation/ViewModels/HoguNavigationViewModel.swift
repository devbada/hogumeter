//
//  HoguNavigationViewModel.swift
//  HoguMeter
//
//  Created on 2026-06-23.
//

import Foundation
import CoreLocation
import MapKit
import Combine

enum HoguNavigationInputTarget: String, Codable, Hashable {
    case origin
    case destination
}

struct HoguNavigationSearchResult: Identifiable {
    let id = UUID()
    let completion: MKLocalSearchCompletion

    var title: String {
        completion.title
    }

    var subtitle: String {
        completion.subtitle
    }
}

enum HoguNavigationSearchResultPolicy {
    static let visibleLimit = 12

    private struct NormalizedKey: Hashable {
        let title: String
        let subtitle: String
    }

    static func visibleResults<Element>(
        _ results: [Element],
        title: (Element) -> String,
        subtitle: (Element) -> String
    ) -> [Element] {
        var seen = Set<NormalizedKey>()
        var visible: [Element] = []
        visible.reserveCapacity(min(results.count, visibleLimit))

        for result in results {
            let key = NormalizedKey(
                title: normalized(title(result)),
                subtitle: normalized(subtitle(result))
            )
            guard seen.insert(key).inserted else { continue }
            visible.append(result)
            if visible.count == visibleLimit { break }
        }

        return visible
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
    }
}

struct HoguNavigationSearchResponseToken: Equatable {
    let query: String
    let target: HoguNavigationInputTarget
    let generation: Int
}

struct HoguNavigationSearchResponseGate {
    private(set) var generation = 0

    mutating func advance() {
        generation += 1
    }

    func capture(query: String, target: HoguNavigationInputTarget) -> HoguNavigationSearchResponseToken {
        HoguNavigationSearchResponseToken(
            query: Self.trimmed(query),
            target: target,
            generation: generation
        )
    }

    func accepts(
        _ token: HoguNavigationSearchResponseToken,
        activeQuery: String,
        selectedTarget: HoguNavigationInputTarget
    ) -> Bool {
        token.generation == generation
            && token.query == Self.trimmed(activeQuery)
            && token.target == selectedTarget
    }

    private static func trimmed(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct HoguNavigationRouteCalculationGate {
    private(set) var generation = 0

    mutating func start() -> Int {
        generation += 1
        return generation
    }

    mutating func invalidate() {
        generation += 1
    }

    func accepts(_ capturedGeneration: Int) -> Bool {
        generation == capturedGeneration
    }
}

struct HoguNavigationRecentPlace: Codable, Equatable, Identifiable {
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let target: HoguNavigationInputTarget
    let updatedAt: Date

    var id: String {
        "\(target.rawValue)-\(title)-\(subtitle)-\(latitude)-\(longitude)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var mapItem: MKMapItem {
        MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
    }
}

struct HoguNavigationRecentRoute: Codable, Equatable, Identifiable {
    let originName: String
    let destinationName: String
    let originLatitude: Double
    let originLongitude: Double
    let destinationLatitude: Double
    let destinationLongitude: Double
    let updatedAt: Date

    var id: String {
        "\(originName)-\(destinationName)-\(originLatitude)-\(originLongitude)-\(destinationLatitude)-\(destinationLongitude)"
    }

    var originCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: originLatitude, longitude: originLongitude)
    }

    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }

    var originMapItem: MKMapItem {
        MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
    }

    var destinationMapItem: MKMapItem {
        MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
    }
}

enum HoguNavigationRecentSuggestion: Identifiable {
    case route(HoguNavigationRecentRoute)
    case place(HoguNavigationRecentPlace)

    var id: String {
        switch self {
        case .route(let route):
            return "route-\(route.id)"
        case .place(let place):
            return "place-\(place.id)"
        }
    }

    var icon: String {
        switch self {
        case .route:
            return "arrow.triangle.turn.up.right.diamond.fill"
        case .place(let place):
            return place.target == .origin ? "location.fill" : "mappin.and.ellipse"
        }
    }

    var title: String {
        switch self {
        case .route(let route):
            return route.destinationName
        case .place(let place):
            return place.title
        }
    }

    var subtitle: String {
        switch self {
        case .route(let route):
            return "\(route.originName) → \(route.destinationName)"
        case .place(let place):
            return place.subtitle
        }
    }
}

struct HoguNavigationRoutePreview {
    let originName: String
    let destinationName: String
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let expectedFare: Int
    let polyline: MKPolyline
    let originCoordinate: CLLocationCoordinate2D
    let destinationCoordinate: CLLocationCoordinate2D
    let guidanceSteps: [HoguNavigationRouteStep]
    /// 현재 재탐색 구간의 원래 전체 거리. 화면 표시는 distance(남은 거리)를 사용한다.
    let segmentDistance: CLLocationDistance
    /// 현재 경로 구간 자체의 ETA. 진행률에 맞춰 남은 시간을 계산할 때 기준값으로 쓴다.
    let segmentExpectedTravelTime: TimeInterval
    /// 안내를 시작한 시점의 전체 경로 길이. 재탐색 뒤에도 이미 이동한 구간을 보존한다.
    let accumulatedDistance: CLLocationDistance
    /// 안내를 시작한 시점부터 경과한 예상 시간. 재탐색 뒤 총 ETA 산정에 사용한다.
    let accumulatedExpectedTravelTime: TimeInterval
}

struct HoguNavigationRouteStep {
    let instruction: String
    let startDistance: CLLocationDistance
    let distance: CLLocationDistance
    let maneuver: HoguNavigationManeuver
}

enum HoguNavigationManeuver: Equatable {
    case left
    case right
    case straight
    case uTurn

    var iconName: String {
        switch self {
        case .left: return "arrow.turn.up.left"
        case .right: return "arrow.turn.up.right"
        case .straight: return "arrow.up"
        case .uTurn: return "arrow.uturn.left"
        }
    }

    var koreanLabel: String {
        switch self {
        case .left: return "좌회전"
        case .right: return "우회전"
        case .straight: return "직진"
        case .uTurn: return "유턴"
        }
    }
}

enum HoguNavigationManeuverResolver {
    static func maneuver(inboundHeading: CLLocationDirection, outboundHeading: CLLocationDirection) -> HoguNavigationManeuver {
        let delta = signedHeadingDelta(from: inboundHeading, to: outboundHeading)
        switch abs(delta) {
        case 150...:
            return .uTurn
        case 35..<150:
            return delta > 0 ? .right : .left
        default:
            return .straight
        }
    }

    static func guidance(instruction: String, inboundHeading: CLLocationDirection?, outboundHeading: CLLocationDirection?) -> (text: String, maneuver: HoguNavigationManeuver) {
        let sourceManeuver = maneuver(in: instruction)
        guard let inboundHeading, let outboundHeading else {
            return (instruction, sourceManeuver ?? .straight)
        }

        let geometryManeuver = maneuver(inboundHeading: inboundHeading, outboundHeading: outboundHeading)
        let delta = abs(signedHeadingDelta(from: inboundHeading, to: outboundHeading))
        guard geometryManeuver != .straight, delta >= 35 else {
            return (instruction, sourceManeuver ?? geometryManeuver)
        }
        if sourceManeuver == geometryManeuver {
            return (instruction, geometryManeuver)
        }

        let roadText = instruction
            .replacingOccurrences(of: "완만히", with: "")
            .replacingOccurrences(of: "좌회전", with: "")
            .replacingOccurrences(of: "우회전", with: "")
            .replacingOccurrences(of: "유턴", with: "")
            .replacingOccurrences(of: "직진", with: "")
            .replacingOccurrences(of: "하여", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if instruction.unicodeScalars.allSatisfy({ $0.isASCII }) {
            return (geometryManeuver.koreanLabel, geometryManeuver)
        }
        return (roadText.isEmpty ? geometryManeuver.koreanLabel : "\(geometryManeuver.koreanLabel) \(roadText)", geometryManeuver)
    }

    private static func maneuver(in instruction: String) -> HoguNavigationManeuver? {
        if instruction.contains("유턴") { return .uTurn }
        if instruction.contains("좌회전") || instruction.contains("왼쪽") { return .left }
        if instruction.contains("우회전") || instruction.contains("오른쪽") { return .right }
        if instruction.contains("직진") { return .straight }
        return nil
    }

    private static func signedHeadingDelta(from inboundHeading: CLLocationDirection, to outboundHeading: CLLocationDirection) -> CLLocationDirection {
        (outboundHeading - inboundHeading + 540).truncatingRemainder(dividingBy: 360) - 180
    }
}

enum HoguNavigationStepBoundaryResolver {
    static func maneuver(
        previousStepCoordinates: [CLLocationCoordinate2D],
        currentStepCoordinates: [CLLocationCoordinate2D]
    ) -> HoguNavigationManeuver? {
        guard let inbound = heading(in: previousStepCoordinates, fromStart: false),
              let outbound = heading(in: currentStepCoordinates, fromStart: true) else {
            return nil
        }
        return HoguNavigationManeuverResolver.maneuver(inboundHeading: inbound, outboundHeading: outbound)
    }

    static func heading(in coordinates: [CLLocationCoordinate2D], fromStart: Bool) -> CLLocationDirection? {
        guard coordinates.count >= 2 else { return nil }
        let ordered = fromStart ? coordinates : Array(coordinates.reversed())
        guard let anchor = ordered.first else { return nil }
        let anchorLocation = CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
        guard let comparison = ordered.dropFirst().first(where: {
            anchorLocation.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) >= 5
        }) else { return nil }
        return heading(from: fromStart ? anchor : comparison, to: fromStart ? comparison : anchor)
    }

    private static func heading(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDirection {
        let sourceLatitude = source.latitude * .pi / 180
        let destinationLatitude = destination.latitude * .pi / 180
        let longitudeDelta = (destination.longitude - source.longitude) * .pi / 180
        let heading = atan2(sin(longitudeDelta) * cos(destinationLatitude), cos(sourceLatitude) * sin(destinationLatitude) - sin(sourceLatitude) * cos(destinationLatitude) * cos(longitudeDelta)) * 180 / .pi
        return heading >= 0 ? heading : heading + 360
    }
}

enum HoguNavigationGuidanceSelector {
    static func nextStep(
        in steps: [HoguNavigationRouteStep],
        progressDistance: CLLocationDistance,
        lookAhead: CLLocationDistance = 25
    ) -> HoguNavigationRouteStep? {
        steps.first { $0.startDistance > progressDistance + lookAhead }
    }
}

struct HoguNavigationLocationSessionGate {
    private(set) var generation = 0

    mutating func start() -> Int { generation += 1; return generation }
    mutating func stop() { generation += 1 }
    func acceptsOneShot(capturedGeneration: Int, isNavigationStarted: Bool) -> Bool {
        !isNavigationStarted && capturedGeneration == generation
    }
}

final class HoguNavigationSharedLocationSubscription {
    private let publisher: AnyPublisher<CLLocation, Never>
    private let deliveryQueue: DispatchQueue
    private var cancellable: AnyCancellable?
    private var token = 0
    var onLocation: ((CLLocation) -> Void)?

    init(publisher: AnyPublisher<CLLocation, Never>, deliveryQueue: DispatchQueue = .main, onLocation: ((CLLocation) -> Void)? = nil) {
        self.publisher = publisher
        self.deliveryQueue = deliveryQueue
        self.onLocation = onLocation
    }

    func start() {
        guard cancellable == nil else { return }
        token += 1
        let activeToken = token
        cancellable = publisher.sink { [weak self] location in
            guard let self else { return }
            self.deliveryQueue.async { [weak self] in
                guard let self, self.cancellable != nil, self.token == activeToken else { return }
                self.onLocation?(location)
            }
        }
    }

    func stop() {
        token += 1
        cancellable?.cancel()
        cancellable = nil
    }

    deinit { stop() }
}

/// 경로 폴리라인 한 선분에 투영한 결과. 안내, 이탈 판정, 지도 표시에 같은 기준을 사용한다.
struct HoguNavigationRouteProjection {
    let coordinate: CLLocationCoordinate2D
    let distanceToRoute: CLLocationDistance
    let progressDistance: CLLocationDistance
    let segmentIndex: Int
    let segmentRatio: Double
    let heading: CLLocationDirection
}

/// 한 위치 이벤트에서 계산한 경로 투영 결과. 지도와 안내 로직이 같은 결과를 재사용한다.
struct HoguNavigationFrame {
    let location: CLLocation
    let projection: HoguNavigationRouteProjection
    let displayHeading: CLLocationDirection
}

struct HoguNavigationProjectedSpeedCamera {
    let camera: SpeedCamera
    let progressDistance: CLLocationDistance
    let distanceToRoute: CLLocationDistance
}

enum HoguNavigationSpeedCameraCandidateSelector {
    static func upcoming(
        in cameras: [HoguNavigationProjectedSpeedCamera],
        after progressDistance: CLLocationDistance,
        maximumCount: Int = 3
    ) -> [HoguNavigationProjectedSpeedCamera] {
        guard maximumCount > 0 else { return [] }
        var lowerBound = 0
        var upperBound = cameras.count
        while lowerBound < upperBound {
            let midpoint = (lowerBound + upperBound) / 2
            if cameras[midpoint].progressDistance < progressDistance {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }
        return Array(cameras.dropFirst(lowerBound).prefix(maximumCount))
    }
}

struct HoguNavigationSpeedCameraPrecomputeGate {
    private(set) var generation = 0

    mutating func invalidate() -> Int {
        generation += 1
        return generation
    }

    func accepts(_ capturedGeneration: Int) -> Bool {
        generation == capturedGeneration
    }
}

enum HoguNavigationSpeedCameraRegionTransition {
    static func requiresImmediateClear(
        currentRegionKeys: Set<String>,
        nextRegionKeys: Set<String>
    ) -> Bool {
        currentRegionKeys != nextRegionKeys
    }
}

enum HoguNavigationSpeedCameraRouteIndexer {
    static func project(
        cameras: [SpeedCamera],
        using index: RouteProjectionIndex,
        maximumDistanceToRoute: CLLocationDistance = 160
    ) -> [HoguNavigationProjectedSpeedCamera] {
        cameras.compactMap { camera -> HoguNavigationProjectedSpeedCamera? in
            guard let projection = index.project(CLLocation(
                latitude: camera.coordinate.latitude,
                longitude: camera.coordinate.longitude
            )), projection.distanceToRoute <= maximumDistanceToRoute else {
                return nil
            }
            return HoguNavigationProjectedSpeedCamera(
                camera: camera,
                progressDistance: projection.progressDistance,
                distanceToRoute: projection.distanceToRoute
            )
        }
        .sorted { $0.progressDistance < $1.progressDistance }
    }
}

enum HoguNavigationRouteSampleSelector {
    static func representativeCoordinates(
        from coordinates: [CLLocationCoordinate2D],
        maximumCount: Int
    ) -> [CLLocationCoordinate2D] {
        guard maximumCount > 0, !coordinates.isEmpty else { return [] }

        let samples: [CLLocationCoordinate2D]
        if coordinates.count <= maximumCount {
            samples = coordinates
        } else if maximumCount == 1 {
            samples = [coordinates[0]]
        } else {
            samples = (0..<maximumCount).map { index in
                coordinates[Int((Double(index) / Double(maximumCount - 1)) * Double(coordinates.count - 1))]
            }
        }

        return samples.reduce(into: []) { result, coordinate in
            let isDuplicate = result.contains {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                    .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) < 25
            }
            if !isDuplicate { result.append(coordinate) }
        }
    }
}

enum HoguNavigationThermalLevel: Int, Comparable {
    case nominal
    case fair
    case serious
    case critical

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .serious
        }
    }
}

struct HoguNavigationEnergyPolicy: Equatable {
    let thermalLevel: HoguNavigationThermalLevel
    let cameraMinimumInterval: TimeInterval
    let overlayMinimumProgress: CLLocationDistance
    let overlayMinimumInterval: TimeInterval
    let cameraPitch: CGFloat
    let allowsMapAnimation: Bool
    let allowsVehicleAnimation: Bool
    let showsPointsOfInterest: Bool
    let usesOpaqueHUD: Bool

    static func policy(for level: HoguNavigationThermalLevel) -> Self {
        switch level {
        case .nominal:
            return Self(thermalLevel: level, cameraMinimumInterval: 0.5, overlayMinimumProgress: 10, overlayMinimumInterval: 1, cameraPitch: 58, allowsMapAnimation: true, allowsVehicleAnimation: true, showsPointsOfInterest: true, usesOpaqueHUD: false)
        case .fair:
            return Self(thermalLevel: level, cameraMinimumInterval: 1, overlayMinimumProgress: 10, overlayMinimumInterval: 1, cameraPitch: 50, allowsMapAnimation: true, allowsVehicleAnimation: true, showsPointsOfInterest: false, usesOpaqueHUD: false)
        case .serious:
            return Self(thermalLevel: level, cameraMinimumInterval: 1, overlayMinimumProgress: 15, overlayMinimumInterval: 1.5, cameraPitch: 35, allowsMapAnimation: false, allowsVehicleAnimation: false, showsPointsOfInterest: false, usesOpaqueHUD: true)
        case .critical:
            return Self(thermalLevel: level, cameraMinimumInterval: 2, overlayMinimumProgress: .greatestFiniteMagnitude, overlayMinimumInterval: .greatestFiniteMagnitude, cameraPitch: 0, allowsMapAnimation: false, allowsVehicleAnimation: false, showsPointsOfInterest: false, usesOpaqueHUD: true)
        }
    }
}

struct HoguNavigationThermalStateController {
    private(set) var effectiveLevel: HoguNavigationThermalLevel = .nominal
    private var pendingRecoveryLevel: HoguNavigationThermalLevel?
    private var recoveryEligibleAt: Date?

    var recoveryCandidate: HoguNavigationThermalLevel? { pendingRecoveryLevel }
    var recoveryDeadline: Date? { recoveryEligibleAt }

    mutating func receive(_ observedLevel: HoguNavigationThermalLevel, at now: Date) -> HoguNavigationThermalLevel {
        if observedLevel >= effectiveLevel {
            effectiveLevel = observedLevel
            pendingRecoveryLevel = nil
            recoveryEligibleAt = nil
            return effectiveLevel
        }
        if pendingRecoveryLevel != observedLevel {
            pendingRecoveryLevel = observedLevel
            recoveryEligibleAt = now.addingTimeInterval(30)
        }
        return effectiveLevel
    }

    mutating func advance(at now: Date) -> HoguNavigationThermalLevel {
        guard let pendingRecoveryLevel,
              let recoveryEligibleAt,
              now >= recoveryEligibleAt else {
            return effectiveLevel
        }
        effectiveLevel = pendingRecoveryLevel
        self.pendingRecoveryLevel = nil
        self.recoveryEligibleAt = nil
        return effectiveLevel
    }
}

struct HoguNavigationThermalRecoveryScheduler {
    private(set) var generation = 0
    private(set) var candidate: HoguNavigationThermalLevel?
    private(set) var deadline: Date?

    mutating func schedule(candidate: HoguNavigationThermalLevel, deadline: Date) -> Int? {
        guard self.candidate != candidate || self.deadline != deadline else { return nil }
        generation += 1
        self.candidate = candidate
        self.deadline = deadline
        return generation
    }

    mutating func cancel() {
        generation += 1
        candidate = nil
        deadline = nil
    }

    func accepts(_ capturedGeneration: Int, candidate: HoguNavigationThermalLevel, at now: Date) -> Bool {
        generation == capturedGeneration && self.candidate == candidate && (deadline ?? .distantFuture) <= now
    }
}

struct HoguNavigationRenderBudget {
    private(set) var lastCameraUpdateAt = Date.distantPast
    private(set) var lastCameraCoordinate: CLLocationCoordinate2D?
    private(set) var lastCameraHeading: CLLocationDirection?
    private(set) var lastOverlayUpdateAt = Date.distantPast
    private(set) var renderedProgressDistance: CLLocationDistance?

    mutating func shouldUpdateCamera(
        coordinate: CLLocationCoordinate2D,
        heading: CLLocationDirection,
        policy: HoguNavigationEnergyPolicy,
        now: Date
    ) -> Bool {
        guard now.timeIntervalSince(lastCameraUpdateAt) >= policy.cameraMinimumInterval else { return false }
        let movedEnough = lastCameraCoordinate.map {
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                .distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) >= 5
        } ?? true
        let headingChangedEnough = lastCameraHeading.map {
            abs(($0 - heading + 540).truncatingRemainder(dividingBy: 360) - 180) >= 3
        } ?? true
        guard movedEnough || headingChangedEnough || now.timeIntervalSince(lastCameraUpdateAt) >= 3 else { return false }
        lastCameraUpdateAt = now
        lastCameraCoordinate = coordinate
        lastCameraHeading = heading
        return true
    }

    mutating func shouldUpdateOverlay(
        progressDistance: CLLocationDistance,
        policy: HoguNavigationEnergyPolicy,
        now: Date
    ) -> Bool {
        guard now.timeIntervalSince(lastOverlayUpdateAt) >= policy.overlayMinimumInterval else { return false }
        guard let renderedProgressDistance else { return true }
        guard abs(renderedProgressDistance - progressDistance) >= policy.overlayMinimumProgress else { return false }
        lastOverlayUpdateAt = now
        return true
    }

    mutating func recordOverlay(progressDistance: CLLocationDistance, at now: Date) {
        renderedProgressDistance = progressDistance
        lastOverlayUpdateAt = now
    }

    mutating func reset() { self = Self() }
}

final class RouteProjectionIndex {
    let coordinates: [CLLocationCoordinate2D]
    let mapPoints: [MKMapPoint]
    let segmentDistances: [CLLocationDistance]
    let cumulativeDistances: [CLLocationDistance]
    let headings: [CLLocationDirection]
    private(set) var projectionRequestCount = 0

    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        self.mapPoints = coordinates.map(MKMapPoint.init)
        var segments: [CLLocationDistance] = []
        var cumulative: [CLLocationDistance] = [0]
        var headings: [CLLocationDirection] = []
        for index in 0..<max(0, coordinates.count - 1) {
            let start = CLLocation(latitude: coordinates[index].latitude, longitude: coordinates[index].longitude)
            let end = CLLocation(latitude: coordinates[index + 1].latitude, longitude: coordinates[index + 1].longitude)
            let distance = start.distance(from: end)
            segments.append(distance)
            cumulative.append((cumulative.last ?? 0) + distance)
            headings.append(HoguNavigationRouteProjector.heading(from: coordinates[index], to: coordinates[index + 1]))
        }
        self.segmentDistances = segments
        self.cumulativeDistances = cumulative
        self.headings = headings
    }

    func project(_ location: CLLocation) -> HoguNavigationRouteProjection? {
        projectionRequestCount += 1
        guard mapPoints.count >= 2 else { return nil }

        let target = MKMapPoint(location.coordinate)
        var closest: HoguNavigationRouteProjection?

        for index in 0..<segmentDistances.count {
            let segmentDistance = segmentDistances[index]
            guard segmentDistance > 0 else { continue }

            let start = mapPoints[index]
            let end = mapPoints[index + 1]
            let deltaX = end.x - start.x
            let deltaY = end.y - start.y
            let mapLengthSquared = deltaX * deltaX + deltaY * deltaY
            guard mapLengthSquared > 0 else { continue }

            let ratio = min(1, max(0, ((target.x - start.x) * deltaX + (target.y - start.y) * deltaY) / mapLengthSquared))
            let projectedPoint = MKMapPoint(x: start.x + deltaX * ratio, y: start.y + deltaY * ratio)
            let projectedCoordinate = projectedPoint.coordinate
            let distanceToRoute = location.distance(from: CLLocation(
                latitude: projectedCoordinate.latitude,
                longitude: projectedCoordinate.longitude
            ))
            let candidate = HoguNavigationRouteProjection(
                coordinate: projectedCoordinate,
                distanceToRoute: distanceToRoute,
                progressDistance: cumulativeDistances[index] + segmentDistance * ratio,
                segmentIndex: index,
                segmentRatio: ratio,
                heading: headings[index]
            )
            if closest == nil || candidate.distanceToRoute < closest!.distanceToRoute {
                closest = candidate
            }
        }
        return closest
    }
}

enum HoguNavigationRouteProjector {
    static func project(
        coordinate: CLLocationCoordinate2D,
        onto routeCoordinates: [CLLocationCoordinate2D]
    ) -> HoguNavigationRouteProjection? {
        guard routeCoordinates.count >= 2 else { return nil }

        let target = MKMapPoint(coordinate)
        var accumulatedDistance: CLLocationDistance = 0
        var closest: HoguNavigationRouteProjection?

        for index in 0..<(routeCoordinates.count - 1) {
            let startCoordinate = routeCoordinates[index]
            let endCoordinate = routeCoordinates[index + 1]
            let start = MKMapPoint(startCoordinate)
            let end = MKMapPoint(endCoordinate)
            let deltaX = end.x - start.x
            let deltaY = end.y - start.y
            let mapLengthSquared = deltaX * deltaX + deltaY * deltaY
            let segmentDistance = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
                .distance(from: CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude))
            defer { accumulatedDistance += segmentDistance }
            guard mapLengthSquared > 0, segmentDistance > 0 else { continue }

            let ratio = min(1, max(0, ((target.x - start.x) * deltaX + (target.y - start.y) * deltaY) / mapLengthSquared))
            let projectedPoint = MKMapPoint(x: start.x + deltaX * ratio, y: start.y + deltaY * ratio)
            let projectedCoordinate = projectedPoint.coordinate
            let distanceToRoute = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                .distance(from: CLLocation(latitude: projectedCoordinate.latitude, longitude: projectedCoordinate.longitude))
            let candidate = HoguNavigationRouteProjection(
                coordinate: projectedCoordinate,
                distanceToRoute: distanceToRoute,
                progressDistance: accumulatedDistance + segmentDistance * ratio,
                segmentIndex: index,
                segmentRatio: ratio,
                heading: heading(from: startCoordinate, to: endCoordinate)
            )
            if closest == nil || candidate.distanceToRoute < closest!.distanceToRoute {
                closest = candidate
            }
        }
        return closest
    }

    static func heading(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDirection {
        let sourceLatitude = source.latitude * .pi / 180
        let destinationLatitude = destination.latitude * .pi / 180
        let longitudeDelta = (destination.longitude - source.longitude) * .pi / 180
        let heading = atan2(
            sin(longitudeDelta) * cos(destinationLatitude),
            cos(sourceLatitude) * sin(destinationLatitude)
                - sin(sourceLatitude) * cos(destinationLatitude) * cos(longitudeDelta)
        ) * 180 / .pi
        return heading >= 0 ? heading : heading + 360
    }
}

final class HoguNavigationViewModel: NSObject, ObservableObject {

    @Published var originText: String = "현재 위치"
    @Published var destinationText: String = ""
    @Published var searchResults: [HoguNavigationSearchResult] = []
    @Published var recentSuggestions: [HoguNavigationRecentSuggestion] = []
    @Published var selectedSearchTarget: HoguNavigationInputTarget = .destination
    @Published var routePreview: HoguNavigationRoutePreview?
    @Published private(set) var navigationFrame: HoguNavigationFrame?
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var userHeading: CLLocationDirection = 0
    @Published var hasUsableCourse: Bool = false
    @Published var userSpeed: Double = 0
    @Published var speedCameraWarning: SpeedCameraWarning?
    @Published var isResolvingLocation: Bool = false
    @Published var isCalculatingRoute: Bool = false
    @Published var isNavigationStarted: Bool = false
    @Published var isRerouting: Bool = false
    @Published var navigationStatusMessage: String?
    @Published var upcomingRouteInstruction: String?
    @Published var upcomingRouteInstructionDistance: CLLocationDistance?
    @Published var upcomingRouteManeuver: HoguNavigationManeuver?
    @Published var errorMessage: String?
    @Published private(set) var energyPolicy = HoguNavigationEnergyPolicy.policy(for: .nominal)

    private let searchCompleter = MKLocalSearchCompleter()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let fareCalculator: FareCalculator
    private let speedCameraAPIClient = SpeedCameraAPIClient()
    private let userDefaults: UserDefaults
    private let optimizationFlags: HoguNavigationOptimizationFlags
    private let sharedLocationPublisher: AnyPublisher<CLLocation, Never>
    private let sharedLocationSubscription: HoguNavigationSharedLocationSubscription
    private var locationSessionGate = HoguNavigationLocationSessionGate()
    private let recentPlacesKey = "hoguNavigationRecentPlacesV1"
    private let recentRoutesKey = "hoguNavigationRecentRoutesV1"
    private var speedCameras: [SpeedCamera] = []
    private var speedCameraCandidates: [SpeedCamera] = []
    private var projectedSpeedCameraCandidates: [HoguNavigationProjectedSpeedCamera] = []
    private var speedCameraPrecomputeGate = HoguNavigationSpeedCameraPrecomputeGate()
    private var speedCameraRouteGeneration = 0
    private var currentSpeedCameraRegionKeys = Set<String>()
    private var lastWarnedCameraId: String?
    private var originMapItem: MKMapItem?
    private var destinationMapItem: MKMapItem?
    private var currentLocation: CLLocation?
    private var activeSearchQuery: String = ""
    private var searchResponseGate = HoguNavigationSearchResponseGate()
    private var routeCalculationGate = HoguNavigationRouteCalculationGate()
    private var activeRouteCalculation: MKDirections?
    private var hasRequestedInitialLocation = false
    private var usesCurrentLocationAsOrigin = true
    private var lastRerouteAt: Date?
    private var routeDeviationCandidateCount = 0
    private var lastRouteProgressDistance: CLLocationDistance?
    private var routeProjectionIndex: RouteProjectionIndex?
    private var thermalStateController = HoguNavigationThermalStateController()
    private var thermalRecoveryScheduler = HoguNavigationThermalRecoveryScheduler()
    private var thermalStateObserver: NSObjectProtocol?
    private var thermalRecoveryWorkItem: DispatchWorkItem?
    private let routeDeviationThreshold: CLLocationDistance = 120
    private let rerouteMinimumInterval: TimeInterval = 45
    private let routeDeviationConfirmationCount = 3
    private let routeDeviationAccuracyLimit: CLLocationAccuracy = 35
    private let highSpeedDeviationHoldSpeed: CLLocationSpeed = 9.7
    private let highSpeedDeviationHoldDistance: CLLocationDistance = 250
    private let guidanceSnapDistanceLimit: CLLocationDistance = 90
    private let maximumLocationAge: TimeInterval = 12
    private let maximumHorizontalAccuracy: CLLocationAccuracy = 80
    private let minimumRoutePreviewDuration: TimeInterval = 60

    var hasSearchListItems: Bool {
        !recentSuggestions.isEmpty || !searchResults.isEmpty
    }

    init(
        fareCalculator: FareCalculator,
        sharedLocationPublisher: AnyPublisher<CLLocation, Never>,
        userDefaults: UserDefaults = .standard
    ) {
        self.fareCalculator = fareCalculator
        self.sharedLocationPublisher = sharedLocationPublisher
        self.sharedLocationSubscription = HoguNavigationSharedLocationSubscription(publisher: sharedLocationPublisher)
        self.userDefaults = userDefaults
        self.optimizationFlags = HoguNavigationOptimizationFlags(userDefaults: userDefaults)
        super.init()
        sharedLocationSubscription.onLocation = { [weak self] location in
            self?.handleLocation(location)
        }
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)
        )
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 5
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: ProcessInfo.processInfo,
            queue: .main
        ) { [weak self] _ in
            self?.updateThermalPolicy(at: Date())
        }
        updateThermalPolicy(at: Date())
    }

    deinit {
        thermalRecoveryWorkItem?.cancel()
        thermalRecoveryScheduler.cancel()
        if let thermalStateObserver {
            NotificationCenter.default.removeObserver(thermalStateObserver)
        }
    }

    private func updateThermalPolicy(at now: Date) {
        let observedLevel = HoguNavigationThermalLevel(ProcessInfo.processInfo.thermalState)
        let effectiveLevel = thermalStateController.receive(observedLevel, at: now)
        HoguNavigationPerformanceMonitor.shared.thermalStateChanged(level: effectiveLevel.rawValue)
        let appliedLevel: HoguNavigationThermalLevel = optimizationFlags[.thermalAdaptation] || effectiveLevel >= .serious
            ? effectiveLevel
            : .nominal
        energyPolicy = HoguNavigationEnergyPolicy.policy(for: appliedLevel)
        guard observedLevel < effectiveLevel,
              let candidate = thermalStateController.recoveryCandidate,
              let deadline = thermalStateController.recoveryDeadline else {
            cancelThermalRecovery()
            return
        }
        guard let generation = thermalRecoveryScheduler.schedule(candidate: candidate, deadline: deadline) else {
            return
        }
        thermalRecoveryWorkItem?.cancel()
        let delay = max(0, deadline.timeIntervalSince(now))
        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  HoguNavigationThermalLevel(ProcessInfo.processInfo.thermalState) == candidate,
                  self.thermalRecoveryScheduler.accepts(generation, candidate: candidate, at: Date()) else {
                return
            }
            let recoveredLevel = self.thermalStateController.advance(at: Date())
            self.thermalRecoveryScheduler.cancel()
            self.thermalRecoveryWorkItem = nil
            let appliedLevel: HoguNavigationThermalLevel = self.optimizationFlags[.thermalAdaptation] || recoveredLevel >= .serious
                ? recoveredLevel
                : .nominal
            self.energyPolicy = HoguNavigationEnergyPolicy.policy(for: appliedLevel)
        }
        thermalRecoveryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelThermalRecovery() {
        thermalRecoveryWorkItem?.cancel()
        thermalRecoveryWorkItem = nil
        thermalRecoveryScheduler.cancel()
    }

    func prepareOnAppear() {
        guard !hasRequestedInitialLocation else { return }
        hasRequestedInitialLocation = true
        requestCurrentLocationAsOrigin(clearRoutePreview: false)
    }

    func focusSearch(target: HoguNavigationInputTarget) {
        searchResponseGate.advance()
        selectedSearchTarget = target
        errorMessage = nil
        activeSearchQuery = ""
        searchCompleter.queryFragment = ""
        searchResults = []
        recentSuggestions = loadRecentSuggestions(for: target)
    }

    func clearSearchSuggestions() {
        searchResponseGate.advance()
        activeSearchQuery = ""
        searchCompleter.queryFragment = ""
        searchResults = []
        recentSuggestions = []
    }

    func updateSearchQuery(_ query: String, target: HoguNavigationInputTarget) {
        clearRouteCalculationResult()
        searchResponseGate.advance()
        selectedSearchTarget = target
        errorMessage = nil

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            activeSearchQuery = ""
            searchResults = []
            recentSuggestions = loadRecentSuggestions(for: target)
            searchCompleter.queryFragment = ""
            return
        }

        activeSearchQuery = trimmedQuery
        recentSuggestions = []
        searchCompleter.queryFragment = trimmedQuery
    }

    func useCurrentLocationAsOrigin() {
        requestCurrentLocationAsOrigin(clearRoutePreview: true)
    }

    private func requestCurrentLocationAsOrigin(clearRoutePreview: Bool) {
        errorMessage = nil
        isResolvingLocation = true
        usesCurrentLocationAsOrigin = true
        if clearRoutePreview {
            clearRouteCalculationResult()
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            isResolvingLocation = false
            errorMessage = "위치 권한을 허용해야 현재 위치를 출발지로 쓸 수 있습니다."
        @unknown default:
            isResolvingLocation = false
            errorMessage = "현재 위치를 확인할 수 없습니다."
        }
    }

    func selectSearchResult(_ result: HoguNavigationSearchResult, target: HoguNavigationInputTarget) {
        errorMessage = nil
        clearSearchSuggestions()
        clearRouteCalculationResult()

        let request = MKLocalSearch.Request(completion: result.completion)
        MKLocalSearch(request: request).start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    Logger.gps.error("[HoguNavigation] 장소 검색 실패: \(error.localizedDescription)")
                    self.errorMessage = "장소를 찾지 못했습니다."
                    return
                }

                guard let mapItem = response?.mapItems.first else {
                    self.errorMessage = "검색 결과가 비어 있습니다."
                    return
                }

                self.apply(mapItem: mapItem, title: result.title, target: target)
                self.saveRecentPlace(
                    mapItem: mapItem,
                    title: result.title,
                    subtitle: result.subtitle,
                    target: target
                )
            }
        }
    }

    func selectRecentSuggestion(_ suggestion: HoguNavigationRecentSuggestion, target: HoguNavigationInputTarget) {
        errorMessage = nil
        clearSearchSuggestions()

        switch suggestion {
        case .place(let place):
            apply(mapItem: place.mapItem, title: place.title, target: target)
            saveRecentPlace(
                mapItem: place.mapItem,
                title: place.title,
                subtitle: place.subtitle,
                target: target
            )
        case .route(let route):
            originText = route.originName
            destinationText = route.destinationName
            originMapItem = route.originMapItem
            destinationMapItem = route.destinationMapItem
            usesCurrentLocationAsOrigin = false
            clearRoutePreviewAndProjectionIndex()
            resetRouteTrackingState()
            saveRecentRoute(route)
            calculateRoute()
        }
    }

    func calculateRoute() {
        errorMessage = nil

        guard let destinationMapItem = destinationMapItem else {
            errorMessage = "목적지를 먼저 선택해 주세요."
            return
        }

        guard let sourceMapItem = originMapItem ?? currentLocationMapItem() else {
            errorMessage = "출발지를 먼저 설정해 주세요."
            return
        }

        activeRouteCalculation?.cancel()
        let calculationGeneration = routeCalculationGate.start()
        isCalculatingRoute = true

        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        activeRouteCalculation = directions
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self,
                      self.routeCalculationGate.accepts(calculationGeneration) else { return }
                self.activeRouteCalculation = nil
                self.isCalculatingRoute = false

                if let error = error {
                    Logger.gps.error("[HoguNavigation] 경로 계산 실패: \(error.localizedDescription)")
                    self.errorMessage = "경로를 계산하지 못했습니다."
                    return
                }

                guard let route = response?.routes.first,
                      let originCoordinate = sourceMapItem.placemark.location?.coordinate,
                      let destinationCoordinate = destinationMapItem.placemark.location?.coordinate else {
                    self.errorMessage = "표시할 경로가 없습니다."
                    return
                }

                let expectedTravelTime = self.normalizedExpectedTravelTime(
                    distance: route.distance,
                    mapKitExpectedTravelTime: route.expectedTravelTime
                )

                let fare = self.fareCalculator.estimateRouteFare(
                    distance: route.distance,
                    expectedTravelTime: expectedTravelTime,
                    at: Date()
                )

                self.routePreview = HoguNavigationRoutePreview(
                    originName: self.originText,
                    destinationName: self.destinationText,
                    distance: route.distance,
                    expectedTravelTime: expectedTravelTime,
                    expectedFare: fare,
                    polyline: route.polyline,
                    originCoordinate: originCoordinate,
                    destinationCoordinate: destinationCoordinate,
                    guidanceSteps: self.routeGuidanceSteps(from: route),
                    segmentDistance: route.distance,
                    segmentExpectedTravelTime: expectedTravelTime,
                    accumulatedDistance: 0,
                    accumulatedExpectedTravelTime: 0
                )
                self.rebuildRouteProjectionIndex()
                self.resetRouteTrackingState()
                self.refreshSpeedCameraCandidates()
                self.saveRecentRoute(
                    originName: self.originText,
                    destinationName: self.destinationText,
                    originCoordinate: originCoordinate,
                    destinationCoordinate: destinationCoordinate
                )
                HapticManager.medium()
            }
        }
    }

    func startNavigationFromPreview() {
        isNavigationStarted = true
        _ = locationSessionGate.start()
        resetRouteTrackingState()
        hasUsableCourse = false
        if optimizationFlags[.sharedLocationSession] {
            sharedLocationSubscription.start()
        } else {
            locationManager.startUpdatingLocation()
        }
        NotificationCenter.default.post(name: .hoguNavigationDidStart, object: nil)
        Task {
            await loadSpeedCamerasIfNeeded()
            await MainActor.run {
                self.updateSpeedCameraWarning()
            }
        }
    }

    func stopNavigation() {
        locationSessionGate.stop()
        isNavigationStarted = false
        isRerouting = false
        sharedLocationSubscription.stop()
        locationManager.stopUpdatingLocation()
        speedCameraWarning = nil
        upcomingRouteInstruction = nil
        upcomingRouteInstructionDistance = nil
        upcomingRouteManeuver = nil
        navigationStatusMessage = nil
        speedCameraCandidates = []
        projectedSpeedCameraCandidates = []
        _ = speedCameraPrecomputeGate.invalidate()
        lastWarnedCameraId = nil
        hasUsableCourse = false
        navigationFrame = nil
        resetRouteTrackingState()
        NotificationCenter.default.post(name: .hoguNavigationDidStop, object: nil)
    }

    func resetRouteCalculationResult() {
        guard !isNavigationStarted else { return }
        clearRouteCalculationResult()
    }

    private func apply(mapItem: MKMapItem, title: String, target: HoguNavigationInputTarget) {
        switch target {
        case .origin:
            originText = title
            originMapItem = mapItem
            usesCurrentLocationAsOrigin = false
        case .destination:
            destinationText = title
            destinationMapItem = mapItem
        }

        clearRoutePreviewAndProjectionIndex()
        resetRouteTrackingState()
    }

    private func resetRouteTrackingState(clearRerouteCooldown: Bool = true) {
        routeDeviationCandidateCount = 0
        lastRouteProgressDistance = nil
        if clearRerouteCooldown {
            lastRerouteAt = nil
        }
    }

    private func rebuildRouteProjectionIndex() {
        guard let routePreview else {
            routeProjectionIndex = nil
            navigationFrame = nil
            return
        }
        routeProjectionIndex = optimizationFlags[.routeIndex]
            ? RouteProjectionIndex(coordinates: routePreview.polyline.coordinates)
            : nil
        navigationFrame = nil
        _ = speedCameraPrecomputeGate.invalidate()
        projectedSpeedCameraCandidates = []
        speedCameraRouteGeneration += 1
        speedCameraWarning = nil
        lastWarnedCameraId = nil
    }

    private func clearRoutePreviewAndProjectionIndex() {
        invalidateRouteCalculation()
        routePreview = nil
        routeProjectionIndex = nil
        navigationFrame = nil
        speedCameraWarning = nil
        upcomingRouteInstruction = nil
        upcomingRouteInstructionDistance = nil
        upcomingRouteManeuver = nil
        navigationStatusMessage = nil
        speedCameraCandidates = []
        _ = speedCameraPrecomputeGate.invalidate()
        projectedSpeedCameraCandidates = []
        lastWarnedCameraId = nil
        speedCameraRouteGeneration += 1
    }

    private func clearRouteCalculationResult() {
        clearRoutePreviewAndProjectionIndex()
        resetRouteTrackingState()
    }

    private func invalidateRouteCalculation() {
        activeRouteCalculation?.cancel()
        activeRouteCalculation = nil
        routeCalculationGate.invalidate()
        isCalculatingRoute = false
    }

    private func currentLocationMapItem() -> MKMapItem? {
        guard let currentLocation = currentLocation else { return nil }
        let placemark = MKPlacemark(coordinate: currentLocation.coordinate)
        return MKMapItem(placemark: placemark)
    }

    private func loadRecentSuggestions(for target: HoguNavigationInputTarget) -> [HoguNavigationRecentSuggestion] {
        let routes = loadRecentRoutes()
            .map(HoguNavigationRecentSuggestion.route)
        let places = loadRecentPlaces()
            .map(HoguNavigationRecentSuggestion.place)

        return (routes + places)
            .sorted { lhs, rhs in
                recentUpdatedAt(lhs) > recentUpdatedAt(rhs)
            }
            .prefix(5)
            .map { $0 }
    }

    private func recentUpdatedAt(_ suggestion: HoguNavigationRecentSuggestion) -> Date {
        switch suggestion {
        case .route(let route):
            return route.updatedAt
        case .place(let place):
            return place.updatedAt
        }
    }

    private func saveRecentPlace(
        mapItem: MKMapItem,
        title: String,
        subtitle: String,
        target: HoguNavigationInputTarget
    ) {
        guard let coordinate = mapItem.placemark.location?.coordinate else { return }

        let place = HoguNavigationRecentPlace(
            title: title,
            subtitle: subtitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            target: target,
            updatedAt: Date()
        )

        var places = loadRecentPlaces()
        places.removeAll { $0.id == place.id }
        places.insert(place, at: 0)
        saveRecentPlaces(Array(places.prefix(20)))
    }

    private func saveRecentRoute(
        originName: String,
        destinationName: String,
        originCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D
    ) {
        let route = HoguNavigationRecentRoute(
            originName: originName,
            destinationName: destinationName,
            originLatitude: originCoordinate.latitude,
            originLongitude: originCoordinate.longitude,
            destinationLatitude: destinationCoordinate.latitude,
            destinationLongitude: destinationCoordinate.longitude,
            updatedAt: Date()
        )
        saveRecentRoute(route)
    }

    private func saveRecentRoute(_ route: HoguNavigationRecentRoute) {
        let updatedRoute = HoguNavigationRecentRoute(
            originName: route.originName,
            destinationName: route.destinationName,
            originLatitude: route.originLatitude,
            originLongitude: route.originLongitude,
            destinationLatitude: route.destinationLatitude,
            destinationLongitude: route.destinationLongitude,
            updatedAt: Date()
        )

        var routes = loadRecentRoutes()
        routes.removeAll { $0.id == updatedRoute.id }
        routes.insert(updatedRoute, at: 0)
        saveRecentRoutes(Array(routes.prefix(20)))
    }

    private func loadRecentPlaces() -> [HoguNavigationRecentPlace] {
        guard let data = userDefaults.data(forKey: recentPlacesKey) else { return [] }

        do {
            return try JSONDecoder().decode([HoguNavigationRecentPlace].self, from: data)
        } catch {
            Logger.gps.error("[HoguNavigation] 최근 장소 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }

    private func saveRecentPlaces(_ places: [HoguNavigationRecentPlace]) {
        do {
            let data = try JSONEncoder().encode(places)
            userDefaults.set(data, forKey: recentPlacesKey)
        } catch {
            Logger.gps.error("[HoguNavigation] 최근 장소 저장 실패: \(error.localizedDescription)")
        }
    }

    private func loadRecentRoutes() -> [HoguNavigationRecentRoute] {
        guard let data = userDefaults.data(forKey: recentRoutesKey) else { return [] }

        do {
            return try JSONDecoder().decode([HoguNavigationRecentRoute].self, from: data)
        } catch {
            Logger.gps.error("[HoguNavigation] 최근 경로 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }

    private func saveRecentRoutes(_ routes: [HoguNavigationRecentRoute]) {
        do {
            let data = try JSONEncoder().encode(routes)
            userDefaults.set(data, forKey: recentRoutesKey)
        } catch {
            Logger.gps.error("[HoguNavigation] 최근 경로 저장 실패: \(error.localizedDescription)")
        }
    }
}

extension HoguNavigationViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // MKLocalSearchCompleter는 결과별 request ID를 제공하지 않으므로 callback 시점의
        // queryFragment를 token화한다. 이후 query/target 변경은 generation으로 차단한다.
        let callbackQuery = completer.queryFragment.trimmingCharacters(in: .whitespacesAndNewlines)
        let callbackTarget = selectedSearchTarget
        let callbackToken = searchResponseGate.capture(query: callbackQuery, target: callbackTarget)
        let callbackResults = completer.results
        DispatchQueue.main.async {
            guard !callbackQuery.isEmpty,
                  self.searchResponseGate.accepts(
                    callbackToken,
                    activeQuery: self.activeSearchQuery,
                    selectedTarget: self.selectedSearchTarget
                  ) else { return }
            let visibleCompletions = HoguNavigationSearchResultPolicy.visibleResults(
                callbackResults,
                title: { $0.title },
                subtitle: { $0.subtitle }
            )
            self.searchResults = visibleCompletions.map(HoguNavigationSearchResult.init)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        let callbackQuery = completer.queryFragment.trimmingCharacters(in: .whitespacesAndNewlines)
        let callbackTarget = selectedSearchTarget
        let callbackToken = searchResponseGate.capture(query: callbackQuery, target: callbackTarget)
        let callbackErrorCode = (error as? MKError)?.code
        let callbackErrorDescription = error.localizedDescription
        DispatchQueue.main.async {
            guard !callbackQuery.isEmpty,
                  self.searchResponseGate.accepts(
                    callbackToken,
                    activeQuery: self.activeSearchQuery,
                    selectedTarget: self.selectedSearchTarget
                  ) else { return }

            if !self.searchResults.isEmpty {
                return
            }

            if callbackErrorCode == .directionsNotFound {
                return
            }

            Logger.gps.error("[HoguNavigation] 검색 자동완성 실패: \(callbackErrorDescription)")
            self.searchResults = []
            self.errorMessage = "검색 결과를 불러오지 못했습니다."
        }
    }
}

extension HoguNavigationViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isResolvingLocation = false
                self.errorMessage = "위치 권한을 허용해야 현재 위치를 출발지로 쓸 수 있습니다."
            }
        case .notDetermined:
            break
        @unknown default:
            DispatchQueue.main.async {
                self.isResolvingLocation = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isNavigationStarted || !optimizationFlags[.sharedLocationSession] else { return }
        guard let location = preferredLocation(from: locations) else {
            DispatchQueue.main.async {
                self.isResolvingLocation = false
                if !self.isNavigationStarted {
                    self.errorMessage = "현재 위치 정확도가 낮습니다. 잠시 후 다시 시도해 주세요."
                }
            }
            return
        }

        let generation = locationSessionGate.generation
        DispatchQueue.main.async {
            guard self.locationSessionGate.acceptsOneShot(
                capturedGeneration: generation,
                isNavigationStarted: self.isNavigationStarted
            ) else { return }
            self.handleLocation(location)
        }
    }

    private func handleLocation(_ location: CLLocation) {
        let locationSpan = HoguNavigationPerformanceMonitor.shared.begin(.locationCallback)
        defer { HoguNavigationPerformanceMonitor.shared.end(.locationCallback, id: locationSpan) }
        currentLocation = location
        userCoordinate = location.coordinate
        let locationHeading = heading(from: location)
        userHeading = locationHeading
        hasUsableCourse = location.course >= 0 && location.speed > 1.4
        userSpeed = max(0, location.speed * 3.6)

        let projectionSpan = HoguNavigationPerformanceMonitor.shared.begin(.routeProjection)
        let projection: HoguNavigationRouteProjection?
        var didProjectRoute = false
        if isNavigationStarted, let routeProjectionIndex {
            projection = routeProjectionIndex.project(location)
            didProjectRoute = true
        } else if isNavigationStarted, let routePreview {
            projection = HoguNavigationRouteProjector.project(
                coordinate: location.coordinate,
                onto: routePreview.polyline.coordinates
            )
            didProjectRoute = true
        } else {
            projection = nil
        }
        HoguNavigationPerformanceMonitor.shared.end(.routeProjection, id: projectionSpan)
        if didProjectRoute {
            HoguNavigationPerformanceMonitor.shared.event("projectorCalls")
            HoguNavigationPerformanceMonitor.shared.event("routeSegments", count: routeProjectionIndex?.segmentDistances.count ?? 0)
        }
        navigationFrame = projection.map {
            HoguNavigationFrame(
                location: location,
                projection: $0,
                displayHeading: hasUsableCourse ? locationHeading : $0.heading
            )
        }

        if !isNavigationStarted && usesCurrentLocationAsOrigin {
            originMapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            originText = "현재 위치"
        } else {
            handleRouteDeviationIfNeeded(from: location, projection: projection)
            let guidanceSpan = HoguNavigationPerformanceMonitor.shared.begin(.guidance)
            updateRouteGuidance(from: location, projection: projection)
            HoguNavigationPerformanceMonitor.shared.end(.guidance, id: guidanceSpan)
            let cameraSpan = HoguNavigationPerformanceMonitor.shared.begin(.speedCamera)
            updateSpeedCameraWarning(using: navigationFrame)
            HoguNavigationPerformanceMonitor.shared.end(.speedCamera, id: cameraSpan)
        }
        isResolvingLocation = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            Logger.gps.error("[HoguNavigation] 현재 위치 확인 실패: \(error.localizedDescription)")
            self.isResolvingLocation = false
            self.errorMessage = "현재 위치를 확인하지 못했습니다."
        }
    }

    private func heading(from location: CLLocation) -> CLLocationDirection {
        if location.course >= 0,
           location.speed > 1.4 {
            return location.course
        }

        return userHeading
    }

    private func preferredLocation(from locations: [CLLocation]) -> CLLocation? {
        let now = Date()
        let candidates = locations.filter {
            $0.horizontalAccuracy >= 0
                && now.timeIntervalSince($0.timestamp) <= maximumLocationAge
                && $0.horizontalAccuracy <= maximumHorizontalAccuracy
        }

        if let latestCandidate = candidates.max(by: { $0.timestamp < $1.timestamp }) {
            return latestCandidate
        }

        guard currentLocation == nil else { return nil }

        return locations
            .filter {
                $0.horizontalAccuracy >= 0
                    && now.timeIntervalSince($0.timestamp) <= maximumLocationAge * 3
            }
            .max { $0.timestamp < $1.timestamp }
    }

    private func handleRouteDeviationIfNeeded(
        from location: CLLocation,
        projection: HoguNavigationRouteProjection?
    ) {
        guard isNavigationStarted,
              usesCurrentLocationAsOrigin,
              !isRerouting,
              routePreview != nil,
              let destinationMapItem = destinationMapItem else {
            return
        }

        guard let projection else {
            routeDeviationCandidateCount = 0
            return
        }

        guard location.horizontalAccuracy <= routeDeviationAccuracyLimit,
              projection.distanceToRoute > routeDeviationThreshold else {
            routeDeviationCandidateCount = 0
            return
        }

        if location.speed >= highSpeedDeviationHoldSpeed,
           projection.distanceToRoute <= highSpeedDeviationHoldDistance {
            routeDeviationCandidateCount = 0
            return
        }

        routeDeviationCandidateCount += 1
        guard routeDeviationCandidateCount >= routeDeviationConfirmationCount else {
            return
        }

        let now = Date()
        if let lastRerouteAt, now.timeIntervalSince(lastRerouteAt) < rerouteMinimumInterval {
            return
        }

        routeDeviationCandidateCount = 0
        lastRerouteAt = now
        rerouteFromCurrentLocation(location, destinationMapItem: destinationMapItem)
    }

    private func rerouteFromCurrentLocation(_ location: CLLocation, destinationMapItem: MKMapItem) {
        isRerouting = true
        navigationStatusMessage = "경로를 이탈했습니다. 경로를 다시 설정합니다."

        let sourceMapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        MKDirections(request: request).calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRerouting = false

                if let error = error {
                    Logger.gps.error("[HoguNavigation] 경로 재설정 실패: \(error.localizedDescription)")
                    self.navigationStatusMessage = "경로를 다시 설정하지 못했습니다."
                    self.hideNavigationStatusMessageAfterDelay()
                    return
                }

                guard let route = response?.routes.first,
                      let destinationCoordinate = destinationMapItem.placemark.location?.coordinate else {
                    self.navigationStatusMessage = "경로를 다시 설정하지 못했습니다."
                    self.hideNavigationStatusMessageAfterDelay()
                    return
                }

                let expectedTravelTime = self.normalizedExpectedTravelTime(
                    distance: route.distance,
                    mapKitExpectedTravelTime: route.expectedTravelTime
                )

                let previousPreview = self.routePreview
                let progressedDistance = min(
                    max(self.lastRouteProgressDistance ?? 0, 0),
                    previousPreview?.segmentDistance ?? 0
                )
                let progressedExpectedTravelTime = (previousPreview?.segmentExpectedTravelTime ?? 0)
                    * (progressedDistance / max(previousPreview?.segmentDistance ?? 1, 1))
                let totalAccumulatedDistance = (previousPreview?.accumulatedDistance ?? 0) + progressedDistance
                let totalAccumulatedExpectedTravelTime = (previousPreview?.accumulatedExpectedTravelTime ?? 0)
                    + progressedExpectedTravelTime

                self.routePreview = HoguNavigationRoutePreview(
                    originName: "현재 위치",
                    destinationName: self.destinationText,
                    distance: route.distance,
                    expectedTravelTime: expectedTravelTime,
                    expectedFare: self.fareCalculator.estimateRouteFare(
                        distance: totalAccumulatedDistance + route.distance,
                        expectedTravelTime: totalAccumulatedExpectedTravelTime + expectedTravelTime,
                        at: Date()
                    ),
                    polyline: route.polyline,
                    originCoordinate: location.coordinate,
                    destinationCoordinate: destinationCoordinate,
                    guidanceSteps: self.routeGuidanceSteps(from: route),
                    segmentDistance: route.distance,
                    segmentExpectedTravelTime: expectedTravelTime,
                    accumulatedDistance: totalAccumulatedDistance,
                    accumulatedExpectedTravelTime: totalAccumulatedExpectedTravelTime
                )
                self.rebuildRouteProjectionIndex()
                self.resetRouteTrackingState(clearRerouteCooldown: false)
                self.originText = "현재 위치"
                self.originMapItem = sourceMapItem
                self.usesCurrentLocationAsOrigin = true
                self.refreshSpeedCameraCandidates()
                self.navigationStatusMessage = "새 경로로 다시 설정했습니다."
                self.hideNavigationStatusMessageAfterDelay()
                Task {
                    await self.loadSpeedCamerasIfNeeded()
                }
            }
        }
    }

    private func hideNavigationStatusMessageAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self, !self.isRerouting else { return }
            self.navigationStatusMessage = nil
        }
    }

    private func routeGuidanceSteps(from route: MKRoute) -> [HoguNavigationRouteStep] {
        var distanceFromStart: CLLocationDistance = 0
        var steps: [HoguNavigationRouteStep] = []
        var previousEndHeading: CLLocationDirection?

        for step in route.steps {
            let instruction = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            let coordinates = step.polyline.coordinates
            if !instruction.isEmpty {
                let guidance = HoguNavigationManeuverResolver.guidance(
                    instruction: instruction,
                    inboundHeading: previousEndHeading,
                    outboundHeading: HoguNavigationStepBoundaryResolver.heading(in: coordinates, fromStart: true)
                )
                steps.append(
                    HoguNavigationRouteStep(
                        instruction: guidance.text,
                        startDistance: distanceFromStart,
                        distance: step.distance,
                        maneuver: guidance.maneuver
                    )
                )
            }
            previousEndHeading = HoguNavigationStepBoundaryResolver.heading(in: coordinates, fromStart: false) ?? previousEndHeading
            distanceFromStart += step.distance
        }

        return steps
    }

    private func normalizedExpectedTravelTime(
        distance: CLLocationDistance,
        mapKitExpectedTravelTime: TimeInterval
    ) -> TimeInterval {
        guard distance > 0 else {
            return max(mapKitExpectedTravelTime, minimumRoutePreviewDuration)
        }

        let maximumAverageSpeed = maximumPreviewAverageSpeedKPH(for: distance)
        let minimumPlausibleTravelTime = distance / (maximumAverageSpeed / 3.6)

        return max(
            mapKitExpectedTravelTime,
            minimumPlausibleTravelTime,
            minimumRoutePreviewDuration
        )
    }

    private func maximumPreviewAverageSpeedKPH(for distance: CLLocationDistance) -> Double {
        switch distance {
        case ..<5_000:
            return 22
        case ..<20_000:
            return 30
        case ..<40_000:
            return 38
        default:
            return 55
        }
    }

    private func updateRouteGuidance(
        from location: CLLocation,
        projection: HoguNavigationRouteProjection?
    ) {
        guard let routePreview = routePreview,
              let projection,
              projection.distanceToRoute <= guidanceSnapDistanceLimit else {
            return
        }

        let normalizedProgressDistance = normalizedRouteProgressDistance(
            projection.progressDistance,
            speedMetersPerSecond: max(location.speed, 0)
        )
        updateRoutePreviewProgress(normalizedProgressDistance)

        guard let nextStep = HoguNavigationGuidanceSelector.nextStep(
            in: routePreview.guidanceSteps,
            progressDistance: normalizedProgressDistance
        ) else {
            upcomingRouteInstruction = nil
            upcomingRouteInstructionDistance = nil
            upcomingRouteManeuver = nil
            return
        }

        upcomingRouteInstruction = nextStep.instruction
        upcomingRouteInstructionDistance = max(0, nextStep.startDistance - normalizedProgressDistance)
        upcomingRouteManeuver = nextStep.maneuver
    }

    /// 지도상의 현재 구간과 이미 이동한 구간을 합쳐, 안내 중 요약값을 매 위치 갱신한다.
    /// 재탐색 시에도 accumulated 값이 새 구간의 남은 값에 더해지므로 비용이 사라지지 않는다.
    private func updateRoutePreviewProgress(_ progressDistance: CLLocationDistance) {
        guard let preview = routePreview, preview.segmentDistance > 0 else { return }

        let clampedProgress = min(max(progressDistance, 0), preview.segmentDistance)
        let remainingDistance = max(0, preview.segmentDistance - clampedProgress)
        let remainingExpectedTravelTime = preview.segmentExpectedTravelTime
            * (remainingDistance / preview.segmentDistance)
        let totalExpectedDistance = preview.accumulatedDistance + remainingDistance
        let totalExpectedTravelTime = preview.accumulatedExpectedTravelTime + remainingExpectedTravelTime
        let expectedFare: Int
        if clampedProgress < 5, preview.accumulatedDistance == 0 {
            expectedFare = preview.expectedFare
        } else {
            expectedFare = fareCalculator.estimateRouteFare(
                distance: totalExpectedDistance,
                expectedTravelTime: totalExpectedTravelTime,
                at: Date()
            )
        }

        routePreview = HoguNavigationRoutePreview(
            originName: preview.originName,
            destinationName: preview.destinationName,
            distance: remainingDistance,
            expectedTravelTime: totalExpectedTravelTime,
            expectedFare: expectedFare,
            polyline: preview.polyline,
            originCoordinate: preview.originCoordinate,
            destinationCoordinate: preview.destinationCoordinate,
            guidanceSteps: preview.guidanceSteps,
            segmentDistance: preview.segmentDistance,
            segmentExpectedTravelTime: preview.segmentExpectedTravelTime,
            accumulatedDistance: preview.accumulatedDistance,
            accumulatedExpectedTravelTime: preview.accumulatedExpectedTravelTime
        )
    }

    private func normalizedRouteProgressDistance(
        _ progressDistance: CLLocationDistance,
        speedMetersPerSecond: CLLocationSpeed
    ) -> CLLocationDistance {
        guard let previousProgressDistance = lastRouteProgressDistance else {
            self.lastRouteProgressDistance = progressDistance
            return progressDistance
        }

        if progressDistance < previousProgressDistance - 30 {
            return previousProgressDistance
        }

        let maximumForwardJump = max(80, speedMetersPerSecond * 8)
        if progressDistance > previousProgressDistance + maximumForwardJump {
            return previousProgressDistance
        }

        self.lastRouteProgressDistance = max(previousProgressDistance, progressDistance)
        return self.lastRouteProgressDistance ?? progressDistance
    }

    private func bearing(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDirection {
        let sourceLatitude = source.latitude * .pi / 180
        let sourceLongitude = source.longitude * .pi / 180
        let destinationLatitude = destination.latitude * .pi / 180
        let destinationLongitude = destination.longitude * .pi / 180
        let longitudeDelta = destinationLongitude - sourceLongitude

        let y = sin(longitudeDelta) * cos(destinationLatitude)
        let x = cos(sourceLatitude) * sin(destinationLatitude)
            - sin(sourceLatitude) * cos(destinationLatitude) * cos(longitudeDelta)
        let degrees = atan2(y, x) * 180 / .pi
        return degrees >= 0 ? degrees : degrees + 360
    }

    private func loadSpeedCamerasIfNeeded() async {
        let routeCoordinates = await MainActor.run {
            self.routePreview?.polyline.coordinates ?? []
        }
        let regions = await resolveSpeedCameraRegions(from: routeCoordinates)
        let regionKeys = Set(regions.map(\.cacheKey))
        let routeGeneration = await MainActor.run { self.speedCameraRouteGeneration }
        let hasPendingRetry = await speedCameraAPIClient.hasPendingRetry(regions: regions)
        await MainActor.run {
            guard HoguNavigationSpeedCameraRegionTransition.requiresImmediateClear(
                currentRegionKeys: self.currentSpeedCameraRegionKeys,
                nextRegionKeys: regionKeys
            ) else {
                return
            }
            self.speedCameraWarning = nil
            self.lastWarnedCameraId = nil
            self.speedCameraCandidates = []
            self.projectedSpeedCameraCandidates = []
            _ = self.speedCameraPrecomputeGate.invalidate()
        }
        let canReuse = await MainActor.run {
            !self.speedCameras.isEmpty && self.currentSpeedCameraRegionKeys == regionKeys && !hasPendingRetry
        }
        guard !canReuse else { return }
        let cameras: [SpeedCamera]
        if regions.isEmpty {
            cameras = await speedCameraAPIClient.fetchCameras()
        } else {
            cameras = await speedCameraAPIClient.fetchCameras(regions: regions)
        }
        await MainActor.run {
            guard self.speedCameraRouteGeneration == routeGeneration else { return }
            self.speedCameras = cameras
            self.currentSpeedCameraRegionKeys = regionKeys
            self.refreshSpeedCameraCandidates()
            self.updateSpeedCameraWarning()
        }
    }

    private func resolveSpeedCameraRegions(from routeCoordinates: [CLLocationCoordinate2D]) async -> [SpeedCameraRegionFilter] {
        let samples = routeSampleCoordinates(routeCoordinates)
        var regions: [SpeedCameraRegionFilter] = []

        for coordinate in samples {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(
                    CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                )

                guard let placemark = placemarks.first,
                      let sido = normalizedRegionName(placemark.administrativeArea) else {
                    continue
                }

                let sigungu = [
                    placemark.locality,
                    placemark.subAdministrativeArea,
                    placemark.subLocality
                ]
                    .compactMap(normalizedRegionName)
                    .first { $0 != sido }
                regions.append(SpeedCameraRegionFilter(sido: sido, sigungu: sigungu))
            } catch {
                continue
            }
        }

        return Array(Set(regions))
    }

    private func routeSampleCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        HoguNavigationRouteSampleSelector.representativeCoordinates(from: coordinates, maximumCount: 3)
    }

    private func normalizedRegionName(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private func refreshSpeedCameraCandidates() {
        let precomputeGeneration = speedCameraPrecomputeGate.invalidate()
        guard let routePreview = routePreview, !speedCameras.isEmpty else {
            speedCameraCandidates = []
            projectedSpeedCameraCandidates = []
            return
        }

        let coordinates = routePreview.polyline.coordinates
        guard !coordinates.isEmpty else {
            speedCameraCandidates = speedCameras
            projectedSpeedCameraCandidates = []
            return
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let margin = 0.03
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max() else {
            speedCameraCandidates = []
            projectedSpeedCameraCandidates = []
            return
        }

        let candidates = speedCameras.filter { camera in
            let coordinate = camera.coordinate
            return coordinate.latitude >= minLatitude - margin
                && coordinate.latitude <= maxLatitude + margin
                && coordinate.longitude >= minLongitude - margin
                && coordinate.longitude <= maxLongitude + margin
        }
        speedCameraCandidates = candidates
        projectedSpeedCameraCandidates = []

        // 경로 또는 카메라 목록이 바뀔 때만 별도 index로 camera progress를 계산한다.
        // 주행 GPS callback이 쓰는 routeProjectionIndex는 이 작업에서 호출하지 않는다.
        let precomputeIndex = RouteProjectionIndex(coordinates: coordinates)
        guard optimizationFlags[.cameraIndex] else {
            projectedSpeedCameraCandidates = HoguNavigationSpeedCameraRouteIndexer.project(
                cameras: candidates,
                using: precomputeIndex
            )
            updateSpeedCameraWarning(using: navigationFrame)
            return
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let projected = HoguNavigationSpeedCameraRouteIndexer.project(
                cameras: candidates,
                using: precomputeIndex
            )

            DispatchQueue.main.async {
                guard let self,
                      self.speedCameraPrecomputeGate.accepts(precomputeGeneration) else {
                    return
                }
                self.projectedSpeedCameraCandidates = projected
                self.updateSpeedCameraWarning(using: self.navigationFrame)
            }
        }
    }

    private func updateSpeedCameraWarning(using frame: HoguNavigationFrame? = nil) {
        guard isNavigationStarted,
              let frame = frame ?? navigationFrame else {
            speedCameraWarning = nil
            return
        }

        let candidateCameras = HoguNavigationSpeedCameraCandidateSelector.upcoming(
            in: projectedSpeedCameraCandidates,
            after: frame.projection.progressDistance
        )
        HoguNavigationPerformanceMonitor.shared.event("cameraEvaluated", count: candidateCameras.count)
        let upcoming = candidateCameras
            .compactMap { projectedCamera -> SpeedCameraWarning? in
                let camera = projectedCamera.camera
                let userLocation = frame.location
                let cameraLocation = CLLocation(
                    latitude: camera.coordinate.latitude,
                    longitude: camera.coordinate.longitude
                )
                let directDistance = userLocation.distance(from: cameraLocation)
                let aheadDistance = projectedCamera.progressDistance - frame.projection.progressDistance
                guard aheadDistance <= 600 else { return nil }

                let cameraBearing = bearing(from: frame.location.coordinate, to: camera.coordinate)
                guard angleDifference(frame.displayHeading, cameraBearing) <= 45 else { return nil }
                guard directDistance <= 700 else { return nil }

                return SpeedCameraWarning(
                    camera: camera,
                    distanceM: aheadDistance,
                    currentSpeedKmh: userSpeed
                )
            }
            .sorted { $0.distanceM < $1.distanceM }
            .first

        if let upcoming, upcoming.camera.id != lastWarnedCameraId {
            HapticManager.warning()
            lastWarnedCameraId = upcoming.camera.id
        }

        speedCameraWarning = upcoming
    }

    private func angleDifference(_ lhs: CLLocationDirection, _ rhs: CLLocationDirection) -> CLLocationDirection {
        let difference = abs(lhs - rhs).truncatingRemainder(dividingBy: 360)
        return difference > 180 ? 360 - difference : difference
    }

}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: pointCount
        )
        getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }
}
