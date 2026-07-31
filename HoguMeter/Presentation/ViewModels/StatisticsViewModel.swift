//
//  StatisticsViewModel.swift
//  HoguMeter
//

import Foundation
import Combine

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var selectedPeriod: StatisticsPeriod = .monthly
    @Published private(set) var monthlyStatistics: [TripStatistics] = []
    @Published private(set) var weeklyStatistics: [TripStatistics] = []
    @Published private(set) var overview: StatisticsOverview = .empty
    @Published private(set) var gridCells: [StatisticsGridCell] = []
    @Published private(set) var isLoading = false

    private let repository: TripRepository
    private let statisticsService: TripStatisticsService

    var selectedStatistics: [TripStatistics] {
        switch selectedPeriod {
        case .monthly:
            return monthlyStatistics
        case .weekly:
            return weeklyStatistics
        }
    }

    var latestStatistics: TripStatistics? {
        selectedStatistics.first
    }

    init(
        repository: TripRepository = TripRepository(),
        statisticsService: TripStatisticsService = TripStatisticsService()
    ) {
        self.repository = repository
        self.statisticsService = statisticsService
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true

        let persistTripSummaries = repository.getAllSummaries()
        overview = statisticsService.overview(for: persistTripSummaries)
        monthlyStatistics = statisticsService.aggregate(persistTripSummaries, by: .monthly)
        weeklyStatistics = statisticsService.aggregate(persistTripSummaries, by: .weekly)
        gridCells = statisticsService.makeGridCells(from: repository.getAllRoutes())

        isLoading = false
    }
}
