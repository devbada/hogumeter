//
//  TripHistoryView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct TripHistoryView: View {
    @State private var trips: [Trip] = []

    var body: some View {
        NavigationView {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "주행 기록 없음",
                        systemImage: "clock",
                        description: Text("아직 저장된 주행 기록이 없습니다")
                    )
                } else {
                    List(trips) { trip in
                        NavigationLink {
                            TripDetailView(trip: trip)
                        } label: {
                            TripRowView(trip: trip)
                        }
                    }
                }
            }
            .navigationTitle("주행 기록")
        }
    }
}

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formattedDate)
                    .font(.headline)
                Spacer()
                Text("\(trip.totalFare)원")
                    .font(.headline)
                    .foregroundColor(.green)
            }

            HStack {
                Text("\(String(format: "%.1f", trip.distance)) km")
                Text("•")
                Text(formattedDuration)
                Text("•")
                Text("\(trip.startRegion) → \(trip.endRegion)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: trip.startTime)
    }

    private var formattedDuration: String {
        let minutes = Int(trip.duration) / 60
        return "\(minutes)분"
    }
}

struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        List {
            Section("기본 정보") {
                LabeledContent("출발", value: trip.startRegion)
                LabeledContent("도착", value: trip.endRegion)
                LabeledContent("거리", value: "\(String(format: "%.1f", trip.distance)) km")
                LabeledContent("시간", value: formattedDuration)
            }

            Section("요금 내역") {
                LabeledContent("기본요금", value: "\(trip.fareBreakdown.baseFare)원")
                LabeledContent("거리요금", value: "\(trip.fareBreakdown.distanceFare)원")
                LabeledContent("시간요금", value: "\(trip.fareBreakdown.timeFare)원")
                if trip.fareBreakdown.regionSurcharge > 0 {
                    LabeledContent("지역할증", value: "\(trip.fareBreakdown.regionSurcharge)원")
                }
                if trip.fareBreakdown.nightSurcharge > 0 {
                    LabeledContent("야간할증", value: "\(trip.fareBreakdown.nightSurcharge)원")
                }
                LabeledContent("총 요금", value: "\(trip.fareBreakdown.totalFare)원")
                    .bold()
            }
        }
        .navigationTitle("주행 상세")
    }

    private var formattedDuration: String {
        let hours = Int(trip.duration) / 3600
        let minutes = (Int(trip.duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

#Preview {
    TripHistoryView()
}
