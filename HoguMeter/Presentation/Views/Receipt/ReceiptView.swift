//
//  ReceiptView.swift
//  HoguMeter
//
//  Created on 2025-12-09.
//

import SwiftUI
import Photos

/// 주행 완료 후 영수증을 표시하는 뷰
struct ReceiptView: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @State private var receiptImage: UIImage?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    receiptHeader

                    Divider()
                        .padding(.vertical, 20)

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

                    Spacer(minLength: 40)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        captureReceipt()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Image(systemName: "camera")
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("영수증 저장", isPresented: $showSaveAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
            }
        }
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
                    detail: "\(trip.regionChanges)회"
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
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }

    // MARK: - Capture Action
    @MainActor
    private func captureReceipt() {
        isSaving = true

        // Core Graphics로 직접 그리기 (가장 빠름)
        let image = ReceiptImageGenerator.generate(from: trip)

        // 사진첩에 저장
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    saveAlertMessage = "영수증이 사진첩에 저장되었습니다."
                    showSaveAlert = true
                case .denied, .restricted:
                    saveAlertMessage = "사진첩 접근 권한이 없습니다.\n설정에서 권한을 허용해주세요."
                    showSaveAlert = true
                case .notDetermined:
                    saveAlertMessage = "사진첩 접근 권한이 필요합니다."
                    showSaveAlert = true
                @unknown default:
                    saveAlertMessage = "알 수 없는 오류가 발생했습니다."
                    showSaveAlert = true
                }
                isSaving = false
            }
        }
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

    static func generate(from trip: Trip) -> UIImage {
        let width: CGFloat = 320
        let hasRoute = !trip.routePoints.isEmpty
        let hasDriverQuote = trip.driverQuote != nil && !trip.driverQuote!.isEmpty
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
                y = drawRouteMap(in: ctx, trip: trip, width: width, padding: padding, y: y)
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

    private static func drawRouteMap(in ctx: CGContext, trip: Trip, width: CGFloat, padding: CGFloat, y: CGFloat) -> CGFloat {
        let mapWidth = width - padding * 2
        let mapHeight: CGFloat = 120
        let mapRect = CGRect(x: padding, y: y, width: mapWidth, height: mapHeight)

        // 배경 (연한 회색)
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

        // 좌표를 화면 좌표로 변환하는 함수
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

        // 출발/도착 마커
        let startPoint = toScreenPoint(lat: trip.routePoints.first!.latitude, lon: trip.routePoints.first!.longitude)
        let endPoint = toScreenPoint(lat: trip.routePoints.last!.latitude, lon: trip.routePoints.last!.longitude)

        // 출발 마커 (녹색)
        ctx.setFillColor(UIColor.systemGreen.cgColor)
        ctx.fillEllipse(in: CGRect(x: startPoint.x - 5, y: startPoint.y - 5, width: 10, height: 10))

        // 도착 마커 (빨간색)
        ctx.setFillColor(UIColor.systemRed.cgColor)
        ctx.fillEllipse(in: CGRect(x: endPoint.x - 5, y: endPoint.y - 5, width: 10, height: 10))

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
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes)분 \(seconds)초" : "\(seconds)초"
    }
}
