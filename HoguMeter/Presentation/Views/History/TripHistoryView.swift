//
//  TripHistoryView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct TripHistoryView: View {
    @State private var trips: [Trip] = []
    @State private var showDeleteAlert = false
    @State private var tripToDelete: Trip?

    private let repository = TripRepository()

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
                    List {
                        ForEach(trips) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip, onDelete: {
                                    deleteTrip(trip)
                                })
                            } label: {
                                TripRowView(trip: trip)
                            }
                        }
                        .onDelete(perform: onDelete)
                    }
                }
            }
            .navigationTitle("주행 기록")
            .toolbar {
                if !trips.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .onAppear {
                loadTrips()
            }
            .refreshable {
                loadTrips()
            }
        }
    }

    private func loadTrips() {
        trips = repository.getAll()
    }

    private func deleteTrip(_ trip: Trip) {
        repository.delete(trip)
        loadTrips()
    }

    private func onDelete(at offsets: IndexSet) {
        for index in offsets {
            let trip = trips[index]
            repository.delete(trip)
        }
        loadTrips()
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
    var onDelete: (() -> Void)?

    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

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

            Section {
                Button {
                    showShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("영수증 공유")
                    }
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("기록 삭제")
                    }
                }
            }
        }
        .navigationTitle("주행 상세")
        .sheet(isPresented: $showShareSheet) {
            ReceiptView(trip: trip)
        }
        .alert("기록 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("이 주행 기록을 삭제하시겠습니까?")
        }
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
