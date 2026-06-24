//
//  HoguNavigationViewModel.swift
//  HoguMeter
//
//  Created on 2026-06-23.
//

import Foundation
import CoreLocation
import MapKit

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
}

struct HoguNavigationRouteStep {
    let instruction: String
    let startDistance: CLLocationDistance
    let distance: CLLocationDistance
}

final class HoguNavigationViewModel: NSObject, ObservableObject {

    @Published var originText: String = "현재 위치"
    @Published var destinationText: String = ""
    @Published var searchResults: [HoguNavigationSearchResult] = []
    @Published var recentSuggestions: [HoguNavigationRecentSuggestion] = []
    @Published var selectedSearchTarget: HoguNavigationInputTarget = .destination
    @Published var routePreview: HoguNavigationRoutePreview?
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var userHeading: CLLocationDirection = 0
    @Published var userSpeed: Double = 0
    @Published var speedCameraWarning: SpeedCameraWarning?
    @Published var isResolvingLocation: Bool = false
    @Published var isCalculatingRoute: Bool = false
    @Published var isNavigationStarted: Bool = false
    @Published var isRerouting: Bool = false
    @Published var navigationStatusMessage: String?
    @Published var upcomingRouteInstruction: String?
    @Published var upcomingRouteInstructionDistance: CLLocationDistance?
    @Published var errorMessage: String?

    private let searchCompleter = MKLocalSearchCompleter()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let fareCalculator: FareCalculator
    private let speedCameraAPIClient = SpeedCameraAPIClient()
    private let userDefaults: UserDefaults
    private let recentPlacesKey = "hoguNavigationRecentPlacesV1"
    private let recentRoutesKey = "hoguNavigationRecentRoutesV1"
    private var speedCameras: [SpeedCamera] = []
    private var speedCameraCandidates: [SpeedCamera] = []
    private var lastWarnedCameraId: String?
    private var originMapItem: MKMapItem?
    private var destinationMapItem: MKMapItem?
    private var currentLocation: CLLocation?
    private var activeSearchQuery: String = ""
    private var hasRequestedInitialLocation = false
    private var usesCurrentLocationAsOrigin = true
    private var lastRerouteAt: Date?
    private let routeDeviationThreshold: CLLocationDistance = 90
    private let rerouteMinimumInterval: TimeInterval = 20
    private let maximumLocationAge: TimeInterval = 12
    private let maximumHorizontalAccuracy: CLLocationAccuracy = 80
    private let minimumRoutePreviewDuration: TimeInterval = 60

    var hasSearchListItems: Bool {
        !recentSuggestions.isEmpty || !searchResults.isEmpty
    }

    init(fareCalculator: FareCalculator, userDefaults: UserDefaults = .standard) {
        self.fareCalculator = fareCalculator
        self.userDefaults = userDefaults
        super.init()
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
    }

    func prepareOnAppear() {
        guard !hasRequestedInitialLocation else { return }
        hasRequestedInitialLocation = true
        requestCurrentLocationAsOrigin(clearRoutePreview: false)
    }

    func focusSearch(target: HoguNavigationInputTarget) {
        selectedSearchTarget = target
        errorMessage = nil
        activeSearchQuery = ""
        searchCompleter.queryFragment = ""
        searchResults = []
        recentSuggestions = loadRecentSuggestions(for: target)
    }

    func clearSearchSuggestions() {
        activeSearchQuery = ""
        searchCompleter.queryFragment = ""
        searchResults = []
        recentSuggestions = []
    }

    func updateSearchQuery(_ query: String, target: HoguNavigationInputTarget) {
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
        requestCurrentLocationAsOrigin(clearRoutePreview: false)
    }

    private func requestCurrentLocationAsOrigin(clearRoutePreview: Bool) {
        errorMessage = nil
        isResolvingLocation = true
        usesCurrentLocationAsOrigin = true
        if clearRoutePreview {
            routePreview = nil
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
        searchResults = []
        recentSuggestions = []

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

    func selectRecentSuggestion(_ suggestion: HoguNavigationRecentSuggestion) {
        errorMessage = nil
        clearSearchSuggestions()

        switch suggestion {
        case .place(let place):
            apply(mapItem: place.mapItem, title: place.title, target: place.target)
            saveRecentPlace(
                mapItem: place.mapItem,
                title: place.title,
                subtitle: place.subtitle,
                target: place.target
            )
        case .route(let route):
            originText = route.originName
            destinationText = route.destinationName
            originMapItem = route.originMapItem
            destinationMapItem = route.destinationMapItem
            routePreview = nil
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

        isCalculatingRoute = true

        let request = MKDirections.Request()
        request.source = sourceMapItem
        request.destination = destinationMapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        MKDirections(request: request).calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
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
                    guidanceSteps: self.routeGuidanceSteps(from: route)
                )
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
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        NotificationCenter.default.post(name: .hoguNavigationDidStart, object: nil)
        Task {
            await loadSpeedCamerasIfNeeded()
            await MainActor.run {
                self.updateSpeedCameraWarning()
            }
        }
    }

    func stopNavigation() {
        isNavigationStarted = false
        isRerouting = false
        locationManager.distanceFilter = 5
        locationManager.stopUpdatingLocation()
        speedCameraWarning = nil
        upcomingRouteInstruction = nil
        upcomingRouteInstructionDistance = nil
        navigationStatusMessage = nil
        speedCameraCandidates = []
        lastWarnedCameraId = nil
        NotificationCenter.default.post(name: .hoguNavigationDidStop, object: nil)
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

        routePreview = nil
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
            .filter { $0.target == target }
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
        DispatchQueue.main.async {
            guard !self.activeSearchQuery.isEmpty else {
                self.searchResults = []
                return
            }
            self.searchResults = completer.results.map(HoguNavigationSearchResult.init)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            guard !self.activeSearchQuery.isEmpty else { return }

            if !self.searchResults.isEmpty {
                return
            }

            if let mapError = error as? MKError, mapError.code == .directionsNotFound {
                return
            }

            Logger.gps.error("[HoguNavigation] 검색 자동완성 실패: \(error.localizedDescription)")
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
        guard let location = preferredLocation(from: locations) else {
            DispatchQueue.main.async {
                self.isResolvingLocation = false
                if !self.isNavigationStarted {
                    self.errorMessage = "현재 위치 정확도가 낮습니다. 잠시 후 다시 시도해 주세요."
                }
            }
            return
        }

        DispatchQueue.main.async {
            self.currentLocation = location
            self.userCoordinate = location.coordinate
            self.userHeading = self.heading(from: location)
            self.userSpeed = max(0, location.speed * 3.6)
            if !self.isNavigationStarted && self.usesCurrentLocationAsOrigin {
                self.originMapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                self.originText = "현재 위치"
            } else {
                self.handleRouteDeviationIfNeeded(from: location)
                self.updateRouteGuidance(from: location)
                self.updateSpeedCameraWarning()
            }
            self.isResolvingLocation = false
            HapticManager.light()
        }
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

        guard let destinationCoordinate = routePreview?.destinationCoordinate else {
            return userHeading
        }

        return bearing(from: location.coordinate, to: destinationCoordinate)
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

    private func handleRouteDeviationIfNeeded(from location: CLLocation) {
        guard isNavigationStarted,
              !isRerouting,
              let routePreview = routePreview,
              let destinationMapItem = destinationMapItem else {
            return
        }

        let routeCoordinates = routePreview.polyline.coordinates
        guard let nearestDistance = nearestRouteDistance(
            to: location.coordinate,
            routeCoordinates: routeCoordinates
        ), nearestDistance > routeDeviationThreshold else {
            return
        }

        let now = Date()
        if let lastRerouteAt, now.timeIntervalSince(lastRerouteAt) < rerouteMinimumInterval {
            return
        }

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

                let fare = self.fareCalculator.estimateRouteFare(
                    distance: route.distance,
                    expectedTravelTime: expectedTravelTime,
                    at: Date()
                )

                self.routePreview = HoguNavigationRoutePreview(
                    originName: "현재 위치",
                    destinationName: self.destinationText,
                    distance: route.distance,
                    expectedTravelTime: expectedTravelTime,
                    expectedFare: fare,
                    polyline: route.polyline,
                    originCoordinate: location.coordinate,
                    destinationCoordinate: destinationCoordinate,
                    guidanceSteps: self.routeGuidanceSteps(from: route)
                )
                self.originText = "현재 위치"
                self.originMapItem = sourceMapItem
                self.usesCurrentLocationAsOrigin = true
                self.speedCameras = []
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

        for step in route.steps {
            let instruction = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            if !instruction.isEmpty {
                steps.append(
                    HoguNavigationRouteStep(
                        instruction: instruction,
                        startDistance: distanceFromStart,
                        distance: step.distance
                    )
                )
            }
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

    private func updateRouteGuidance(from location: CLLocation) {
        guard let routePreview = routePreview,
              let progressDistance = routeProgressDistance(
                to: location.coordinate,
                routeCoordinates: routePreview.polyline.coordinates
              ) else {
            upcomingRouteInstruction = nil
            upcomingRouteInstructionDistance = nil
            return
        }

        let lookAheadPadding: CLLocationDistance = 25
        guard let nextStep = routePreview.guidanceSteps.first(where: {
            $0.startDistance > progressDistance + lookAheadPadding
        }) else {
            upcomingRouteInstruction = nil
            upcomingRouteInstructionDistance = nil
            return
        }

        upcomingRouteInstruction = nextStep.instruction
        upcomingRouteInstructionDistance = max(0, nextStep.startDistance - progressDistance)
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
        guard speedCameras.isEmpty else { return }
        let routeCoordinates = await MainActor.run {
            self.routePreview?.polyline.coordinates ?? []
        }
        let regions = await resolveSpeedCameraRegions(from: routeCoordinates)
        let cameras: [SpeedCamera]
        if regions.isEmpty {
            cameras = await speedCameraAPIClient.fetchCameras()
        } else {
            cameras = await speedCameraAPIClient.fetchCameras(regions: regions)
        }
        await MainActor.run {
            self.speedCameras = cameras
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
        guard coordinates.count > 8 else { return coordinates }

        let step = max(1, coordinates.count / 7)
        var samples = stride(from: 0, to: coordinates.count, by: step)
            .map { coordinates[$0] }

        if let last = coordinates.last {
            samples.append(last)
        }

        return samples
    }

    private func normalizedRegionName(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private func refreshSpeedCameraCandidates() {
        guard let routePreview = routePreview, !speedCameras.isEmpty else {
            speedCameraCandidates = []
            return
        }

        let coordinates = routePreview.polyline.coordinates
        guard !coordinates.isEmpty else {
            speedCameraCandidates = speedCameras
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
            return
        }

        speedCameraCandidates = speedCameras.filter { camera in
            let coordinate = camera.coordinate
            return coordinate.latitude >= minLatitude - margin
                && coordinate.latitude <= maxLatitude + margin
                && coordinate.longitude >= minLongitude - margin
                && coordinate.longitude <= maxLongitude + margin
        }
    }

    private func updateSpeedCameraWarning() {
        guard isNavigationStarted,
              let userCoordinate = userCoordinate else {
            speedCameraWarning = nil
            return
        }

        let routeCoordinates = routePreview?.polyline.coordinates ?? []

        let upcoming = speedCameraCandidates
            .compactMap { camera -> SpeedCameraWarning? in
                let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
                let cameraLocation = CLLocation(
                    latitude: camera.coordinate.latitude,
                    longitude: camera.coordinate.longitude
                )
                let directDistance = userLocation.distance(from: cameraLocation)
                let routeAheadDistance = self.routeAheadDistance(
                    from: userCoordinate,
                    to: camera.coordinate,
                    routeCoordinates: routeCoordinates
                )
                let aheadDistance = routeAheadDistance ?? directDistance
                guard aheadDistance <= 600 else { return nil }

                let cameraBearing = bearing(from: userCoordinate, to: camera.coordinate)
                guard angleDifference(userHeading, cameraBearing) <= 45 else { return nil }

                if !routeCoordinates.isEmpty {
                    let routeDistance = routeCoordinates
                        .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: cameraLocation) }
                        .min() ?? .greatestFiniteMagnitude
                    guard routeDistance <= 160 else { return nil }
                    guard routeAheadDistance != nil else { return nil }
                }

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

    private func routeAheadDistance(
        from userCoordinate: CLLocationCoordinate2D,
        to cameraCoordinate: CLLocationCoordinate2D,
        routeCoordinates: [CLLocationCoordinate2D]
    ) -> CLLocationDistance? {
        guard routeCoordinates.count >= 2,
              let userIndex = nearestRouteIndex(to: userCoordinate, routeCoordinates: routeCoordinates),
              let cameraIndex = nearestRouteIndex(to: cameraCoordinate, routeCoordinates: routeCoordinates),
              cameraIndex >= userIndex else {
            return nil
        }

        var distance = CLLocation(
            latitude: userCoordinate.latitude,
            longitude: userCoordinate.longitude
        ).distance(from: CLLocation(
            latitude: routeCoordinates[userIndex].latitude,
            longitude: routeCoordinates[userIndex].longitude
        ))

        if cameraIndex > userIndex {
            for index in userIndex..<cameraIndex {
                let start = routeCoordinates[index]
                let end = routeCoordinates[index + 1]
                distance += CLLocation(latitude: start.latitude, longitude: start.longitude)
                    .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
            }
        }

        distance += CLLocation(
            latitude: routeCoordinates[cameraIndex].latitude,
            longitude: routeCoordinates[cameraIndex].longitude
        ).distance(from: CLLocation(
            latitude: cameraCoordinate.latitude,
            longitude: cameraCoordinate.longitude
        ))

        return distance
    }

    private func nearestRouteIndex(
        to coordinate: CLLocationCoordinate2D,
        routeCoordinates: [CLLocationCoordinate2D]
    ) -> Int? {
        guard !routeCoordinates.isEmpty else { return nil }

        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return routeCoordinates.enumerated()
            .min { lhs, rhs in
                let lhsLocation = CLLocation(latitude: lhs.element.latitude, longitude: lhs.element.longitude)
                let rhsLocation = CLLocation(latitude: rhs.element.latitude, longitude: rhs.element.longitude)
                return lhsLocation.distance(from: targetLocation) < rhsLocation.distance(from: targetLocation)
            }?
            .offset
    }

    private func nearestRouteDistance(
        to coordinate: CLLocationCoordinate2D,
        routeCoordinates: [CLLocationCoordinate2D]
    ) -> CLLocationDistance? {
        guard !routeCoordinates.isEmpty else { return nil }

        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return routeCoordinates
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: targetLocation) }
            .min()
    }

    private func routeProgressDistance(
        to coordinate: CLLocationCoordinate2D,
        routeCoordinates: [CLLocationCoordinate2D]
    ) -> CLLocationDistance? {
        guard routeCoordinates.count >= 2,
              let routeIndex = nearestRouteIndex(to: coordinate, routeCoordinates: routeCoordinates) else {
            return nil
        }

        var distance: CLLocationDistance = 0
        if routeIndex > 0 {
            for index in 0..<routeIndex {
                let start = routeCoordinates[index]
                let end = routeCoordinates[index + 1]
                distance += CLLocation(latitude: start.latitude, longitude: start.longitude)
                    .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
            }
        }

        distance += CLLocation(
            latitude: routeCoordinates[routeIndex].latitude,
            longitude: routeCoordinates[routeIndex].longitude
        ).distance(from: CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))

        return distance
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
