//
//  StorageStats.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation

/// Storage usage statistics
struct StorageStats {
    /// Total number of trips stored
    let totalTripCount: Int

    /// Total size of all data in bytes
    let totalSizeBytes: Int64

    /// Size of route data files in bytes
    let routeDataSizeBytes: Int64

    /// Size of metadata (TripSummary) in bytes
    let metadataSizeBytes: Int64

    // MARK: - Computed Properties

    /// Total size in megabytes
    var totalSizeMB: Double {
        Double(totalSizeBytes) / 1_048_576
    }

    /// Route data size in megabytes
    var routeDataSizeMB: Double {
        Double(routeDataSizeBytes) / 1_048_576
    }

    /// Metadata size in megabytes
    var metadataSizeMB: Double {
        Double(metadataSizeBytes) / 1_048_576
    }

    /// Formatted total size string
    var formattedTotalSize: String {
        formatBytes(totalSizeBytes)
    }

    /// Formatted route data size string
    var formattedRouteDataSize: String {
        formatBytes(routeDataSizeBytes)
    }

    /// Formatted metadata size string
    var formattedMetadataSize: String {
        formatBytes(metadataSizeBytes)
    }

    // MARK: - Default

    /// Empty statistics
    static let empty = StorageStats(
        totalTripCount: 0,
        totalSizeBytes: 0,
        routeDataSizeBytes: 0,
        metadataSizeBytes: 0
    )

    // MARK: - Private Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
