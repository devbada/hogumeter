//
//  TripHistoryView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct TripHistoryView: View {
    @StateObject private var viewModel = TripHistoryViewModel()
    @State private var showDeleteAllAlert = false

    // Coach Mark
    @StateObject private var coachMarkManager = CoachMarkManager.shared
    @State private var coachMarkFrames: [String: CGRect] = [:]

    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    if viewModel.trips.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "주행 기록 없음",
                            systemImage: "clock",
                            description: Text("아직 저장된 주행 기록이 없습니다")
                        )
                        .coachMarkTarget(id: "tripList")
                    } else {
                        List {
                            ForEach(Array(viewModel.trips.enumerated()), id: \.element.id) { index, trip in
                                NavigationLink {
                                    TripDetailView(
                                        tripId: trip.id,
                                        tripSummary: trip,
                                        viewModel: viewModel
                                    )
                                } label: {
                                    TripSummaryRowView(trip: trip)
                                        .onAppear {
                                            viewModel.loadNextPageIfNeeded(currentItem: trip)
                                        }
                                }
                                .if(index == 0) { view in
                                    view.coachMarkTarget(id: "tripItem")
                                }
                            }
                            .onDelete(perform: onDelete)

                            // Loading indicator for pagination
                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .coachMarkTarget(id: "tripList")
                    }
                }

                // Coach Mark 오버레이
                if coachMarkManager.isShowingCoachMark,
                   coachMarkManager.currentScreenId == "history",
                   let currentMark = coachMarkManager.currentCoachMark,
                   let frame = coachMarkFrames[currentMark.targetView] {
                    CoachMarkOverlay(
                        manager: coachMarkManager,
                        coachMark: currentMark,
                        targetFrame: frame
                    )
                }
            }
            .navigationTitle("주행 기록")
            .toolbar {
                if !viewModel.trips.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(role: .destructive) {
                            showDeleteAllAlert = true
                        } label: {
                            Text("전체 삭제")
                                .foregroundColor(.red)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .alert("전체 삭제", isPresented: $showDeleteAllAlert) {
                Button("취소", role: .cancel) { }
                Button("전체 삭제", role: .destructive) {
                    viewModel.deleteAll()
                }
            } message: {
                Text("모든 주행 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
            }
            .onPreferenceChange(CoachMarkFramePreferenceKey.self) { frames in
                coachMarkFrames = frames
            }
            .onAppear {
                // Always reload to show latest trips (e.g., after completing a new trip)
                viewModel.loadInitialPage()
                if coachMarkManager.shouldShowCoachMarks(for: "history") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        coachMarkManager.startCoachMarks(for: "history")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private func onDelete(at offsets: IndexSet) {
        for index in offsets {
            let trip = viewModel.trips[index]
            viewModel.delete(trip)
        }
    }
}

// MARK: - Trip Summary Row View (for list display)

struct TripSummaryRowView: View {
    let trip: TripSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formattedDate)
                    .font(.headline)
                Spacer()
                Text("\(trip.totalFare.formatted())원")
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

// MARK: - Legacy Trip Row View (backward compatibility)

struct TripRowView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formattedDate)
                    .font(.headline)
                Spacer()
                Text("\(trip.totalFare.formatted())원")
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

// MARK: - Trip Detail View (lazy loads route data)

struct TripDetailView: View {
    let tripId: UUID
    let tripSummary: TripSummary
    @ObservedObject var viewModel: TripHistoryViewModel

    @State private var fullTrip: Trip?
    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @State private var isLoadingTrip = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("기본 정보") {
                LabeledContent("출발", value: tripSummary.startRegion)
                LabeledContent("도착", value: tripSummary.endRegion)
                LabeledContent("거리", value: "\(String(format: "%.1f", tripSummary.distance)) km")
                LabeledContent("시간", value: formattedDuration)
            }

            Section("요금 내역") {
                LabeledContent("기본요금", value: "\(tripSummary.fareBreakdown.baseFare.formatted())원")
                LabeledContent("거리요금", value: "\(tripSummary.fareBreakdown.distanceFare.formatted())원")
                LabeledContent("시간요금", value: "\(tripSummary.fareBreakdown.timeFare.formatted())원")
                if tripSummary.fareBreakdown.regionSurcharge > 0 {
                    LabeledContent("지역할증", value: "\(tripSummary.fareBreakdown.regionSurcharge.formatted())원")
                }
                if tripSummary.fareBreakdown.nightSurcharge > 0 {
                    LabeledContent("야간할증", value: "\(tripSummary.fareBreakdown.nightSurcharge.formatted())원")
                }
                LabeledContent("총 요금", value: "\(tripSummary.fareBreakdown.totalFare.formatted())원")
                    .bold()
            }

            Section {
                Button {
                    loadFullTripAndShowShare()
                } label: {
                    HStack {
                        if isLoadingTrip {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text("영수증 공유")
                    }
                }
                .disabled(isLoadingTrip)

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
            if let trip = fullTrip {
                ReceiptView(trip: trip)
            } else {
                // Fallback: Create trip from summary if full trip unavailable
                ReceiptView(trip: tripSummary.toTrip())
            }
        }
        .alert("기록 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                viewModel.delete(tripSummary)
                dismiss()
            }
        } message: {
            Text("이 주행 기록을 삭제하시겠습니까?")
        }
    }

    private var formattedDuration: String {
        let hours = Int(tripSummary.duration) / 3600
        let minutes = (Int(tripSummary.duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }

    private func loadFullTripAndShowShare() {
        isLoadingTrip = true
        // Lazy load full trip with route data only when needed
        if fullTrip == nil {
            fullTrip = viewModel.getFullTrip(id: tripId)
        }
        isLoadingTrip = false
        showShareSheet = true
    }
}

#Preview {
    TripHistoryView()
}
