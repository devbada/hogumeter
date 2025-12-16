//
//  MapViewRepresentable.swift
//  HoguMeter
//
//  Created on 2025-12-12.
//

import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    // 폴리라인 업데이트 최적화를 위한 좌표 개수 추적
    fileprivate class MapState {
        var lastPolylineCount: Int = 0
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false // 커스텀 마커 사용 예정
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = true

        // 제스처 인식기 추가 (사용자 드래그 감지)
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 추적 모드 변경 처리
        if viewModel.shouldUpdateTrackingMode {
            updateTrackingMode(mapView, context: context)
            DispatchQueue.main.async {
                viewModel.shouldUpdateTrackingMode = false
            }
        }

        // 지도 중심 업데이트 (heading 모드가 아닐 때만 region 사용)
        if viewModel.shouldUpdateRegion {
            if viewModel.trackingMode == .followWithHeading {
                // Heading 모드: 카메라로 위치와 방향 동시 업데이트
                updateCameraWithHeading(mapView)
            } else {
                mapView.setRegion(viewModel.region, animated: true)
            }
            DispatchQueue.main.async {
                viewModel.shouldUpdateRegion = false
            }
        }

        // Heading 모드에서 방향 업데이트 (region 업데이트 없이도)
        if viewModel.trackingMode == .followWithHeading {
            updateCameraHeadingOnly(mapView, context: context)
        }

        // 커스텀 마커 업데이트
        updateTaxiHorseAnnotation(mapView)

        // 폴리라인 업데이트 (좌표 개수가 변경되었을 때만)
        updatePolyline(mapView, mapState: context.coordinator.mapState)

        // 출발 마커 업데이트
        updateStartMarker(mapView)
    }

    private func updateTrackingMode(_ mapView: MKMapView, context: Context) {
        switch viewModel.trackingMode {
        case .none:
            // 추적 해제 - 지도 회전 초기화
            if mapView.camera.heading != 0 {
                let camera = mapView.camera.copy() as! MKMapCamera
                camera.heading = 0
                mapView.setCamera(camera, animated: true)
            }
        case .follow:
            // 일반 추적 - 지도 회전 초기화
            if mapView.camera.heading != 0 {
                let camera = mapView.camera.copy() as! MKMapCamera
                camera.heading = 0
                mapView.setCamera(camera, animated: true)
            }
        case .followWithHeading:
            // 방향 추적 - 현재 heading으로 카메라 설정
            updateCameraWithHeading(mapView)
        }
        context.coordinator.lastTrackingMode = viewModel.trackingMode
    }

    private func updateCameraWithHeading(_ mapView: MKMapView) {
        guard let location = viewModel.currentLocation else { return }

        let camera = MKMapCamera(
            lookingAtCenter: location,
            fromDistance: mapView.camera.centerCoordinateDistance,
            pitch: 0,
            heading: viewModel.currentHeading
        )
        mapView.setCamera(camera, animated: true)
    }

    private func updateCameraHeadingOnly(_ mapView: MKMapView, context: Context) {
        // heading이 변경되었을 때만 업데이트
        let currentHeading = viewModel.currentHeading
        guard abs(currentHeading - context.coordinator.lastHeading) > 1.0 else { return }
        context.coordinator.lastHeading = currentHeading

        guard let location = viewModel.currentLocation else { return }

        let camera = MKMapCamera(
            lookingAtCenter: location,
            fromDistance: mapView.camera.centerCoordinateDistance,
            pitch: 0,
            heading: currentHeading
        )
        mapView.setCamera(camera, animated: true)
    }

    private func updateTaxiHorseAnnotation(_ mapView: MKMapView) {
        guard let location = viewModel.currentLocation else { return }

        if let existingAnnotation = mapView.annotations.first(where: { $0 is TaxiHorseAnnotation }) as? TaxiHorseAnnotation {
            // 기존 마커 업데이트 (MKAnnotation coordinate는 KVO로 자동 애니메이션됨)
            existingAnnotation.update(
                coordinate: location,
                heading: viewModel.currentHeading,
                speed: viewModel.currentSpeed
            )

            // AnnotationView 업데이트
            if let annotationView = mapView.view(for: existingAnnotation) as? TaxiHorseAnnotationView {
                annotationView.updateHeading(viewModel.currentHeading)
                annotationView.updateSpeed(viewModel.currentSpeed)
            }
        } else {
            // 새 마커 추가
            let annotation = TaxiHorseAnnotation(
                coordinate: location,
                heading: viewModel.currentHeading,
                speed: viewModel.currentSpeed
            )
            mapView.addAnnotation(annotation)
        }
    }

    private func updatePolyline(_ mapView: MKMapView, mapState: MapState) {
        let coordinates = viewModel.routeCoordinates
        let currentCount = coordinates.count

        // 좌표 개수가 변경되지 않았으면 스킵 (성능 최적화)
        guard currentCount != mapState.lastPolylineCount else { return }
        mapState.lastPolylineCount = currentCount

        // 기존 폴리라인 제거
        mapView.overlays.forEach { overlay in
            if overlay is MKPolyline {
                mapView.removeOverlay(overlay)
            }
        }

        // 새 폴리라인 추가 (2개 이상 좌표가 있을 때만)
        guard currentCount >= 2 else { return }

        var coords = coordinates
        let polyline = MKPolyline(coordinates: &coords, count: coords.count)
        mapView.addOverlay(polyline)
    }

    private func updateStartMarker(_ mapView: MKMapView) {
        guard let startLocation = viewModel.startLocation else { return }

        // 이미 있으면 스킵
        let hasStartMarker = mapView.annotations.contains { $0 is StartPointAnnotation }
        guard !hasStartMarker else { return }

        let annotation = StartPointAnnotation(coordinate: startLocation)
        mapView.addAnnotation(annotation)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapViewRepresentable
        fileprivate let mapState = MapState()
        var lastHeading: Double = 0
        var lastTrackingMode: MapTrackingMode = .follow

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // 사용자가 지도를 드래그하면 추적 모드 비활성화 및 자동 줌 일시 중지
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began {
                Task { @MainActor in
                    parent.viewModel.userDidInteractWithMap()
                    parent.viewModel.disableTracking()
                }
            }
        }

        // 다른 제스처와 동시 인식 허용
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        // 커스텀 마커 뷰 제공
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // 출발 마커
            if annotation is StartPointAnnotation {
                let identifier = "StartPoint"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    view?.markerTintColor = .systemGreen
                    view?.glyphImage = UIImage(systemName: "flag.fill")
                } else {
                    view?.annotation = annotation
                }
                return view
            }

            // 택시+말 마커
            if let taxiHorseAnnotation = annotation as? TaxiHorseAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: TaxiHorseAnnotationView.reuseIdentifier
                ) as? TaxiHorseAnnotationView ?? TaxiHorseAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: TaxiHorseAnnotationView.reuseIdentifier
                )

                view.annotation = annotation
                view.updateHeading(taxiHorseAnnotation.heading)
                view.updateSpeed(taxiHorseAnnotation.speed)

                return view
            }

            return nil
        }

        // 폴리라인 렌더러
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
