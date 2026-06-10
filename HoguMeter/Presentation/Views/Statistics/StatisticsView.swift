//
//  StatisticsView.swift
//  HoguMeter
//

import Charts
import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel: StatisticsViewModel
    @StateObject private var coachMarkManager = CoachMarkManager.shared
    @State private var coachMarkFrames: [String: CGRect] = [:]

    init(repository: TripRepository = TripRepository()) {
        _viewModel = StateObject(
            wrappedValue: StatisticsViewModel(repository: repository)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if viewModel.overview.tripCount == 0 && !viewModel.isLoading {
                        ContentUnavailableView(
                            "통계 없음",
                            systemImage: "chart.bar.xaxis",
                            description: Text("주행 기록이 쌓이면 거리와 금액 통계를 확인할 수 있습니다")
                        )
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 16) {
                                    overviewSection
                                        .id("statisticsOverview")
                                        .coachMarkTarget(id: "statisticsOverview")

                                    VStack(spacing: 16) {
                                        periodPicker
                                        currentPeriodSection
                                        distanceChartSection
                                        fareChartSection
                                    }
                                    .id("statisticsPeriod")
                                    .coachMarkTarget(id: "statisticsPeriod")

                                    gridMapSection
                                        .id("statisticsMap")
                                        .coachMarkTarget(id: "statisticsMap")

                                    periodHistorySection
                                }
                                .padding()
                            }
                            .onChange(of: coachMarkManager.currentMarkIndex) { _, _ in
                                scrollToCurrentCoachMark(using: proxy)
                            }
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                }
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }

                if coachMarkManager.isShowingCoachMark,
                   coachMarkManager.currentScreenId == "statistics",
                   let currentMark = coachMarkManager.currentCoachMark,
                   let frame = coachMarkFrames[currentMark.targetView] {
                    CoachMarkOverlay(
                        manager: coachMarkManager,
                        coachMark: currentMark,
                        targetFrame: frame
                    )
                }
            }
            .navigationTitle("통계")
            .onPreferenceChange(CoachMarkFramePreferenceKey.self) { frames in
                coachMarkFrames = frames
            }
            .onAppear {
                viewModel.load()
                startCoachMarksIfNeeded()
            }
            .refreshable {
                viewModel.load()
                startCoachMarksIfNeeded()
            }
        }
    }

    private func startCoachMarksIfNeeded() {
        guard viewModel.overview.tripCount > 0,
              coachMarkManager.shouldShowCoachMarks(for: "statistics") else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            coachMarkManager.startCoachMarks(for: "statistics")
        }
    }

    private func scrollToCurrentCoachMark(using proxy: ScrollViewProxy) {
        guard coachMarkManager.currentScreenId == "statistics",
              let targetView = coachMarkManager.currentCoachMark?.targetView else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(targetView, anchor: .center)
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("전체 이용 기록", systemImage: "calendar.badge.clock")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.overview.tripCount.formatted())회")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let startDate = viewModel.overview.usageStartDate,
               let endDate = viewModel.overview.usageEndDate {
                Text("\(startDate.formatted(date: .numeric, time: .omitted)) ~ \(endDate.formatted(date: .numeric, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                metricCard(
                    title: "총 거리",
                    value: distanceText(viewModel.overview.totalDistance),
                    icon: "road.lanes",
                    color: .blue
                )
                metricCard(
                    title: "총 발생금액",
                    value: "\(viewModel.overview.totalFare.formatted())원",
                    icon: "wonsign.circle.fill",
                    color: .green
                )
            }
        }
        .statisticsCard()
    }

    private var periodPicker: some View {
        Picker("집계 기간", selection: $viewModel.selectedPeriod) {
            ForEach(StatisticsPeriod.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("통계 집계 기간")
    }

    private var currentPeriodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(latestPeriodTitle)
                .font(.headline)

            HStack(spacing: 12) {
                metricCard(
                    title: "거리",
                    value: distanceText(viewModel.latestStatistics?.totalDistance ?? 0),
                    icon: "location.fill",
                    color: .blue
                )
                metricCard(
                    title: "발생금액",
                    value: "\((viewModel.latestStatistics?.totalFare ?? 0).formatted())원",
                    icon: "banknote.fill",
                    color: .green
                )
            }
        }
        .statisticsCard()
    }

    private var distanceChartSection: some View {
        chartCard(title: "\(viewModel.selectedPeriod.title) 총 거리", systemImage: "chart.bar.fill") {
            Chart(chartStatistics) { statistics in
                BarMark(
                    x: .value("기간", periodLabel(statistics)),
                    y: .value("거리", statistics.totalDistance)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .chartYAxisLabel("km")
            .frame(height: 180)
            .accessibilityLabel("\(viewModel.selectedPeriod.title) 총 거리 차트")
        }
    }

    private var fareChartSection: some View {
        chartCard(title: "\(viewModel.selectedPeriod.title) 총 발생금액", systemImage: "wonsign.circle.fill") {
            Chart(chartStatistics) { statistics in
                BarMark(
                    x: .value("기간", periodLabel(statistics)),
                    y: .value("금액", statistics.totalFare)
                )
                .foregroundStyle(.green.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let fare = value.as(Int.self) {
                            Text(compactFareText(fare))
                        }
                    }
                }
            }
            .frame(height: 180)
            .accessibilityLabel("\(viewModel.selectedPeriod.title) 총 발생금액 차트")
        }
    }

    private var gridMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("이용 지역 모아보기", systemImage: "square.grid.3x3.fill")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.gridCells.count.formatted())개 격자")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.gridCells.isEmpty {
                Label("저장된 경로 데이터가 없습니다", systemImage: "map")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                NavigationLink {
                    StatisticsGridMapView(cells: viewModel.gridCells)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("500m 격자 지도 보기")
                                .font(.headline)
                            Text("진한 격자일수록 자주 이용한 지역입니다")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .statisticsCard()
    }

    private var periodHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(viewModel.selectedPeriod.title) 상세")
                .font(.headline)

            ForEach(viewModel.selectedStatistics) { statistics in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(periodLongLabel(statistics))
                            .font(.subheadline.weight(.semibold))
                        Text("\(statistics.tripCount.formatted())회")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(distanceText(statistics.totalDistance))
                            .font(.subheadline.weight(.semibold))
                        Text("\(statistics.totalFare.formatted())원")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                if statistics.id != viewModel.selectedStatistics.last?.id {
                    Divider()
                }
            }
        }
        .statisticsCard()
    }

    private var chartStatistics: [TripStatistics] {
        Array(viewModel.selectedStatistics.prefix(6).reversed())
    }

    private var latestPeriodTitle: String {
        guard let statistics = viewModel.latestStatistics else {
            return "현재 \(viewModel.selectedPeriod.title) 기록 없음"
        }
        return periodLongLabel(statistics)
    }

    private func metricCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func chartCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .statisticsCard()
    }

    private func distanceText(_ distance: Double) -> String {
        String(format: "%.1f km", distance)
    }

    private func periodLabel(_ statistics: TripStatistics) -> String {
        switch statistics.period {
        case .monthly:
            return statistics.startDate.formatted(.dateTime.month(.defaultDigits))
        case .weekly:
            return statistics.startDate.formatted(.dateTime.month(.defaultDigits).day())
        }
    }

    private func periodLongLabel(_ statistics: TripStatistics) -> String {
        switch statistics.period {
        case .monthly:
            return statistics.startDate.formatted(.dateTime.year().month(.wide))
        case .weekly:
            let start = statistics.startDate.formatted(.dateTime.month().day())
            let end = statistics.endDate.formatted(.dateTime.month().day())
            return "\(start) ~ \(end)"
        }
    }

    private func compactFareText(_ fare: Int) -> String {
        if fare >= 10_000 {
            return "\(fare / 10_000)만"
        }
        if fare >= 1_000 {
            return "\(fare / 1_000)천"
        }
        return "\(fare)"
    }
}

private extension View {
    func statisticsCard() -> some View {
        padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    StatisticsView()
}
