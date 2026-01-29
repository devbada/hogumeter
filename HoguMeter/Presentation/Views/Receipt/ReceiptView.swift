//
//  ReceiptView.swift
//  HoguMeter
//
//  Created on 2025-12-09.
//

import SwiftUI
import Photos
import MapKit

/// 주행 완료 후 영수증을 표시하는 뷰
struct ReceiptView: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @State private var receiptImage: UIImage?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var isSaving = false
    @State private var mapSnapshotImage: UIImage?
    @State private var isLoadingMap = true
    @State private var selectedTemplate: ReceiptTemplate
    @State private var showTemplateSheet = false
    @State private var showShareSheet = false
    @State private var generatedReceiptImage: UIImage?

    private let settingsRepository = SettingsRepository()

    init(trip: Trip) {
        self.trip = trip
        // 저장된 기본 템플릿으로 초기화
        let repository = SettingsRepository()
        _selectedTemplate = State(initialValue: repository.receiptTemplate)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    receiptHeader

                    Divider()
                        .padding(.vertical, 20)

                    // 경로 지도 (경로가 있을 때만)
                    if !trip.routePoints.isEmpty {
                        routeMapSection

                        Divider()
                            .padding(.vertical, 20)
                    }

                    // 시간 정보
                    timeSection

                    Divider()
                        .padding(.vertical, 20)

                    // 요금 상세 내역
                    fareBreakdownSection

                    Divider()
                        .padding(.vertical, 20)

                    // 총 요금
                    totalFareSection

                    Divider()
                        .padding(.vertical, 20)

                    // 슬로건
                    sloganSection

                    Spacer(minLength: 20)

                    // 공유 버튼들
                    if let receiptImage = generatedReceiptImage {
                        ShareButtonsView(image: receiptImage, onDismiss: { dismiss() })
                            .padding(.top, 10)
                    } else {
                        // 이미지 생성 중 로딩 표시
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("영수증 이미지 생성 중...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }

                    Spacer(minLength: 20)
                }
                .padding(30)
            }
            .background(Color(.systemBackground))
            .navigationTitle("영수증")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        showTemplateSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedTemplate.iconName)
                            Text(selectedTemplate.displayName)
                                .font(.subheadline)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showTemplateSheet) {
                TemplateSelectionView(selectedTemplate: $selectedTemplate)
            }
            .onChange(of: selectedTemplate) { _, newValue in
                settingsRepository.receiptTemplate = newValue
                // 템플릿 변경 시 이미지 재생성
                Task {
                    await regenerateReceiptImage()
                }
            }
            .alert("영수증 저장", isPresented: $showSaveAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
            }
            .task {
                // 뷰가 나타날 때 지도 스냅샷 로드 및 영수증 이미지 생성
                if trip.routePoints.count >= 2 {
                    mapSnapshotImage = await generateMapSnapshotWithRoute()
                }
                isLoadingMap = false
                await regenerateReceiptImage()
            }
        }
    }

    // MARK: - Generate Receipt Image
    @MainActor
    private func regenerateReceiptImage() async {
        // 지도 스냅샷 생성 (경로가 있는 경우, 미니멀 템플릿 제외)
        var mapSnapshot: UIImage?
        if trip.routePoints.count >= 2 && selectedTemplate != .minimal {
            mapSnapshot = await generateMapSnapshot()
        }

        // 선택된 템플릿으로 영수증 이미지 생성
        generatedReceiptImage = TemplateReceiptGenerator.generate(
            from: trip,
            template: selectedTemplate,
            mapSnapshot: mapSnapshot
        )
    }

    // MARK: - Header
    private var receiptHeader: some View {
        VStack(spacing: 15) {
            // 앱 로고 (이모지 대체)
            Text("🏇")
                .font(.system(size: 60))

            Text("호구미터")
                .font(.title)
                .fontWeight(.bold)

            Text("TAXI FARE RECEIPT")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Time Section
    private var timeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("출발")
                    .foregroundColor(.secondary)
                Spacer()
                Text(trip.startTime.formatted(date: .omitted, time: .shortened))
                    .fontWeight(.semibold)
            }

            HStack {
                Text("도착")
                    .foregroundColor(.secondary)
                Spacer()
                Text(trip.endTime.formatted(date: .omitted, time: .shortened))
                    .fontWeight(.semibold)
            }

            HStack {
                Text("날짜")
                    .foregroundColor(.secondary)
                Spacer()
                Text(trip.startTime.formatted(date: .long, time: .omitted))
                    .fontWeight(.semibold)
            }

            HStack {
                Text("소요 시간")
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDuration(trip.duration))
                    .fontWeight(.semibold)
            }
        }
        .font(.body)
    }

    // MARK: - Fare Breakdown Section
    private var fareBreakdownSection: some View {
        VStack(spacing: 12) {
            Text("요금 내역")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            // 기본 요금
            fareRow(
                title: "기본 요금",
                value: trip.fareBreakdown.baseFare,
                detail: "2km"
            )

            // 거리 요금
            if trip.fareBreakdown.distanceFare > 0 {
                fareRow(
                    title: "거리 요금",
                    value: trip.fareBreakdown.distanceFare,
                    detail: String(format: "%.1fkm", trip.distance)
                )
            }

            // 시간 요금
            if trip.fareBreakdown.timeFare > 0 {
                fareRow(
                    title: "시간 요금",
                    value: trip.fareBreakdown.timeFare
                )
            }

            // 지역 할증
            if trip.fareBreakdown.regionSurcharge > 0 {
                fareRow(
                    title: "지역 할증",
                    value: trip.fareBreakdown.regionSurcharge,
                    detail: trip.isRealisticMode
                        ? trip.surchargeRateDisplay  // 리얼 모드: "20%"
                        : "\(trip.regionChanges)회"  // 재미 모드: "367회"
                )
            }

            // 야간 할증
            if trip.fareBreakdown.nightSurcharge > 0 {
                fareRow(
                    title: "야간 할증",
                    value: trip.fareBreakdown.nightSurcharge,
                    detail: "20%"
                )
            }
        }
    }

    // MARK: - Total Fare Section
    private var totalFareSection: some View {
        HStack {
            Text("총 요금")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Text("\(trip.totalFare.formattedWithComma)원")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Slogan Section
    private var sloganSection: some View {
        VStack(spacing: 8) {
            // 택시기사 한마디 (있으면 표시)
            if let quote = trip.driverQuote, !quote.isEmpty {
                HStack(spacing: 6) {
                    Text("🚕")
                        .font(.title3)
                    Text("\"\(quote)\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }

            Text("🚖")
                .font(.title)

            Text("내 차 탔으면 내놔")
                .font(.headline)
                .fontWeight(.bold)

            Text("Thank you for using HoguMeter")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Route Map Section
    private var routeMapSection: some View {
        VStack(spacing: 8) {
            Text("주행 경로")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 지도 스냅샷 이미지 표시
            ZStack {
                if isLoadingMap {
                    // 로딩 중
                    Color(.systemGray6)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let mapImage = mapSnapshotImage {
                    // 지도 스냅샷 표시
                    Image(uiImage: mapImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // 지도 로드 실패 또는 경로 없음 - 기존 Canvas 폴백
                    routeMapCanvas
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )

            // 범례
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 10, height: 10)
                    Text("출발").font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 10, height: 10)
                    Text("도착").font(.caption).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Route Map Canvas (폴백용)
    private var routeMapCanvas: some View {
        Canvas { context, size in
            let points = trip.routePoints
            guard points.count >= 2 else { return }

            // 좌표 범위 계산
            let lats = points.map { $0.latitude }
            let lons = points.map { $0.longitude }
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLon = lons.min(), let maxLon = lons.max() else { return }

            let latRange = max(maxLat - minLat, 0.001)
            let lonRange = max(maxLon - minLon, 0.001)
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2

            // 화면 좌표 변환 함수
            let padding: CGFloat = 15
            func toScreen(_ lat: Double, _ lon: Double) -> CGPoint {
                let x = padding + ((lon - (centerLon - lonRange / 2)) / lonRange) * (size.width - padding * 2)
                let y = size.height - padding - ((lat - (centerLat - latRange / 2)) / latRange) * (size.height - padding * 2)
                return CGPoint(x: x, y: y)
            }

            // 경로 그리기
            var path = Path()
            let firstPoint = toScreen(points[0].latitude, points[0].longitude)
            path.move(to: firstPoint)

            for i in 1..<points.count {
                let point = toScreen(points[i].latitude, points[i].longitude)
                path.addLine(to: point)
            }

            context.stroke(path, with: .color(.blue), lineWidth: 3)

            // 출발점 (녹색) - 안전한 배열 접근
            if let firstRoutePoint = points.first {
                let startPoint = toScreen(firstRoutePoint.latitude, firstRoutePoint.longitude)
                context.fill(Circle().path(in: CGRect(x: startPoint.x - 6, y: startPoint.y - 6, width: 12, height: 12)), with: .color(.green))
            }

            // 도착점 (빨간색) - 안전한 배열 접근
            if let lastRoutePoint = points.last {
                let endPoint = toScreen(lastRoutePoint.latitude, lastRoutePoint.longitude)
                context.fill(Circle().path(in: CGRect(x: endPoint.x - 6, y: endPoint.y - 6, width: 12, height: 12)), with: .color(.red))
            }
        }
        .background(Color(.systemGray6))
    }

    // MARK: - Helper Views
    private func fareRow(title: String, value: Int, detail: String? = nil) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            if let detail = detail {
                Text("(\(detail))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(value.formattedWithComma)원")
                .fontWeight(.semibold)
        }
    }

    // MARK: - Helpers
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분 \(seconds)초"
        } else if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }

    // MARK: - Capture Action
    @MainActor
    private func captureReceipt() {
        guard !isSaving else { return } // 중복 호출 방지
        isSaving = true

        Task { @MainActor in
            // 지도 스냅샷 생성 (경로가 있는 경우, 미니멀 템플릿 제외)
            var mapSnapshot: UIImage?
            if trip.routePoints.count >= 2 && selectedTemplate != .minimal {
                mapSnapshot = await generateMapSnapshot()
            }

            // 선택된 템플릿으로 영수증 이미지 생성
            let image = TemplateReceiptGenerator.generate(
                from: trip,
                template: selectedTemplate,
                mapSnapshot: mapSnapshot
            )

            // 사진첩에 저장
            await saveToPhotoLibrary(image: image)
            // Note: isSaving is reset in saveToPhotoLibrary
        }
    }

    /// 지도 스냅샷 + 경로 + 마커를 포함한 이미지 생성 (캡처/저장용)
    private func generateMapSnapshot() async -> UIImage? {
        guard trip.routePoints.count >= 2 else { return nil }

        let lats = trip.routePoints.map { $0.latitude }
        let lons = trip.routePoints.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }

        // 여유 공간 추가
        let latPadding = max((maxLat - minLat) * 0.3, 0.002)
        let lonPadding = max((maxLon - minLon) * 0.3, 0.002)

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(maxLat - minLat + latPadding, 0.005),
                longitudeDelta: max(maxLon - minLon + lonPadding, 0.005)
            )
        )

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 280, height: 120)
        options.scale = 2.0

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            // 경로와 마커를 스냅샷에 그려서 반환 (snapshot.point(for:) 사용)
            return drawRouteOnSnapshot(snapshot)
        } catch {
            return nil
        }
    }

    /// 지도 스냅샷 + 경로 + 마커를 포함한 이미지 생성 (라이브 뷰용)
    private func generateMapSnapshotWithRoute() async -> UIImage? {
        guard trip.routePoints.count >= 2 else { return nil }

        let lats = trip.routePoints.map { $0.latitude }
        let lons = trip.routePoints.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }

        // 여유 공간 추가
        let latPadding = max((maxLat - minLat) * 0.3, 0.002)
        let lonPadding = max((maxLon - minLon) * 0.3, 0.002)

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(maxLat - minLat + latPadding, 0.005),
                longitudeDelta: max(maxLon - minLon + lonPadding, 0.005)
            )
        )

        // 라이브 뷰용으로 더 큰 사이즈
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 400, height: 200)
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            return drawRouteOnSnapshot(snapshot)
        } catch {
            return nil
        }
    }

    /// 스냅샷 위에 경로와 마커를 그림
    private func drawRouteOnSnapshot(_ snapshot: MKMapSnapshotter.Snapshot) -> UIImage {
        let image = snapshot.image
        let size = image.size

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // 기본 지도 이미지 그리기
            image.draw(at: .zero)

            let ctx = context.cgContext

            // 경로 그리기
            guard trip.routePoints.count >= 2 else { return }

            ctx.setStrokeColor(UIColor.systemBlue.cgColor)
            ctx.setLineWidth(4)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)

            let firstCoord = CLLocationCoordinate2D(
                latitude: trip.routePoints[0].latitude,
                longitude: trip.routePoints[0].longitude
            )
            let firstPoint = snapshot.point(for: firstCoord)
            ctx.move(to: firstPoint)

            for i in 1..<trip.routePoints.count {
                let coord = CLLocationCoordinate2D(
                    latitude: trip.routePoints[i].latitude,
                    longitude: trip.routePoints[i].longitude
                )
                let point = snapshot.point(for: coord)
                ctx.addLine(to: point)
            }
            ctx.strokePath()

            // 출발 마커 (녹색) - 안전한 배열 접근
            if let firstPoint = trip.routePoints.first {
                let startCoord = CLLocationCoordinate2D(
                    latitude: firstPoint.latitude,
                    longitude: firstPoint.longitude
                )
                let startPoint = snapshot.point(for: startCoord)
                ctx.setFillColor(UIColor.systemGreen.cgColor)
                ctx.fillEllipse(in: CGRect(x: startPoint.x - 8, y: startPoint.y - 8, width: 16, height: 16))
                // 흰색 테두리
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.setLineWidth(2)
                ctx.strokeEllipse(in: CGRect(x: startPoint.x - 8, y: startPoint.y - 8, width: 16, height: 16))
            }

            // 도착 마커 (빨간색) - 안전한 배열 접근
            if let lastPoint = trip.routePoints.last {
                let endCoord = CLLocationCoordinate2D(
                    latitude: lastPoint.latitude,
                    longitude: lastPoint.longitude
                )
                let endPoint = snapshot.point(for: endCoord)
                ctx.setFillColor(UIColor.systemRed.cgColor)
                ctx.fillEllipse(in: CGRect(x: endPoint.x - 8, y: endPoint.y - 8, width: 16, height: 16))
                // 흰색 테두리
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.setLineWidth(2)
                ctx.strokeEllipse(in: CGRect(x: endPoint.x - 8, y: endPoint.y - 8, width: 16, height: 16))
            }
        }
    }

    @MainActor
    private func saveToPhotoLibrary(image: UIImage) async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        switch status {
        case .authorized, .limited:
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            saveAlertMessage = "영수증이 사진첩에 저장되었습니다."
        case .denied, .restricted:
            saveAlertMessage = "사진첩 접근 권한이 없습니다.\n설정에서 권한을 허용해주세요."
        case .notDetermined:
            saveAlertMessage = "사진첩 접근 권한이 필요합니다."
        @unknown default:
            saveAlertMessage = "알 수 없는 오류가 발생했습니다."
        }

        showSaveAlert = true
        isSaving = false
    }
}

#Preview {
    let sampleTrip = Trip(
        id: UUID(),
        startTime: Date().addingTimeInterval(-1800),
        endTime: Date(),
        totalFare: 15000,
        distance: 10.0,
        duration: 1800,
        startRegion: "서울",
        endRegion: "경기",
        regionChanges: 1,
        isNightTrip: false,
        fareBreakdown: FareBreakdown(
            baseFare: 4800,
            distanceFare: 8000,
            timeFare: 1000,
            regionSurcharge: 1000,
            nightSurcharge: 0
        )
    )

    ReceiptView(trip: sampleTrip)
}

// MARK: - Receipt Image Generator (Core Graphics 기반, 빠름)

/// Core Graphics로 영수증 이미지를 직접 그리는 생성기
private enum ReceiptImageGenerator {

    static func generate(from trip: Trip, mapSnapshot: UIImage? = nil) -> UIImage {
        let width: CGFloat = 320
        let hasRoute = !trip.routePoints.isEmpty
        let hasDriverQuote = trip.driverQuote.map { !$0.isEmpty } ?? false
        let routeMapHeight: CGFloat = hasRoute ? 140 : 0
        let driverQuoteHeight: CGFloat = hasDriverQuote ? 25 : 0
        let height: CGFloat = 520 + routeMapHeight + driverQuoteHeight
        let padding: CGFloat = 20

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )

        return renderer.image { context in
            let ctx = context.cgContext

            // 배경
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

            var y: CGFloat = padding

            y = drawHeader(width: width, y: y)
            y = drawDivider(in: ctx, width: width, padding: padding, y: y)

            // 경로 지도 (있으면 그리기)
            if hasRoute {
                y = drawRouteMap(in: ctx, trip: trip, width: width, padding: padding, y: y, mapSnapshot: mapSnapshot)
                y = drawDivider(in: ctx, width: width, padding: padding, y: y)
            }

            y = drawTimeInfo(trip: trip, width: width, padding: padding, y: y)
            y = drawDivider(in: ctx, width: width, padding: padding, y: y)
            y = drawFareBreakdown(in: ctx, trip: trip, width: width, padding: padding, y: y)
            y = drawDivider(in: ctx, width: width, padding: padding, y: y)
            y = drawTotal(in: ctx, trip: trip, width: width, padding: padding, y: y)
            y = drawDivider(in: ctx, width: width, padding: padding, y: y)
            _ = drawSlogan(trip: trip, width: width, y: y)
        }
    }

    private static func drawHeader(width: CGFloat, y: CGFloat) -> CGFloat {
        var currentY = y

        let emoji = "🏇" as NSString
        let emojiAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 40)]
        let emojiSize = emoji.size(withAttributes: emojiAttr)
        emoji.draw(at: CGPoint(x: (width - emojiSize.width) / 2, y: currentY), withAttributes: emojiAttr)
        currentY += emojiSize.height + 8

        let title = "호구미터" as NSString
        let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.black]
        let titleSize = title.size(withAttributes: titleAttr)
        title.draw(at: CGPoint(x: (width - titleSize.width) / 2, y: currentY), withAttributes: titleAttr)
        currentY += titleSize.height + 4

        let subtitle = "TAXI FARE RECEIPT" as NSString
        let subtitleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.gray]
        let subtitleSize = subtitle.size(withAttributes: subtitleAttr)
        subtitle.draw(at: CGPoint(x: (width - subtitleSize.width) / 2, y: currentY), withAttributes: subtitleAttr)

        return currentY + subtitleSize.height + 10
    }

    private static func drawDivider(in ctx: CGContext, width: CGFloat, padding: CGFloat, y: CGFloat) -> CGFloat {
        ctx.setStrokeColor(UIColor.lightGray.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: padding, y: y + 10))
        ctx.addLine(to: CGPoint(x: width - padding, y: y + 10))
        ctx.strokePath()
        return y + 20
    }

    private static func drawRouteMap(in ctx: CGContext, trip: Trip, width: CGFloat, padding: CGFloat, y: CGFloat, mapSnapshot: UIImage? = nil) -> CGFloat {
        let mapWidth = width - padding * 2
        let mapHeight: CGFloat = 120
        let mapRect = CGRect(x: padding, y: y, width: mapWidth, height: mapHeight)

        // 지도 스냅샷이 있으면 그리기 (스냅샷에 이미 경로가 포함됨)
        if let snapshot = mapSnapshot {
            snapshot.draw(in: mapRect)

            // 테두리
            ctx.setStrokeColor(UIColor.systemGray4.cgColor)
            ctx.setLineWidth(1)
            ctx.stroke(mapRect)

            // "주행 경로" 라벨
            let routeLabel = "주행 경로" as NSString
            let routeLabelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
            routeLabel.draw(at: CGPoint(x: padding + 5, y: y + 5), withAttributes: routeLabelAttr)

            return y + mapHeight + 10
        }

        // 스냅샷이 없으면 회색 배경에 수동으로 경로 그리기 (폴백)
        ctx.setFillColor(UIColor.systemGray6.cgColor)
        ctx.fill(mapRect)

        // 테두리
        ctx.setStrokeColor(UIColor.systemGray4.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(mapRect)

        guard trip.routePoints.count >= 2 else {
            // 포인트가 부족하면 "경로 없음" 표시
            let noRoute = "경로 정보 없음" as NSString
            let noRouteAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray]
            let noRouteSize = noRoute.size(withAttributes: noRouteAttr)
            noRoute.draw(at: CGPoint(x: padding + (mapWidth - noRouteSize.width) / 2, y: y + (mapHeight - noRouteSize.height) / 2), withAttributes: noRouteAttr)
            return y + mapHeight + 10
        }

        // 좌표 범위 계산
        let lats = trip.routePoints.map { $0.latitude }
        let lons = trip.routePoints.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return y + mapHeight + 10
        }

        // 여백 추가
        let latRange = max(maxLat - minLat, 0.001) * 1.2
        let lonRange = max(maxLon - minLon, 0.001) * 1.2
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        // 좌표를 화면 좌표로 변환하는 함수 (폴백용)
        func toScreenPoint(lat: Double, lon: Double) -> CGPoint {
            let x = padding + 10 + ((lon - (centerLon - lonRange / 2)) / lonRange) * (mapWidth - 20)
            let y_coord = y + mapHeight - 10 - ((lat - (centerLat - latRange / 2)) / latRange) * (mapHeight - 20)
            return CGPoint(x: x, y: y_coord)
        }

        // 경로 그리기
        ctx.setStrokeColor(UIColor.systemBlue.cgColor)
        ctx.setLineWidth(3)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        let firstPoint = toScreenPoint(lat: trip.routePoints[0].latitude, lon: trip.routePoints[0].longitude)
        ctx.move(to: firstPoint)

        for i in 1..<trip.routePoints.count {
            let point = toScreenPoint(lat: trip.routePoints[i].latitude, lon: trip.routePoints[i].longitude)
            ctx.addLine(to: point)
        }
        ctx.strokePath()

        // 출발/도착 마커 - 안전한 배열 접근
        if let firstRoutePoint = trip.routePoints.first {
            let startPoint = toScreenPoint(lat: firstRoutePoint.latitude, lon: firstRoutePoint.longitude)
            // 출발 마커 (녹색)
            ctx.setFillColor(UIColor.systemGreen.cgColor)
            ctx.fillEllipse(in: CGRect(x: startPoint.x - 5, y: startPoint.y - 5, width: 10, height: 10))
        }

        if let lastRoutePoint = trip.routePoints.last {
            let endPoint = toScreenPoint(lat: lastRoutePoint.latitude, lon: lastRoutePoint.longitude)
            // 도착 마커 (빨간색)
            ctx.setFillColor(UIColor.systemRed.cgColor)
            ctx.fillEllipse(in: CGRect(x: endPoint.x - 5, y: endPoint.y - 5, width: 10, height: 10))
        }

        // "주행 경로" 라벨
        let routeLabel = "주행 경로" as NSString
        let routeLabelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
        routeLabel.draw(at: CGPoint(x: padding + 5, y: y + 5), withAttributes: routeLabelAttr)

        return y + mapHeight + 10
    }

    private static func drawTimeInfo(trip: Trip, width: CGFloat, padding: CGFloat, y: CGFloat) -> CGFloat {
        var currentY = y

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "ko_KR")

        let items = [
            ("출발", formatter.string(from: trip.startTime)),
            ("도착", formatter.string(from: trip.endTime)),
            ("날짜", dateFormatter.string(from: trip.startTime)),
            ("소요", formatDuration(trip.duration))
        ]

        for (label, value) in items {
            currentY = drawRow(label: label, value: value, width: width, padding: padding, y: currentY)
        }
        return currentY
    }

    private static func drawFareBreakdown(in ctx: CGContext, trip: Trip, width: CGFloat, padding: CGFloat, y: CGFloat) -> CGFloat {
        var currentY = y

        let sectionTitle = "요금 내역" as NSString
        let sectionAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black]
        sectionTitle.draw(at: CGPoint(x: padding, y: currentY), withAttributes: sectionAttr)
        currentY += 22

        currentY = drawRow(label: "기본요금", value: "\(trip.fareBreakdown.baseFare.formattedWithComma)원", width: width, padding: padding, y: currentY)
        if trip.fareBreakdown.distanceFare > 0 {
            currentY = drawRow(label: "거리요금", value: "\(trip.fareBreakdown.distanceFare.formattedWithComma)원", width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.timeFare > 0 {
            currentY = drawRow(label: "시간요금", value: "\(trip.fareBreakdown.timeFare.formattedWithComma)원", width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.regionSurcharge > 0 {
            currentY = drawRow(label: "지역할증", value: "\(trip.fareBreakdown.regionSurcharge.formattedWithComma)원", width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.nightSurcharge > 0 {
            currentY = drawRow(label: "야간할증", value: "\(trip.fareBreakdown.nightSurcharge.formattedWithComma)원", width: width, padding: padding, y: currentY)
        }
        return currentY
    }

    private static func drawTotal(in ctx: CGContext, trip: Trip, width: CGFloat, padding: CGFloat, y: CGFloat) -> CGFloat {
        let boxRect = CGRect(x: padding, y: y, width: width - padding * 2, height: 40)
        ctx.setFillColor(UIColor.systemBlue.withAlphaComponent(0.1).cgColor)
        ctx.fill(boxRect)

        let label = "총 요금" as NSString
        let labelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.black]
        label.draw(at: CGPoint(x: padding + 12, y: y + 10), withAttributes: labelAttr)

        let value = "\(trip.totalFare.formattedWithComma)원" as NSString
        let valueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.black]
        let valueSize = value.size(withAttributes: valueAttr)
        value.draw(at: CGPoint(x: width - padding - 12 - valueSize.width, y: y + 9), withAttributes: valueAttr)

        return y + 50
    }

    private static func drawSlogan(trip: Trip, width: CGFloat, y: CGFloat) -> CGFloat {
        var currentY = y

        // 택시기사 한마디 (있으면 표시)
        if let quote = trip.driverQuote, !quote.isEmpty {
            let quoteText = "🚕 \"\(quote)\"" as NSString
            let quoteAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
            let quoteSize = quoteText.size(withAttributes: quoteAttr)
            quoteText.draw(at: CGPoint(x: (width - quoteSize.width) / 2, y: currentY), withAttributes: quoteAttr)
            currentY += quoteSize.height + 10
        }

        let emoji = "🚖" as NSString
        let emojiAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24)]
        let emojiSize = emoji.size(withAttributes: emojiAttr)
        emoji.draw(at: CGPoint(x: (width - emojiSize.width) / 2, y: currentY), withAttributes: emojiAttr)
        currentY += emojiSize.height + 6

        let slogan = "내 차 탔으면 내놔" as NSString
        let sloganAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black]
        let sloganSize = slogan.size(withAttributes: sloganAttr)
        slogan.draw(at: CGPoint(x: (width - sloganSize.width) / 2, y: currentY), withAttributes: sloganAttr)
        currentY += sloganSize.height + 4

        let thanks = "Thank you for using HoguMeter" as NSString
        let thanksAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.gray]
        let thanksSize = thanks.size(withAttributes: thanksAttr)
        thanks.draw(at: CGPoint(x: (width - thanksSize.width) / 2, y: currentY), withAttributes: thanksAttr)

        return currentY + thanksSize.height
    }

    private static func drawRow(label: String, value: String, width: CGFloat, padding: CGFloat, y: CGFloat) -> CGFloat {
        let labelNS = label as NSString
        let valueNS = value as NSString
        let labelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.gray]
        let valueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: UIColor.black]

        labelNS.draw(at: CGPoint(x: padding, y: y), withAttributes: labelAttr)
        let valueSize = valueNS.size(withAttributes: valueAttr)
        valueNS.draw(at: CGPoint(x: width - padding - valueSize.width, y: y), withAttributes: valueAttr)

        return y + 20
    }

    private static func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분 \(seconds)초"
        } else if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }
}
