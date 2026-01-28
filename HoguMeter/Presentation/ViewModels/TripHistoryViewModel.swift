//
//  TripHistoryViewModel.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation
import Combine

/// ViewModel for TripHistoryView with pagination support
@MainActor
final class TripHistoryViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var trips: [TripSummary] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var hasMorePages: Bool = true
    @Published private(set) var totalCount: Int = 0

    // MARK: - Private Properties
    private var currentPage: Int = 0
    private let repository: TripRepository
    private let pageSize: Int

    // MARK: - Init
    init(repository: TripRepository = TripRepository(), pageSize: Int = PaginationConfig.pageSize) {
        self.repository = repository
        self.pageSize = pageSize
    }

    // MARK: - Public Methods

    /// Load initial page of trips
    func loadInitialPage() {
        guard !isLoading else { return }

        currentPage = 0
        isLoading = true

        let newTrips = repository.getSummaries(page: 0, pageSize: pageSize)
        totalCount = repository.getTotalCount()

        trips = newTrips
        hasMorePages = newTrips.count >= pageSize && trips.count < totalCount
        isLoading = false
    }

    /// Load next page if the current item is near the end
    /// - Parameter currentItem: The item currently being displayed
    func loadNextPageIfNeeded(currentItem: TripSummary) {
        guard !isLoading, hasMorePages else { return }

        // Check if current item is near the end
        guard let index = trips.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let threshold = trips.count - PaginationConfig.prefetchThreshold
        guard index >= threshold else { return }

        loadNextPage()
    }

    /// Load next page of trips
    func loadNextPage() {
        guard !isLoading, hasMorePages else { return }

        isLoading = true
        currentPage += 1

        let newTrips = repository.getSummaries(page: currentPage, pageSize: pageSize)

        trips.append(contentsOf: newTrips)
        hasMorePages = newTrips.count >= pageSize && trips.count < totalCount
        isLoading = false
    }

    /// Refresh (pull-to-refresh)
    func refresh() async {
        loadInitialPage()
    }

    /// Delete a trip
    /// - Parameter trip: TripSummary to delete
    func delete(_ trip: TripSummary) {
        repository.delete(trip)
        trips.removeAll { $0.id == trip.id }
        totalCount = repository.getTotalCount()
    }

    /// Delete all trips
    func deleteAll() {
        repository.deleteAll()
        trips = []
        totalCount = 0
        hasMorePages = false
    }

    /// Get full trip with route data for detail view
    /// - Parameter id: Trip UUID
    /// - Returns: Full Trip object with route data
    func getFullTrip(id: UUID) -> Trip? {
        return repository.getTrip(id: id)
    }
}
