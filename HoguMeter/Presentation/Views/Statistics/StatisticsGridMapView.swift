//
//  StatisticsGridMapView.swift
//  HoguMeter
//

import MapKit
import SwiftUI

struct StatisticsGridMapView: View {
    let cells: [StatisticsGridCell]

    var body: some View {
        ZStack(alignment: .bottom) {
            StatisticsGridMapRepresentable(cells: cells)
                .ignoresSafeArea(edges: .bottom)

            VStack(alignment: .leading, spacing: 8) {
                Text("이용 빈도")
                    .font(.caption.weight(.semibold))

                HStack(spacing: 8) {
                    Text("낮음")
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.2),
                            Color.orange.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 120, height: 10)
                    .clipShape(Capsule())
                    Text("높음")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .navigationTitle("이용 지역")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StatisticsGridMapRepresentable: UIViewRepresentable {
    let cells: [StatisticsGridCell]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let signature = cells.map { "\($0.id):\($0.visitCount)" }.joined(separator: "|")
        guard context.coordinator.signature != signature else { return }
        context.coordinator.signature = signature

        mapView.removeOverlays(mapView.overlays)
        let polygons = cells.map(makePolygon)
        mapView.addOverlays(polygons)

        let mapRect = polygons.reduce(MKMapRect.null) { partialResult, polygon in
            partialResult.union(polygon.boundingMapRect)
        }

        if !mapRect.isNull, mapRect.width > 0, mapRect.height > 0 {
            mapView.setVisibleMapRect(
                mapRect,
                edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 140, right: 40),
                animated: false
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func makePolygon(for cell: StatisticsGridCell) -> MKPolygon {
        var coordinates = [
            CLLocationCoordinate2D(
                latitude: cell.minLatitude,
                longitude: cell.minLongitude
            ),
            CLLocationCoordinate2D(
                latitude: cell.minLatitude,
                longitude: cell.maxLongitude
            ),
            CLLocationCoordinate2D(
                latitude: cell.maxLatitude,
                longitude: cell.maxLongitude
            ),
            CLLocationCoordinate2D(
                latitude: cell.maxLatitude,
                longitude: cell.minLongitude
            )
        ]

        let polygon = MKPolygon(coordinates: &coordinates, count: coordinates.count)
        polygon.title = String(cell.intensity)
        polygon.subtitle = "\(cell.visitCount)"
        return polygon
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var signature = ""

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? MKPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let intensity = min(max(Double(polygon.title ?? "") ?? 0, 0), 1)
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.18 + intensity * 0.58)
            renderer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.45 + intensity * 0.4)
            renderer.lineWidth = 1
            return renderer
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsGridMapView(cells: [])
    }
}
