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

        // 현재 위치 마커 업데이트 (임시 - 기본 annotation 사용)
        updateCurrentLocationAnnotation(mapView)
    }

    private func updateCurrentLocationAnnotation(_ mapView: MKMapView) {
        guard let location = viewModel.currentLocation else { return }

        // 기존 현재 위치 annotation 찾기
        let existingAnnotation = mapView.annotations.first { annotation in
            annotation.title == "현재 위치"
        }

        if let existing = existingAnnotation {
            // 기존 annotation 제거 후 새로 추가 (위치 업데이트)
            mapView.removeAnnotation(existing)
        }

        // 새 annotation 추가
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "현재 위치"
        mapView.addAnnotation(annotation)
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

        // 현재 위치 마커 스타일 (임시 - 추후 커스텀 마커로 변경)
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation.title == "현재 위치" else { return nil }

            let identifier = "CurrentLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false

                // 임시 마커 (이모지 기반)
                let label = UILabel()
                label.text = "🚕🐴"
                label.font = .systemFont(ofSize: 30)
                label.sizeToFit()
                annotationView?.addSubview(label)
                annotationView?.frame = label.frame
                annotationView?.centerOffset = CGPoint(x: 0, y: -15)
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
    }
}
