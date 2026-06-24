//
//  HoguNavigationView.swift
//  HoguMeter
//
//  Created on 2026-06-23.
//

import SwiftUI
import MapKit

struct HoguNavigationView: View {
    @StateObject private var viewModel: HoguNavigationViewModel
    let meterViewModel: MeterViewModel
    @State private var speedCameraBlink = false
    @FocusState private var focusedField: HoguNavigationInputTarget?

    init(fareCalculator: FareCalculator, meterViewModel: MeterViewModel) {
        self.meterViewModel = meterViewModel
        self._viewModel = StateObject(wrappedValue: HoguNavigationViewModel(fareCalculator: fareCalculator))
    }

    var body: some View {
        NavigationView {
            ZStack {
                HoguNavigationMapView(
                    routePreview: viewModel.routePreview,
                    userCoordinate: viewModel.userCoordinate,
                    userHeading: viewModel.userHeading,
                    userSpeed: viewModel.userSpeed,
                    isNavigationStarted: viewModel.isNavigationStarted,
                    speedCameraWarning: viewModel.speedCameraWarning
                )
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    if !viewModel.isNavigationStarted {
                        searchPanel
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }

                    if viewModel.hasSearchListItems && !viewModel.isNavigationStarted {
                        searchList
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    Spacer()

                    if let preview = viewModel.routePreview {
                        routeSummary(preview)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 18)
                    }
                }

                if let preview = viewModel.routePreview, viewModel.isNavigationStarted {
                    hoguFareBadge(preview.expectedFare)
                        .padding(.top, 14)
                        .padding(.trailing, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                    currentHoguFareBadge(meterViewModel.currentFare)
                        .padding(.top, 14)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    speedBadge(viewModel.userSpeed)
                        .padding(.top, 188)
                        .padding(.trailing, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                    if let warning = viewModel.speedCameraWarning {
                        speedCameraLimitBadge(warning, isBlinking: speedCameraBlink)
                            .padding(.top, 195)
                            .padding(.leading, 20)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }

                    VStack(spacing: 8) {
                        if let message = viewModel.navigationStatusMessage {
                            navigationStatusCard(message, isLoading: viewModel.isRerouting)
                        }

                        if let instruction = viewModel.upcomingRouteInstruction {
                            routeGuidanceCard(
                                instruction: instruction,
                                distance: viewModel.upcomingRouteInstructionDistance
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 88)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationTitle("호구게이션")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.useCurrentLocationAsOrigin) {
                        Image(systemName: viewModel.isResolvingLocation ? "location.circle" : "location")
                    }
                    .disabled(viewModel.isResolvingLocation)
                }
            }
            .onAppear {
                viewModel.prepareOnAppear()
            }
            .onChange(of: viewModel.speedCameraWarning?.isSpeeding ?? false) { _, isSpeeding in
                updateSpeedCameraBlink(isSpeeding: isSpeeding)
            }
            .onChange(of: focusedField) { _, newValue in
                guard let target = newValue else {
                    viewModel.clearSearchSuggestions()
                    return
                }
                viewModel.focusSearch(target: target)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var searchPanel: some View {
        VStack(spacing: 10) {
            searchField(
                title: "출발",
                systemImage: "location.fill",
                text: $viewModel.originText,
                target: .origin
            )

            searchField(
                title: "도착",
                systemImage: "mappin.and.ellipse",
                text: $viewModel.destinationText,
                target: .destination
            )

            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(errorMessage)
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(.red)
            }

            Button(action: {
                focusedField = nil
                viewModel.calculateRoute()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    Text(viewModel.isCalculatingRoute ? "계산 중" : "예상 호구비 계산")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundColor(.white)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isCalculatingRoute)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }

    private func searchField(
        title: String,
        systemImage: String,
        text: Binding<String>,
        target: HoguNavigationInputTarget
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(target == .origin ? .green : .red)
                .frame(width: 22)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .leading)

            TextField(title, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: target)
                .submitLabel(.search)
                .onChange(of: text.wrappedValue) { _, newValue in
                    guard focusedField == target else { return }
                    viewModel.updateSearchQuery(newValue, target: target)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var searchList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.recentSuggestions.prefix(5)) { suggestion in
                Button(action: {
                    focusedField = nil
                    viewModel.selectRecentSuggestion(suggestion)
                }) {
                    searchRow(
                        icon: suggestion.icon,
                        iconColor: .orange,
                        title: suggestion.title,
                        subtitle: suggestion.subtitle
                    )
                }

                if suggestion.id != viewModel.recentSuggestions.prefix(5).last?.id {
                    Divider()
                        .padding(.leading, 42)
                }
            }

            ForEach(viewModel.searchResults.prefix(6)) { result in
                Button(action: {
                    let target = viewModel.selectedSearchTarget
                    focusedField = nil
                    viewModel.selectSearchResult(result, target: target)
                }) {
                    searchRow(
                        icon: "magnifyingglass",
                        iconColor: .secondary,
                        title: result.title,
                        subtitle: result.subtitle
                    )
                }

                if result.id != viewModel.searchResults.prefix(6).last?.id {
                    Divider()
                        .padding(.leading, 42)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    private func searchRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }

    private func routeSummary(_ preview: HoguNavigationRoutePreview) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                summaryItem(
                    icon: "road.lanes",
                    title: "예상 거리",
                    value: formatDistance(preview.distance)
                )

                Divider()
                    .frame(height: 42)

                summaryItem(
                    icon: "clock",
                    title: "예상 시간",
                    value: formatDuration(preview.expectedTravelTime)
                )

                Divider()
                    .frame(height: 42)

                summaryItem(
                    icon: "wonsign.circle.fill",
                    title: "예상 호구비",
                    value: "\(preview.expectedFare.formattedWithComma)원",
                    valueColor: .orange
                )
            }

            Button(action: {
                toggleNavigation()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isNavigationStarted ? "stop.circle.fill" : "location.north.circle.fill")
                    Text(viewModel.isNavigationStarted ? "네비게이션 중지" : "네비게이션 시작")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundColor(.white)
                .background(viewModel.isNavigationStarted ? Color.red : Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.14), radius: 12, y: -4)
    }

    private func toggleNavigation() {
        if viewModel.isNavigationStarted {
            viewModel.stopNavigation()
            return
        }

        guard meterViewModel.state != .running else {
            viewModel.errorMessage = "일반 미터기 사용 중에는 네비게이션을 시작할 수 없습니다."
            HapticManager.warning()
            return
        }

        viewModel.startNavigationFromPreview()
    }

    private func hoguFareBadge(_ fare: Int) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("예상 호구비용")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(fare.formattedWithComma)원")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func currentHoguFareBadge(_ fare: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("현재 호구비용")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(fare.formattedWithComma)원")
                .font(.title2)
                .fontWeight(.heavy)
                .foregroundColor(.green)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.16), radius: 10, y: 5)
    }

    private func speedBadge(_ speed: Double) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(speed.rounded()))")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("km/h")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.86))
        }
        .frame(width: 86, height: 76)
        .background(Color.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
    }

    private func speedCameraLimitBadge(_ warning: SpeedCameraWarning, isBlinking: Bool) -> some View {
        HStack(spacing: 8) {
            speedLimitSign(limitKmh: warning.camera.limitKmh)

            if warning.isSpeeding {
                overspeedBadge(overspeedKmh: warning.overspeedKmh)
                    .opacity(isBlinking ? 0.45 : 1)
            }
        }
    }

    private func speedLimitSign(limitKmh: Int?) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.94))
                .overlay {
                    Circle()
                        .stroke(Color.red, lineWidth: 6)
                }
                .shadow(color: .black.opacity(0.16), radius: 10, y: 5)

            if let limitKmh {
                VStack(spacing: 1) {
                    Text("제한속도")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.black)

                    Text("\(limitKmh)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            } else {
                Image(systemName: "camera.metering.spot")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.red)
            }
        }
        .frame(width: 62, height: 62)
    }

    private func overspeedBadge(overspeedKmh: Int) -> some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .shadow(color: .red.opacity(0.34), radius: 10, y: 5)

            VStack(spacing: 1) {
                Text("초과")
                    .font(.system(size: 9, weight: .heavy))

                Text("+\(overspeedKmh)")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(.white)
        }
        .frame(width: 54, height: 54)
    }

    private func navigationStatusCard(_ message: String, isLoading: Bool) -> some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.white)
                    .frame(width: 20)
            }

            Text(message)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
    }

    private func routeGuidanceCard(instruction: String, distance: CLLocationDistance?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: guidanceIcon(for: instruction))
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                if let distance = distance {
                    Text("\(formatDistance(distance)) 후")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.82))
                }

                Text(instruction)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.blue.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
    }

    private func guidanceIcon(for instruction: String) -> String {
        if instruction.contains("좌") {
            return "arrow.turn.up.left"
        }
        if instruction.contains("우") {
            return "arrow.turn.up.right"
        }
        if instruction.contains("유턴") || instruction.uppercased().contains("U") {
            return "arrow.uturn.left"
        }
        return "arrow.up"
    }

    private func updateSpeedCameraBlink(isSpeeding: Bool) {
        speedCameraBlink = false
        guard isSpeeding else { return }

        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
            speedCameraBlink = true
        }
    }

    private func summaryItem(icon: String, title: String, value: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(valueColor)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        }
        return String(format: "%.1fkm", distance / 1000)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(max(minutes, 1))분"
        }

        let hours = minutes / 60
        let remainMinutes = minutes % 60
        return "\(hours)시간 \(remainMinutes)분"
    }
}

private struct HoguNavigationMapView: UIViewRepresentable {
    let routePreview: HoguNavigationRoutePreview?
    let userCoordinate: CLLocationCoordinate2D?
    let userHeading: CLLocationDirection
    let userSpeed: Double
    let isNavigationStarted: Bool
    let speedCameraWarning: SpeedCameraWarning?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.pointOfInterestFilter = .includingAll
        mapView.setRegion(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            ),
            animated: false
        )
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.showsUserLocation = !isNavigationStarted

        if let routePreview = routePreview {
            let routeChanged = context.coordinator.renderedRoutePolyline !== routePreview.polyline
            updateRouteOverlays(
                mapView,
                context: context,
                routePreview: routePreview,
                routeChanged: routeChanged
            )
            updateVehicleAnnotation(mapView, context: context)

            let annotationKey = annotationStateKey(routePreview: routePreview, speedCameraWarning: speedCameraWarning)
            if context.coordinator.renderedAnnotationKey != annotationKey {
                mapView.removeAnnotations(mapView.annotations.filter {
                    !($0 is MKUserLocation)
                        && !($0 is HoguNavigationVehicleAnnotation)
                })
                mapView.addAnnotation(annotation(title: "출발", coordinate: routePreview.originCoordinate))
                mapView.addAnnotation(annotation(title: "도착", coordinate: routePreview.destinationCoordinate))
                if let speedCameraWarning = speedCameraWarning {
                    mapView.addAnnotation(annotation(title: "단속", coordinate: speedCameraWarning.camera.coordinate))
                }
                context.coordinator.renderedAnnotationKey = annotationKey
            }

            if isNavigationStarted {
                guard context.coordinator.shouldUpdateCamera() else { return }

                let targetCoordinate = userCoordinate ?? routePreview.originCoordinate
                let camera = MKMapCamera(
                    lookingAtCenter: targetCoordinate,
                    fromDistance: cameraDistance(for: userSpeed),
                    pitch: 58,
                    heading: userHeading
                )
                mapView.setCamera(camera, animated: true)
                return
            }

            if routeChanged {
                let edgePadding = UIEdgeInsets(top: 180, left: 40, bottom: 210, right: 40)
                mapView.setVisibleMapRect(routePreview.polyline.boundingMapRect, edgePadding: edgePadding, animated: true)
            }
            return
        }

        context.coordinator.resetRenderedRoute()
        if !mapView.overlays.isEmpty {
            mapView.removeOverlays(mapView.overlays)
        }
        let mapAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        if !mapAnnotations.isEmpty {
            mapView.removeAnnotations(mapAnnotations)
        }

        if let userCoordinate = userCoordinate {
            mapView.setRegion(
                MKCoordinateRegion(
                    center: userCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ),
                animated: true
            )
        }
    }

    private func updateRouteOverlays(
        _ mapView: MKMapView,
        context: Context,
        routePreview: HoguNavigationRoutePreview,
        routeChanged: Bool
    ) {
        guard isNavigationStarted,
              let userCoordinate = userCoordinate else {
            guard routeChanged || context.coordinator.renderedProgressIndex != nil else { return }
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlay(routeOverlay(routePreview.polyline, title: "remaining"))
            context.coordinator.renderedRoutePolyline = routePreview.polyline
            context.coordinator.renderedProgressIndex = nil
            return
        }

        let coordinates = routePreview.polyline.coordinates
        guard coordinates.count >= 2,
              let progressIndex = nearestRouteIndex(to: userCoordinate, routeCoordinates: coordinates),
              routeChanged || context.coordinator.renderedProgressIndex != progressIndex else {
            return
        }

        mapView.removeOverlays(mapView.overlays)

        if progressIndex >= 1 {
            var passedCoordinates = Array(coordinates[0...progressIndex])
            let passedOverlay = MKPolyline(coordinates: &passedCoordinates, count: passedCoordinates.count)
            passedOverlay.title = "passed"
            mapView.addOverlay(passedOverlay)
        }

        if progressIndex < coordinates.count - 1 {
            var remainingCoordinates = Array(coordinates[progressIndex..<coordinates.count])
            let remainingOverlay = MKPolyline(coordinates: &remainingCoordinates, count: remainingCoordinates.count)
            remainingOverlay.title = "remaining"
            mapView.addOverlay(remainingOverlay)
        }

        context.coordinator.renderedRoutePolyline = routePreview.polyline
        context.coordinator.renderedProgressIndex = progressIndex
    }

    private func updateVehicleAnnotation(_ mapView: MKMapView, context: Context) {
        guard isNavigationStarted, let userCoordinate = userCoordinate else {
            if let vehicleAnnotation = context.coordinator.vehicleAnnotation {
                mapView.removeAnnotation(vehicleAnnotation)
                context.coordinator.vehicleAnnotation = nil
            }
            return
        }

        if let vehicleAnnotation = context.coordinator.vehicleAnnotation {
            vehicleAnnotation.coordinate = userCoordinate
            vehicleAnnotation.heading = userHeading
            if let view = mapView.view(for: vehicleAnnotation) as? HoguNavigationRotatingAnnotationView {
                view.heading = vehicleAnnotation.heading
            }
        } else {
            let annotation = HoguNavigationVehicleAnnotation(
                coordinate: userCoordinate,
                heading: userHeading
            )
            context.coordinator.vehicleAnnotation = annotation
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func annotation(title: String, coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = coordinate
        return annotation
    }

    private func routeOverlay(_ polyline: MKPolyline, title: String) -> MKPolyline {
        var coordinates = polyline.coordinates
        let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        overlay.title = title
        return overlay
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

    private func annotationStateKey(
        routePreview: HoguNavigationRoutePreview,
        speedCameraWarning: SpeedCameraWarning?
    ) -> String {
        [
            routePreview.originName,
            routePreview.destinationName,
            String(routePreview.originCoordinate.latitude),
            String(routePreview.originCoordinate.longitude),
            String(routePreview.destinationCoordinate.latitude),
            String(routePreview.destinationCoordinate.longitude),
            speedCameraWarning?.camera.id ?? ""
        ].joined(separator: "|")
    }

    private func cameraDistance(for speed: Double) -> CLLocationDistance {
        switch speed {
        case ..<10:
            return 520
        case ..<40:
            return 850
        case ..<80:
            return 1_250
        default:
            return 1_700
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var renderedRoutePolyline: MKPolyline?
        var renderedAnnotationKey: String?
        var renderedProgressIndex: Int?
        var vehicleAnnotation: HoguNavigationVehicleAnnotation?
        private var lastCameraUpdateAt = Date.distantPast

        func shouldUpdateCamera() -> Bool {
            let now = Date()
            guard now.timeIntervalSince(lastCameraUpdateAt) > 0.35 else {
                return false
            }
            lastCameraUpdateAt = now
            return true
        }

        func resetRenderedRoute() {
            renderedRoutePolyline = nil
            renderedAnnotationKey = nil
            renderedProgressIndex = nil
            vehicleAnnotation = nil
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = polyline.title == "passed"
                ? UIColor.systemGray3
                : UIColor.systemOrange
            renderer.lineWidth = 6
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            if let vehicleAnnotation = annotation as? HoguNavigationVehicleAnnotation {
                let identifier = "HoguNavigationVehicle"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? HoguNavigationRotatingAnnotationView
                    ?? HoguNavigationRotatingAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.configureVehicle()
                view.heading = vehicleAnnotation.heading
                return view
            }

            let identifier = "HoguNavigationPoint"
            let annotationTitle = annotation.title ?? ""
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            switch annotationTitle {
            case "출발":
                view.markerTintColor = .systemGreen
                view.glyphImage = UIImage(systemName: "location.fill")
            case "단속":
                view.markerTintColor = .systemRed
                view.glyphImage = UIImage(systemName: "camera.fill")
            default:
                view.markerTintColor = .systemRed
                view.glyphImage = UIImage(systemName: "flag.checkered")
            }
            return view
        }
    }
}

private final class HoguNavigationVehicleAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var heading: CLLocationDirection
    let title: String? = "현재 위치"

    init(coordinate: CLLocationCoordinate2D, heading: CLLocationDirection) {
        self.coordinate = coordinate
        self.heading = heading
    }
}

private final class HoguNavigationRotatingAnnotationView: MKAnnotationView {
    private var headingOffset: CGFloat = 0

    var heading: CLLocationDirection = 0 {
        didSet {
            transform = CGAffineTransform(rotationAngle: CGFloat(heading * .pi / 180) + headingOffset)
        }
    }

    func configureVehicle() {
        headingOffset = 0
        image = vehicleImage()
        frame = CGRect(x: 0, y: 0, width: 46, height: 56)
        centerOffset = CGPoint(x: 0, y: 0)
        canShowCallout = false
    }

    private func vehicleImage() -> UIImage? {
        let size = CGSize(width: 46, height: 56)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setShadow(offset: CGSize(width: 0, height: 4), blur: 7, color: UIColor.black.withAlphaComponent(0.26).cgColor)

            let bodyRect = CGRect(x: 9, y: 8, width: 28, height: 40)
            let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: 12)
            UIColor.systemBlue.setFill()
            bodyPath.fill()

            cgContext.setShadow(offset: .zero, blur: 0, color: nil)

            let hoodPath = UIBezierPath()
            hoodPath.move(to: CGPoint(x: 23, y: 2))
            hoodPath.addLine(to: CGPoint(x: 34, y: 15))
            hoodPath.addLine(to: CGPoint(x: 12, y: 15))
            hoodPath.close()
            UIColor(red: 0.23, green: 0.68, blue: 1, alpha: 1).setFill()
            hoodPath.fill()

            let glassPath = UIBezierPath(roundedRect: CGRect(x: 14, y: 16, width: 18, height: 13), cornerRadius: 5)
            UIColor.white.withAlphaComponent(0.88).setFill()
            glassPath.fill()

            let cabinPath = UIBezierPath(roundedRect: CGRect(x: 13, y: 30, width: 20, height: 12), cornerRadius: 5)
            UIColor(red: 0.09, green: 0.31, blue: 0.92, alpha: 1).setFill()
            cabinPath.fill()

            UIColor.black.withAlphaComponent(0.34).setFill()
            UIBezierPath(roundedRect: CGRect(x: 5, y: 18, width: 7, height: 15), cornerRadius: 3).fill()
            UIBezierPath(roundedRect: CGRect(x: 34, y: 18, width: 7, height: 15), cornerRadius: 3).fill()
            UIBezierPath(roundedRect: CGRect(x: 5, y: 36, width: 7, height: 15), cornerRadius: 3).fill()
            UIBezierPath(roundedRect: CGRect(x: 34, y: 36, width: 7, height: 15), cornerRadius: 3).fill()

            UIColor.white.withAlphaComponent(0.9).setFill()
            UIBezierPath(ovalIn: CGRect(x: 15, y: 5, width: 5, height: 5)).fill()
            UIBezierPath(ovalIn: CGRect(x: 26, y: 5, width: 5, height: 5)).fill()
        }
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

#Preview {
    let settingsRepository = SettingsRepository()
    return HoguNavigationView(
        fareCalculator: FareCalculator(settingsRepository: settingsRepository),
        meterViewModel: MeterViewModel(
            locationService: LocationService(settingsRepository: settingsRepository),
            fareCalculator: FareCalculator(settingsRepository: settingsRepository),
            settingsRepository: settingsRepository,
            regionDetector: RegionDetector(),
            soundManager: SoundManager(),
            tripRepository: TripRepository()
        )
    )
}
