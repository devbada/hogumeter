//
//  HoguNavigationViewModel.swift
//  HoguMeter
//
//  Created on 2026-06-23.
//

import Foundation
import CoreLocation
import MapKit

enum HoguNavigationInputTarget: Hashable {
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

struct HoguNavigationRoutePreview {
    let originName: String
    let destinationName: String
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let expectedFare: Int
    let polyline: MKPolyline
    let originCoordinate: CLLocationCoordinate2D
    let destinationCoordinate: CLLocationCoordinate2D
}

final class HoguNavigationViewModel: NSObject, ObservableObject {

    @Published var originText: String = "현재 위치"
    @Published var destinationText: String = ""
    @Published var searchResults: [HoguNavigationSearchResult] = []
    @Published var selectedSearchTarget: HoguNavigationInputTarget = .destination
    @Published var routePreview: HoguNavigationRoutePreview?
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var userHeading: CLLocationDirection = 0
    @Published var userSpeed: Double = 0
    @Published var speedCameraWarning: SpeedCameraWarning?
    @Published var isResolvingLocation: Bool = false
    @Published var isCalculatingRoute: Bool = false
    @Published var isNavigationStarted: Bool = false
    @Published var errorMessage: String?

    private let searchCompleter = MKLocalSearchCompleter()
    private let locationManager = CLLocationManager()
    private let fareCalculator: FareCalculator
    private let speedCameraAPIClient = SpeedCameraAPIClient()
    private var speedCameras: [SpeedCamera] = []
    private var lastWarnedCameraId: String?
    private var originMapItem: MKMapItem?
    private var destinationMapItem: MKMapItem?
    private var currentLocation: CLLocation?

    init(fareCalculator: FareCalculator) {
        self.fareCalculator = fareCalculator
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

    func updateSearchQuery(_ query: String, target: HoguNavigationInputTarget) {
        selectedSearchTarget = target
        errorMessage = nil

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            searchCompleter.queryFragment = ""
            return
        }

        searchCompleter.queryFragment = trimmedQuery
    }

    func useCurrentLocationAsOrigin() {
        errorMessage = nil
        isResolvingLocation = true
        routePreview = nil

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
            }
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

                let fare = self.fareCalculator.estimateRouteFare(
                    distance: route.distance,
                    expectedTravelTime: route.expectedTravelTime,
                    at: Date()
                )

                self.routePreview = HoguNavigationRoutePreview(
                    originName: self.originText,
                    destinationName: self.destinationText,
                    distance: route.distance,
                    expectedTravelTime: route.expectedTravelTime,
                    expectedFare: fare,
                    polyline: route.polyline,
                    originCoordinate: originCoordinate,
                    destinationCoordinate: destinationCoordinate
                )
                HapticManager.medium()
            }
        }
    }

    func startNavigationFromPreview() {
        isNavigationStarted = true
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
        locationManager.stopUpdatingLocation()
        speedCameraWarning = nil
        lastWarnedCameraId = nil
        NotificationCenter.default.post(name: .hoguNavigationDidStop, object: nil)
    }

    private func apply(mapItem: MKMapItem, title: String, target: HoguNavigationInputTarget) {
        switch target {
        case .origin:
            originText = title
            originMapItem = mapItem
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
}

extension HoguNavigationViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results.map(HoguNavigationSearchResult.init)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
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
        guard let location = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = location
            self.userCoordinate = location.coordinate
            self.userHeading = self.heading(from: location)
            self.userSpeed = max(0, location.speed * 3.6)
            if !self.isNavigationStarted {
                self.originMapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                self.originText = "현재 위치"
            } else {
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
        if location.course >= 0 {
            return location.course
        }

        guard let destinationCoordinate = routePreview?.destinationCoordinate else {
            return userHeading
        }

        return bearing(from: location.coordinate, to: destinationCoordinate)
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
        let cameras = await speedCameraAPIClient.fetchCameras()
        await MainActor.run {
            self.speedCameras = cameras
            self.updateSpeedCameraWarning()
        }
    }

    private func updateSpeedCameraWarning() {
        guard isNavigationStarted,
              let userCoordinate = userCoordinate else {
            speedCameraWarning = nil
            return
        }

        let routeCoordinates = routePreview?.polyline.coordinates ?? []

        let upcoming = speedCameras
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

        if upcoming?.camera.id != lastWarnedCameraId {
            HapticManager.warning()
            lastWarnedCameraId = upcoming?.camera.id
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
