//
//  DataCleanupService.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation

/// Service for managing data cleanup
final class DataCleanupService {

    // MARK: - Singleton
    static let shared = DataCleanupService()

    // MARK: - Dependencies
    private let tripRepository: TripRepository
    private let routeDataManager: RouteDataManager
    private let settingsRepository: SettingsRepository

    // MARK: - Init
    init(
        tripRepository: TripRepository = TripRepository(),
        routeDataManager: RouteDataManager = .shared,
        settingsRepository: SettingsRepository = SettingsRepository()
    ) {
        self.tripRepository = tripRepository
        self.routeDataManager = routeDataManager
        self.settingsRepository = settingsRepository
    }

    // MARK: - Public Methods

    /// Perform cleanup based on settings (called on app launch)
    func performCleanupIfNeeded() {
        let settings = settingsRepository.dataManagementSettings
        guard settings.autoCleanupEnabled else { return }

        switch settings.cleanupPolicy {
        case .ageBased(let months):
            guard let cutoffDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else { return }
            cleanupByAge(olderThan: cutoffDate, routeOnly: settings.deleteRouteOnly)

        case .countBased(let maxCount):
            cleanupByCount(keepRecent: maxCount, routeOnly: settings.deleteRouteOnly)

        case .sizeBased(let maxMB):
            cleanupBySize(maxBytes: Int64(maxMB) * 1_048_576, routeOnly: settings.deleteRouteOnly)
        }
    }

    /// Cleanup trips older than specified date
    /// - Parameters:
    ///   - date: Cutoff date
    ///   - routeOnly: If true, only delete route data (keep metadata)
    /// - Returns: Number of trips/routes cleaned up
    @discardableResult
    func cleanupByAge(olderThan date: Date, routeOnly: Bool) -> Int {
        let summaries = tripRepository.getAllSummaries()
        var cleanedCount = 0

        for summary in summaries where summary.startTime < date {
            if routeOnly {
                routeDataManager.deleteRoute(tripId: summary.id)
            } else {
                tripRepository.delete(summary)
            }
            cleanedCount += 1
        }

        if cleanedCount > 0 {
            Logger.gps.debug("[DataCleanupService] Cleaned up \(cleanedCount) \(routeOnly ? "routes" : "trips") older than \(date)")
        }

        return cleanedCount
    }

    /// Keep only N most recent trips
    /// - Parameters:
    ///   - count: Number of recent trips to keep
    ///   - routeOnly: If true, only delete route data (keep metadata)
    /// - Returns: Number of trips/routes cleaned up
    @discardableResult
    func cleanupByCount(keepRecent count: Int, routeOnly: Bool) -> Int {
        let summaries = tripRepository.getAllSummaries()
        guard summaries.count > count else { return 0 }

        let toRemove = Array(summaries.suffix(from: count))
        var cleanedCount = 0

        for summary in toRemove {
            if routeOnly {
                routeDataManager.deleteRoute(tripId: summary.id)
            } else {
                tripRepository.delete(summary)
            }
            cleanedCount += 1
        }

        if cleanedCount > 0 {
            Logger.gps.debug("[DataCleanupService] Cleaned up \(cleanedCount) \(routeOnly ? "routes" : "trips") (keeping \(count) most recent)")
        }

        return cleanedCount
    }

    /// Cleanup until total size is under limit
    /// - Parameters:
    ///   - maxBytes: Maximum allowed size in bytes
    ///   - routeOnly: If true, only delete route data (keep metadata)
    /// - Returns: Number of trips/routes cleaned up
    @discardableResult
    func cleanupBySize(maxBytes: Int64, routeOnly: Bool) -> Int {
        var stats = getStorageStats()
        let summaries = tripRepository.getAllSummaries().reversed()  // Oldest first
        var cleanedCount = 0

        for summary in summaries {
            guard stats.totalSizeBytes > maxBytes else { break }

            if routeOnly {
                routeDataManager.deleteRoute(tripId: summary.id)
            } else {
                tripRepository.delete(summary)
            }
            cleanedCount += 1

            // Recalculate stats
            stats = getStorageStats()
        }

        if cleanedCount > 0 {
            Logger.gps.debug("[DataCleanupService] Cleaned up \(cleanedCount) \(routeOnly ? "routes" : "trips") to reduce size below \(maxBytes) bytes")
        }

        return cleanedCount
    }

    /// Get current storage statistics
    /// - Returns: StorageStats object
    func getStorageStats() -> StorageStats {
        let tripCount = tripRepository.getTotalCount()
        let routeSize = routeDataManager.totalRouteFilesSize()
        let metadataSize = estimateMetadataSize()

        return StorageStats(
            totalTripCount: tripCount,
            totalSizeBytes: routeSize + metadataSize,
            routeDataSizeBytes: routeSize,
            metadataSizeBytes: metadataSize
        )
    }

    /// Delete all data (trips and routes)
    func deleteAllData() {
        tripRepository.deleteAll()
        Logger.gps.debug("[DataCleanupService] Deleted all trip data")
    }

    /// Delete only route data for old trips (keep metadata)
    /// - Parameter months: Delete routes older than this many months
    /// - Returns: Number of routes deleted
    @discardableResult
    func cleanupOldRoutes(olderThanMonths months: Int = 3) -> Int {
        guard let cutoffDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else {
            return 0
        }
        return cleanupByAge(olderThan: cutoffDate, routeOnly: true)
    }

    // MARK: - Private Methods

    private func estimateMetadataSize() -> Int64 {
        // Estimate ~500 bytes per TripSummary in UserDefaults (JSON encoded)
        return Int64(tripRepository.getTotalCount() * 500)
    }
}
