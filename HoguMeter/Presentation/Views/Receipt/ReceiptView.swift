//
//  ReceiptView.swift
//  HoguMeter
//
//  Created on 2025-12-09.
//

import SwiftUI

/// 주행 완료 후 영수증을 표시하는 뷰
struct ReceiptView: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var receiptImage: UIImage?
    @State private var isGeneratingImage = false

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
                        shareReceipt()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = receiptImage {
                    ShareSheet(items: [image])
                }
            }
            .onAppear {
                // 영수증이 표시되면 미리 이미지 생성 (백그라운드에서)
                prepareImage()
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
            Text("\(trip.totalFare)원")
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
            Text("\(value)원")
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

    // MARK: - Image Preparation
    @MainActor
    private func prepareImage() {
        guard receiptImage == nil, !isGeneratingImage else { return }

        isGeneratingImage = true
        receiptImage = generateReceiptImage()
        isGeneratingImage = false
    }

    @MainActor
    private func generateReceiptImage() -> UIImage {
        let receiptContent = VStack(spacing: 0) {
            receiptHeader
            Divider().padding(.vertical, 15)
            timeSection
            Divider().padding(.vertical, 15)
            fareBreakdownSection
            Divider().padding(.vertical, 15)
            totalFareSection
            Divider().padding(.vertical, 15)
            sloganSection
        }
        .padding(25)
        .frame(width: 350)
        .background(Color.white)

        return receiptContent.snapshot(size: CGSize(width: 350, height: 600))
    }

    // MARK: - Share Action
    @MainActor
    private func shareReceipt() {
        // 이미지가 없으면 생성
        if receiptImage == nil {
            receiptImage = generateReceiptImage()
        }
        showShareSheet = true
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
