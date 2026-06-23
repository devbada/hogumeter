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

                    if !viewModel.searchResults.isEmpty && !viewModel.isNavigationStarted {
                        searchResultsList
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

                    if let warning = viewModel.speedCameraWarning {
                        speedCameraWarningCard(warning)
                            .opacity(warning.isSpeeding && speedCameraBlink ? 0.45 : 1)
                            .padding(.horizontal, 16)
                            .padding(.top, 88)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
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
                viewModel.useCurrentLocationAsOrigin()
            }
            .onChange(of: viewModel.speedCameraWarning?.isSpeeding ?? false) { _, isSpeeding in
                updateSpeedCameraBlink(isSpeeding: isSpeeding)
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

    private var searchResultsList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.searchResults.prefix(6)) { result in
                Button(action: {
                    let target = viewModel.selectedSearchTarget
                    focusedField = nil
                    viewModel.selectSearchResult(result, target: target)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
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
                if viewModel.isNavigationStarted {
                    viewModel.stopNavigation()
                } else {
                    viewModel.startNavigationFromPreview()
                }
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

    private func speedCameraWarningCard(_ warning: SpeedCameraWarning) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.metering.spot")
                .font(.title3)
                .foregroundColor(warning.isSpeeding ? .white : .red)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(warning.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(warning.isSpeeding ? .white : .primary)

                Text(warning.message)
                    .font(.caption)
                    .foregroundColor(warning.isSpeeding ? .white.opacity(0.9) : .secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(warning.isSpeeding ? Color.red.opacity(0.92) : Color.clear)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(warning.isSpeeding ? Color.red : Color.clear, lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.16), radius: 10, y: 5)
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
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })

        if let routePreview = routePreview {
            mapView.addOverlay(routePreview.polyline)
            mapView.addAnnotation(annotation(title: "출발", coordinate: routePreview.originCoordinate))
            mapView.addAnnotation(annotation(title: "도착", coordinate: routePreview.destinationCoordinate))
            if let speedCameraWarning = speedCameraWarning {
                mapView.addAnnotation(annotation(title: "단속", coordinate: speedCameraWarning.camera.coordinate))
            }

            if isNavigationStarted {
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

            let edgePadding = UIEdgeInsets(top: 180, left: 40, bottom: 210, right: 40)
            mapView.setVisibleMapRect(routePreview.polyline.boundingMapRect, edgePadding: edgePadding, animated: true)
            return
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func annotation(title: String, coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = coordinate
        return annotation
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
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemOrange
            renderer.lineWidth = 6
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

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
