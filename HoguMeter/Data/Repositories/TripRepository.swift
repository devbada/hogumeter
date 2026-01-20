//
//  TripRepository.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class TripRepository {

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let summariesKey = "saved_trips_v2"  // New key for separated storage
    private let legacyTripsKey = "saved_trips"   // Old key for migration
    private let maxTripsCount = 100
    private let routeDataManager = RouteDataManager.shared

    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods (New API with Separated Storage)

    /// Save a trip with separated route storage
    func save(_ trip: Trip) {
        // Save route data to separate file
        let hasRouteData = routeDataManager.saveRoute(tripId: trip.id, points: trip.routePoints)

        // Create summary without route points
        let summary = TripSummary(from: trip, hasRouteData: hasRouteData)

        var summaries = getAllSummaries()
        summaries.insert(summary, at: 0)

        // Limit to max count and clean up route files for removed trips
        if summaries.count > maxTripsCount {
            let removed = summaries.suffix(from: maxTripsCount)
            for removedSummary in removed {
                routeDataManager.deleteRoute(tripId: removedSummary.id)
            }
            summaries = Array(summaries.prefix(maxTripsCount))
        }

        saveSummariesToDisk(summaries)
    }

    /// Get all trip summaries (lightweight, for list display)
    func getAllSummaries() -> [TripSummary] {
        // Check for new format first
        if let data = userDefaults.data(forKey: summariesKey) {
            do {
                return try JSONDecoder().decode([TripSummary].self, from: data)
            } catch {
                print("[TripRepository] Failed to decode summaries: \(error)")
                return []
            }
        }

        // Try to migrate from legacy format
        return migrateFromLegacy()
    }

    /// Get paginated trip summaries
    /// - Parameters:
    ///   - page: Page number (0-indexed)
    ///   - pageSize: Number of items per page
    /// - Returns: Array of TripSummary for the requested page
    func getSummaries(page: Int, pageSize: Int = PaginationConfig.pageSize) -> [TripSummary] {
        let all = getAllSummaries()
        let start = page * pageSize
        guard start < all.count else { return [] }
        let end = min(start + pageSize, all.count)
        return Array(all[start..<end])
    }

    /// Get total trip count
    func getTotalCount() -> Int {
        return getAllSummaries().count
    }

    /// Get full trip with route data (lazy load)
    /// - Parameter id: Trip UUID
    /// - Returns: Full Trip object with route data loaded
    func getTrip(id: UUID) -> Trip? {
        guard let summary = getAllSummaries().first(where: { $0.id == id }) else {
            return nil
        }

        let routePoints = routeDataManager.loadRoute(tripId: id) ?? []
        return summary.toTrip(routePoints: routePoints)
    }

    /// Delete a trip by summary
    func delete(_ summary: TripSummary) {
        routeDataManager.deleteRoute(tripId: summary.id)
        var summaries = getAllSummaries()
        summaries.removeAll { $0.id == summary.id }
        saveSummariesToDisk(summaries)
    }

    /// Delete all trips and route data
    func deleteAll() {
        routeDataManager.deleteAllRoutes()
        userDefaults.removeObject(forKey: summariesKey)
        userDefaults.removeObject(forKey: legacyTripsKey)
    }

    // MARK: - Legacy API (Backward Compatibility)

    /// Get all full trips (legacy compatibility)
    /// Note: This loads all route data - use sparingly
    func getAll() -> [Trip] {
        return getAllSummaries().map { summary in
            let routePoints = routeDataManager.loadRoute(tripId: summary.id) ?? []
            return summary.toTrip(routePoints: routePoints)
        }
    }

    /// Delete a trip (legacy compatibility)
    func delete(_ trip: Trip) {
        routeDataManager.deleteRoute(tripId: trip.id)
        var summaries = getAllSummaries()
        summaries.removeAll { $0.id == trip.id }
        saveSummariesToDisk(summaries)
    }

    // MARK: - Private Methods

    private func saveSummariesToDisk(_ summaries: [TripSummary]) {
        do {
            let data = try JSONEncoder().encode(summaries)
            userDefaults.set(data, forKey: summariesKey)
        } catch {
            print("[TripRepository] Failed to encode summaries: \(error)")
        }
    }

    /// Migrate from legacy format (Trip with embedded routes)
    private func migrateFromLegacy() -> [TripSummary] {
        guard let data = userDefaults.data(forKey: legacyTripsKey) else {
            return []
        }

        do {
            let legacyTrips = try JSONDecoder().decode([Trip].self, from: data)
            var summaries: [TripSummary] = []

            for trip in legacyTrips {
                // Save route to separate file
                let hasRouteData = routeDataManager.saveRoute(tripId: trip.id, points: trip.routePoints)
                summaries.append(TripSummary(from: trip, hasRouteData: hasRouteData))
            }

            // Save migrated summaries
            saveSummariesToDisk(summaries)

            // Remove legacy data
            userDefaults.removeObject(forKey: legacyTripsKey)

            print("[TripRepository] Migrated \(legacyTrips.count) trips to new format")
            return summaries
        } catch {
            print("[TripRepository] Migration failed: \(error)")
            return []
        }
    }
}
