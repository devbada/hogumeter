//
//  TemplateReceiptGenerator.swift
//  HoguMeter
//
//  Receipt image generator with template support.
//

import UIKit
import MapKit

/// 템플릿 기반 영수증 이미지 생성기
enum TemplateReceiptGenerator {

    /// 영수증 하단 워터마크 영역 높이 (브랜드 노출 + 해시태그)
    private static let watermarkHeight: CGFloat = 32

    static func generate(
        from trip: Trip,
        template: ReceiptTemplate,
        mapSnapshot: UIImage? = nil
    ) -> UIImage {
        let colors = ReceiptColorScheme.scheme(for: template)
        let width: CGFloat = 320
        let hasRoute = !trip.routePoints.isEmpty
        let hasDriverQuote = trip.driverQuote.map { !$0.isEmpty } ?? false
        let routeMapHeight: CGFloat = hasRoute ? 140 : 0
        let driverQuoteHeight: CGFloat = hasDriverQuote ? 25 : 0

        // 템플릿별 높이 조정 (+ 워터마크 영역 포함)
        let baseHeight: CGFloat = template == .minimal ? 380 : 520
        let height: CGFloat = baseHeight + routeMapHeight + driverQuoteHeight + watermarkHeight
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
            colors.backgroundColor.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

            var y: CGFloat = padding

            // 템플릿별 렌더링
            switch template {
            case .classic:
                y = drawClassicReceipt(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: y, mapSnapshot: mapSnapshot, hasRoute: hasRoute)
            case .modern:
                y = drawModernReceipt(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: y, mapSnapshot: mapSnapshot, hasRoute: hasRoute)
            case .fun:
                y = drawFunReceipt(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: y, mapSnapshot: mapSnapshot, hasRoute: hasRoute)
            case .minimal:
                y = drawMinimalReceipt(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: y)
            case .premium:
                y = drawPremiumReceipt(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: y, mapSnapshot: mapSnapshot, hasRoute: hasRoute)
            }

            // 모든 템플릿 하단에 공통 워터마크 그리기
            // 영수증 본문 끝(y) 아래쪽에 그리되, 너무 가까이 붙지 않도록 살짝 여백을 둔다.
            drawBrandWatermark(
                ctx: ctx,
                colors: colors,
                width: width,
                totalHeight: height,
                contentEndY: y
            )
        }
    }

    // MARK: - Brand Watermark (공통)

    /// 영수증 이미지 최하단에 브랜드 워터마크를 그린다.
    /// - 모든 템플릿에 동일하게 적용되며, 색상 스킴의 secondaryTextColor를 따라간다.
    /// - 영수증 본문(`contentEndY`)과 이미지 하단 사이 중앙에 정렬한다.
    private static func drawBrandWatermark(
        ctx: CGContext,
        colors: ReceiptColorScheme,
        width: CGFloat,
        totalHeight: CGFloat,
        contentEndY: CGFloat
    ) {
        let watermark = Constants.Share.watermarkText as NSString
        let watermarkAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: colors.secondaryTextColor.withAlphaComponent(0.7)
        ]
        let size = watermark.size(withAttributes: watermarkAttr)

        // 워터마크 영역의 세로 중앙에 배치
        let watermarkAreaTop = max(contentEndY, totalHeight - watermarkHeight)
        let availableHeight = totalHeight - watermarkAreaTop
        let drawY = watermarkAreaTop + (availableHeight - size.height) / 2.0
        let drawX = (width - size.width) / 2.0

        watermark.draw(at: CGPoint(x: drawX, y: drawY), withAttributes: watermarkAttr)
    }

    // MARK: - Classic Template

    private static func drawClassicReceipt(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat,
        mapSnapshot: UIImage?,
        hasRoute: Bool
    ) -> CGFloat {
        var currentY = y

        currentY = drawHeader(ctx: ctx, colors: colors, width: width, y: currentY, emoji: "🏇", title: "호구미터", subtitle: "TAXI FARE RECEIPT")
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)

        if hasRoute {
            currentY = drawRouteMap(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY, mapSnapshot: mapSnapshot)
            currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        }

        currentY = drawTimeInfo(trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawFareBreakdown(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawTotal(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawSlogan(trip: trip, colors: colors, width: width, y: currentY, mainEmoji: "🚖", slogan: "내 차 탔으면 내놔")

        return currentY
    }

    // MARK: - Modern Template

    private static func drawModernReceipt(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat,
        mapSnapshot: UIImage?,
        hasRoute: Bool
    ) -> CGFloat {
        var currentY = y

        // 모던 스타일: 심플한 텍스트 헤더
        currentY = drawHeader(ctx: ctx, colors: colors, width: width, y: currentY, emoji: nil, title: "HOGUMETER", subtitle: nil, titleSize: 24, isBold: false)
        currentY += 10
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY, thickness: 2)

        if hasRoute {
            currentY = drawRouteMap(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY, mapSnapshot: mapSnapshot)
            currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        }

        currentY = drawTimeInfo(trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawFareBreakdown(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawTotal(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawSlogan(trip: trip, colors: colors, width: width, y: currentY, mainEmoji: nil, slogan: "Thank you", subtitleOnly: true)

        return currentY
    }

    // MARK: - Fun Template

    private static func drawFunReceipt(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat,
        mapSnapshot: UIImage?,
        hasRoute: Bool
    ) -> CGFloat {
        var currentY = y

        // 재미 스타일: 큰 이모지와 재미있는 텍스트
        currentY = drawHeader(ctx: ctx, colors: colors, width: width, y: currentY, emoji: "🏇💨", title: "호구미터", subtitle: "택시비 폭탄 영수증 💣", emojiSize: 50)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY, dashed: true)

        if hasRoute {
            currentY = drawRouteMap(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY, mapSnapshot: mapSnapshot)
            currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY, dashed: true)
        }

        currentY = drawTimeInfoFun(trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY, dashed: true)
        currentY = drawFareBreakdownFun(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY, dashed: true)
        currentY = drawTotal(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY, prefix: "💰 ")
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY, dashed: true)
        currentY = drawSlogan(trip: trip, colors: colors, width: width, y: currentY, mainEmoji: "🚕💨", slogan: "내 차 탔으면 내놔! 😤")

        return currentY
    }

    // MARK: - Minimal Template

    private static func drawMinimalReceipt(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat
    ) -> CGFloat {
        var currentY = y

        // 미니멀 스타일: 필수 정보만
        let title = "HoguMeter" as NSString
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .light),
            .foregroundColor: colors.primaryTextColor
        ]
        let titleSize = title.size(withAttributes: titleAttr)
        title.draw(at: CGPoint(x: (width - titleSize.width) / 2, y: currentY), withAttributes: titleAttr)
        currentY += titleSize.height + 30

        // 날짜
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        let dateStr = dateFormatter.string(from: trip.startTime) as NSString
        let dateAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: colors.secondaryTextColor
        ]
        let dateSize = dateStr.size(withAttributes: dateAttr)
        dateStr.draw(at: CGPoint(x: (width - dateSize.width) / 2, y: currentY), withAttributes: dateAttr)
        currentY += dateSize.height + 40

        // 총 요금 (크게)
        let fareStr = "\(trip.totalFare.formattedWithComma)원" as NSString
        let fareAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: colors.primaryTextColor
        ]
        let fareSize = fareStr.size(withAttributes: fareAttr)
        fareStr.draw(at: CGPoint(x: (width - fareSize.width) / 2, y: currentY), withAttributes: fareAttr)
        currentY += fareSize.height + 20

        // 거리/시간 요약
        let summaryStr = String(format: "%.1fkm · %@", trip.distance, formatDuration(trip.duration)) as NSString
        let summaryAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: colors.secondaryTextColor
        ]
        let summarySize = summaryStr.size(withAttributes: summaryAttr)
        summaryStr.draw(at: CGPoint(x: (width - summarySize.width) / 2, y: currentY), withAttributes: summaryAttr)
        currentY += summarySize.height + 10

        // 출발 → 도착
        let routeStr = "\(trip.startRegion) → \(trip.endRegion)" as NSString
        let routeAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: colors.secondaryTextColor
        ]
        let routeSize = routeStr.size(withAttributes: routeAttr)
        routeStr.draw(at: CGPoint(x: (width - routeSize.width) / 2, y: currentY), withAttributes: routeAttr)

        return currentY + routeSize.height + 40
    }

    // MARK: - Premium Template

    private static func drawPremiumReceipt(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat,
        mapSnapshot: UIImage?,
        hasRoute: Bool
    ) -> CGFloat {
        var currentY = y

        // 프리미엄 스타일: 골드 테마
        currentY = drawPremiumHeader(ctx: ctx, colors: colors, width: width, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)

        if hasRoute {
            currentY = drawRouteMap(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY, mapSnapshot: mapSnapshot)
            currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        }

        currentY = drawTimeInfo(trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawFareBreakdown(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawTotal(ctx: ctx, trip: trip, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawDivider(ctx: ctx, colors: colors, width: width, padding: padding, y: currentY)
        currentY = drawSlogan(trip: trip, colors: colors, width: width, y: currentY, mainEmoji: "👑", slogan: "Premium Ride")

        return currentY
    }

    private static func drawPremiumHeader(
        ctx: CGContext,
        colors: ReceiptColorScheme,
        width: CGFloat,
        y: CGFloat
    ) -> CGFloat {
        var currentY = y

        // 왕관 이모지
        let crown = "👑" as NSString
        let crownAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 36)]
        let crownSize = crown.size(withAttributes: crownAttr)
        crown.draw(at: CGPoint(x: (width - crownSize.width) / 2, y: currentY), withAttributes: crownAttr)
        currentY += crownSize.height + 8

        // 타이틀
        let title = "HOGUMETER" as NSString
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: colors.accentColor
        ]
        let titleSize = title.size(withAttributes: titleAttr)
        title.draw(at: CGPoint(x: (width - titleSize.width) / 2, y: currentY), withAttributes: titleAttr)
        currentY += titleSize.height + 4

        // 서브타이틀
        let subtitle = "PREMIUM RECEIPT" as NSString
        let subtitleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: colors.secondaryTextColor
        ]
        let subtitleSize = subtitle.size(withAttributes: subtitleAttr)
        subtitle.draw(at: CGPoint(x: (width - subtitleSize.width) / 2, y: currentY), withAttributes: subtitleAttr)

        return currentY + subtitleSize.height + 10
    }

    // MARK: - Shared Drawing Functions

    private static func drawHeader(
        ctx: CGContext,
        colors: ReceiptColorScheme,
        width: CGFloat,
        y: CGFloat,
        emoji: String?,
        title: String,
        subtitle: String?,
        emojiSize: CGFloat = 40,
        titleSize: CGFloat = 22,
        isBold: Bool = true
    ) -> CGFloat {
        var currentY = y

        // 이모지
        if let emoji = emoji {
            let emojiNS = emoji as NSString
            let emojiAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: emojiSize)]
            let size = emojiNS.size(withAttributes: emojiAttr)
            emojiNS.draw(at: CGPoint(x: (width - size.width) / 2, y: currentY), withAttributes: emojiAttr)
            currentY += size.height + 8
        }

        // 타이틀
        let titleNS = title as NSString
        let titleFont = isBold ? UIFont.boldSystemFont(ofSize: titleSize) : UIFont.systemFont(ofSize: titleSize, weight: .light)
        let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: colors.primaryTextColor]
        let titleSizeVal = titleNS.size(withAttributes: titleAttr)
        titleNS.draw(at: CGPoint(x: (width - titleSizeVal.width) / 2, y: currentY), withAttributes: titleAttr)
        currentY += titleSizeVal.height + 4

        // 서브타이틀
        if let subtitle = subtitle {
            let subtitleNS = subtitle as NSString
            let subtitleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: colors.secondaryTextColor]
            let subtitleSize = subtitleNS.size(withAttributes: subtitleAttr)
            subtitleNS.draw(at: CGPoint(x: (width - subtitleSize.width) / 2, y: currentY), withAttributes: subtitleAttr)
            currentY += subtitleSize.height
        }

        return currentY + 10
    }

    private static func drawDivider(
        ctx: CGContext,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat,
        thickness: CGFloat = 0.5,
        dashed: Bool = false
    ) -> CGFloat {
        ctx.setStrokeColor(colors.dividerColor.cgColor)
        ctx.setLineWidth(thickness)

        if dashed {
            ctx.setLineDash(phase: 0, lengths: [4, 4])
        } else {
            ctx.setLineDash(phase: 0, lengths: [])
        }

        ctx.move(to: CGPoint(x: padding, y: y + 10))
        ctx.addLine(to: CGPoint(x: width - padding, y: y + 10))
        ctx.strokePath()

        return y + 20
    }

    private static func drawRouteMap(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat,
        mapSnapshot: UIImage?
    ) -> CGFloat {
        let mapWidth = width - padding * 2
        let mapHeight: CGFloat = 120
        let mapRect = CGRect(x: padding, y: y, width: mapWidth, height: mapHeight)

        if let snapshot = mapSnapshot {
            snapshot.draw(in: mapRect)
            ctx.setStrokeColor(colors.dividerColor.cgColor)
            ctx.setLineWidth(1)
            ctx.stroke(mapRect)

            let routeLabel = "주행 경로" as NSString
            let routeLabelAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: colors.secondaryTextColor
            ]
            routeLabel.draw(at: CGPoint(x: padding + 5, y: y + 5), withAttributes: routeLabelAttr)

            return y + mapHeight + 10
        }

        // 폴백: 그레이 배경
        colors.highlightBackgroundColor.setFill()
        ctx.fill(mapRect)
        ctx.setStrokeColor(colors.dividerColor.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(mapRect)

        guard trip.routePoints.count >= 2 else {
            let noRoute = "경로 정보 없음" as NSString
            let noRouteAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: colors.secondaryTextColor
            ]
            let noRouteSize = noRoute.size(withAttributes: noRouteAttr)
            noRoute.draw(at: CGPoint(x: padding + (mapWidth - noRouteSize.width) / 2, y: y + (mapHeight - noRouteSize.height) / 2), withAttributes: noRouteAttr)
            return y + mapHeight + 10
        }

        // 경로 그리기 (폴백)
        drawRoutePath(ctx: ctx, trip: trip, mapRect: mapRect, colors: colors)

        let routeLabel = "주행 경로" as NSString
        let routeLabelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: colors.secondaryTextColor
        ]
        routeLabel.draw(at: CGPoint(x: padding + 5, y: y + 5), withAttributes: routeLabelAttr)

        return y + mapHeight + 10
    }

    private static func drawRoutePath(
        ctx: CGContext,
        trip: Trip,
        mapRect: CGRect,
        colors: ReceiptColorScheme
    ) {
        let points = trip.routePoints
        guard points.count >= 2 else { return }

        let lats = points.map { $0.latitude }
        let lons = points.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }

        let latRange = max(maxLat - minLat, 0.001) * 1.2
        let lonRange = max(maxLon - minLon, 0.001) * 1.2
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        func toScreenPoint(lat: Double, lon: Double) -> CGPoint {
            let x = mapRect.minX + 10 + ((lon - (centerLon - lonRange / 2)) / lonRange) * (mapRect.width - 20)
            let y = mapRect.maxY - 10 - ((lat - (centerLat - latRange / 2)) / latRange) * (mapRect.height - 20)
            return CGPoint(x: x, y: y)
        }

        ctx.setStrokeColor(colors.accentColor.cgColor)
        ctx.setLineWidth(3)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        let firstPoint = toScreenPoint(lat: points[0].latitude, lon: points[0].longitude)
        ctx.move(to: firstPoint)

        for i in 1..<points.count {
            let point = toScreenPoint(lat: points[i].latitude, lon: points[i].longitude)
            ctx.addLine(to: point)
        }
        ctx.strokePath()

        // 마커
        if let firstRoutePoint = points.first {
            let startPoint = toScreenPoint(lat: firstRoutePoint.latitude, lon: firstRoutePoint.longitude)
            ctx.setFillColor(UIColor.systemGreen.cgColor)
            ctx.fillEllipse(in: CGRect(x: startPoint.x - 5, y: startPoint.y - 5, width: 10, height: 10))
        }

        if let lastRoutePoint = points.last {
            let endPoint = toScreenPoint(lat: lastRoutePoint.latitude, lon: lastRoutePoint.longitude)
            ctx.setFillColor(UIColor.systemRed.cgColor)
            ctx.fillEllipse(in: CGRect(x: endPoint.x - 5, y: endPoint.y - 5, width: 10, height: 10))
        }
    }

    private static func drawTimeInfo(
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat
    ) -> CGFloat {
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
            currentY = drawRow(label: label, value: value, colors: colors, width: width, padding: padding, y: currentY)
        }
        return currentY
    }

    private static func drawTimeInfoFun(
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat
    ) -> CGFloat {
        var currentY = y

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.locale = Locale(identifier: "ko_KR")

        let items = [
            ("🚦 출발", formatter.string(from: trip.startTime)),
            ("🏁 도착", formatter.string(from: trip.endTime)),
            ("📅 날짜", dateFormatter.string(from: trip.startTime)),
            ("⏱️ 소요", formatDuration(trip.duration))
        ]

        for (label, value) in items {
            currentY = drawRow(label: label, value: value, colors: colors, width: width, padding: padding, y: currentY)
        }
        return currentY
    }

    private static func drawFareBreakdown(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat
    ) -> CGFloat {
        var currentY = y

        let sectionTitle = "요금 내역" as NSString
        let sectionAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: colors.primaryTextColor
        ]
        sectionTitle.draw(at: CGPoint(x: padding, y: currentY), withAttributes: sectionAttr)
        currentY += 22

        currentY = drawRow(label: "기본요금 (2km)", value: "\(trip.fareBreakdown.baseFare.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        if trip.fareBreakdown.distanceFare > 0 {
            currentY = drawRow(label: "거리요금 (\(String(format: "%.1fkm", trip.distance)))", value: "\(trip.fareBreakdown.distanceFare.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.timeFare > 0 {
            currentY = drawRow(label: "시간요금", value: "\(trip.fareBreakdown.timeFare.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.regionSurcharge > 0 {
            let regionDetail = trip.isRealisticMode ? trip.surchargeRateDisplay : "\(trip.regionChanges)회"
            currentY = drawRow(label: "지역할증 (\(regionDetail))", value: "\(trip.fareBreakdown.regionSurcharge.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.nightSurcharge > 0 {
            currentY = drawRow(label: "야간할증 (20%)", value: "\(trip.fareBreakdown.nightSurcharge.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        return currentY
    }

    private static func drawFareBreakdownFun(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat
    ) -> CGFloat {
        var currentY = y

        let sectionTitle = "💸 요금 내역" as NSString
        let sectionAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: colors.primaryTextColor
        ]
        sectionTitle.draw(at: CGPoint(x: padding, y: currentY), withAttributes: sectionAttr)
        currentY += 22

        currentY = drawRow(label: "🚖 기본요금 (2km)", value: "\(trip.fareBreakdown.baseFare.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        if trip.fareBreakdown.distanceFare > 0 {
            currentY = drawRow(label: "📏 거리요금 (\(String(format: "%.1fkm", trip.distance)))", value: "\(trip.fareBreakdown.distanceFare.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.timeFare > 0 {
            currentY = drawRow(label: "⏰ 시간요금", value: "\(trip.fareBreakdown.timeFare.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.regionSurcharge > 0 {
            let regionDetail = trip.isRealisticMode ? trip.surchargeRateDisplay : "\(trip.regionChanges)회"
            currentY = drawRow(label: "📍 지역할증 (\(regionDetail))", value: "\(trip.fareBreakdown.regionSurcharge.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        if trip.fareBreakdown.nightSurcharge > 0 {
            currentY = drawRow(label: "🌙 야간할증 (20%)", value: "\(trip.fareBreakdown.nightSurcharge.formattedWithComma)원", colors: colors, width: width, padding: padding, y: currentY)
        }
        return currentY
    }

    private static func drawTotal(
        ctx: CGContext,
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat,
        prefix: String = ""
    ) -> CGFloat {
        let boxRect = CGRect(x: padding, y: y, width: width - padding * 2, height: 40)
        colors.highlightBackgroundColor.setFill()
        ctx.fill(boxRect)

        let label = "\(prefix)총 요금" as NSString
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: colors.primaryTextColor
        ]
        label.draw(at: CGPoint(x: padding + 12, y: y + 10), withAttributes: labelAttr)

        let value = "\(trip.totalFare.formattedWithComma)원" as NSString
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: colors.primaryTextColor
        ]
        let valueSize = value.size(withAttributes: valueAttr)
        value.draw(at: CGPoint(x: width - padding - 12 - valueSize.width, y: y + 9), withAttributes: valueAttr)

        return y + 50
    }

    private static func drawSlogan(
        trip: Trip,
        colors: ReceiptColorScheme,
        width: CGFloat,
        y: CGFloat,
        mainEmoji: String?,
        slogan: String,
        subtitleOnly: Bool = false
    ) -> CGFloat {
        var currentY = y

        // 택시기사 한마디
        if let quote = trip.driverQuote, !quote.isEmpty {
            let quoteText = "🚕 \"\(quote)\"" as NSString
            let quoteAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: colors.secondaryTextColor
            ]
            let quoteSize = quoteText.size(withAttributes: quoteAttr)
            quoteText.draw(at: CGPoint(x: (width - quoteSize.width) / 2, y: currentY), withAttributes: quoteAttr)
            currentY += quoteSize.height + 10
        }

        if let emoji = mainEmoji {
            let emojiNS = emoji as NSString
            let emojiAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24)]
            let emojiSize = emojiNS.size(withAttributes: emojiAttr)
            emojiNS.draw(at: CGPoint(x: (width - emojiSize.width) / 2, y: currentY), withAttributes: emojiAttr)
            currentY += emojiSize.height + 6
        }

        if !subtitleOnly {
            let sloganNS = slogan as NSString
            let sloganAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: colors.primaryTextColor
            ]
            let sloganSize = sloganNS.size(withAttributes: sloganAttr)
            sloganNS.draw(at: CGPoint(x: (width - sloganSize.width) / 2, y: currentY), withAttributes: sloganAttr)
            currentY += sloganSize.height + 4
        }

        let thanks = subtitleOnly ? slogan : "Thank you for using HoguMeter"
        let thanksNS = thanks as NSString
        let thanksAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: colors.secondaryTextColor
        ]
        let thanksSize = thanksNS.size(withAttributes: thanksAttr)
        thanksNS.draw(at: CGPoint(x: (width - thanksSize.width) / 2, y: currentY), withAttributes: thanksAttr)

        return currentY + thanksSize.height
    }

    private static func drawRow(
        label: String,
        value: String,
        colors: ReceiptColorScheme,
        width: CGFloat,
        padding: CGFloat,
        y: CGFloat
    ) -> CGFloat {
        let labelNS = label as NSString
        let valueNS = value as NSString
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: colors.secondaryTextColor
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: colors.primaryTextColor
        ]

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
