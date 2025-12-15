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
        // 지도 중심 업데이트
        if viewModel.shouldUpdateRegion {
            mapView.setRegion(viewModel.region, animated: true)
            DispatchQueue.main.async {
                viewModel.shouldUpdateRegion = false
            }
        }

        // 커스텀 마커 업데이트
        updateTaxiHorseAnnotation(mapView)
    }

    private func updateTaxiHorseAnnotation(_ mapView: MKMapView) {
        guard let location = viewModel.currentLocation else { return }

        if let existingAnnotation = mapView.annotations.first(where: { $0 is TaxiHorseAnnotation }) as? TaxiHorseAnnotation {
            // 기존 마커 업데이트 (부드러운 애니메이션)
            UIView.animate(withDuration: 0.3) {
                existingAnnotation.update(
                    coordinate: location,
                    heading: self.viewModel.currentHeading,
                    speed: self.viewModel.currentSpeed
                )
            }

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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        // 사용자가 지도를 드래그하면 추적 모드 비활성화
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began {
                Task { @MainActor in
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
            guard let taxiHorseAnnotation = annotation as? TaxiHorseAnnotation else { return nil }

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
    }
}
