//
//  RouteDataManager.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation
import CoreLocation
import Compression

/// Manages separate storage of route data files with compression
final class RouteDataManager {

    // MARK: - Singleton
    static let shared = RouteDataManager()

    // MARK: - Properties
    private let fileManager = FileManager.default
    private let routesDirectoryName = "Routes"
    private let fileExtension = "route.gz"

    private var routesDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(routesDirectoryName)
    }

    // MARK: - Init
    private init() {
        createRoutesDirectoryIfNeeded()
    }

    // MARK: - Public Methods

    /// Save route points to compressed file
    /// - Parameters:
    ///   - tripId: UUID of the trip
    ///   - points: Route points to save
    /// - Returns: Success status
    @discardableResult
    func saveRoute(tripId: UUID, points: [RoutePoint]) -> Bool {
        guard !points.isEmpty else { return false }

        // Optimize points before saving
        let optimizedPoints = RouteOptimizer.optimizeForStorage(points)

        do {
            let data = try JSONEncoder().encode(optimizedPoints)
            let compressedData = compress(data)
            let fileURL = routeFileURL(for: tripId)
            try compressedData.write(to: fileURL)

            Logger.gps.debug("[RouteDataManager] Saved route: \(optimizedPoints.count) points (\(compressedData.count) bytes) for trip \(tripId.uuidString.prefix(8))")
            return true
        } catch {
            Logger.gps.error("[RouteDataManager] Failed to save route: \(error.localizedDescription)")
            return false
        }
    }

    /// Load route points from file (lazy loading)
    /// - Parameter tripId: UUID of the trip
    /// - Returns: Route points or nil if not found
    func loadRoute(tripId: UUID) -> [RoutePoint]? {
        let fileURL = routeFileURL(for: tripId)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let compressedData = try Data(contentsOf: fileURL)
            guard let decompressedData = decompress(compressedData) else {
                Logger.gps.error("[RouteDataManager] Failed to decompress route data for trip \(tripId.uuidString.prefix(8))")
                return nil
            }
            let points = try JSONDecoder().decode([RoutePoint].self, from: decompressedData)
            Logger.gps.debug("[RouteDataManager] Loaded route: \(points.count) points for trip \(tripId.uuidString.prefix(8))")
            return points
        } catch {
            Logger.gps.error("[RouteDataManager] Failed to load route: \(error.localizedDescription)")
            return nil
        }
    }

    /// Delete route file for a specific trip
    /// - Parameter tripId: UUID of the trip
    func deleteRoute(tripId: UUID) {
        let fileURL = routeFileURL(for: tripId)
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
                Logger.gps.debug("[RouteDataManager] Deleted route for trip \(tripId.uuidString.prefix(8))")
            }
        } catch {
            Logger.gps.error("[RouteDataManager] Failed to delete route: \(error.localizedDescription)")
        }
    }

    /// Check if route file exists for a trip
    /// - Parameter tripId: UUID of the trip
    /// - Returns: True if route file exists
    func hasRoute(tripId: UUID) -> Bool {
        return fileManager.fileExists(atPath: routeFileURL(for: tripId).path)
    }

    /// Get size of route file in bytes
    /// - Parameter tripId: UUID of the trip
    /// - Returns: File size in bytes
    func routeFileSize(tripId: UUID) -> Int64 {
        let fileURL = routeFileURL(for: tripId)
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        return size
    }

    /// Get total size of all route files in bytes
    /// - Returns: Total size of all route files
    func totalRouteFilesSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: routesDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    /// Get count of route files
    /// - Returns: Number of route files
    func routeFileCount() -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: routesDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }
        return contents.filter { $0.pathExtension == "gz" }.count
    }

    /// Delete all route files
    func deleteAllRoutes() {
        do {
            if fileManager.fileExists(atPath: routesDirectory.path) {
                try fileManager.removeItem(at: routesDirectory)
            }
            createRoutesDirectoryIfNeeded()
            Logger.gps.debug("[RouteDataManager] Deleted all routes")
        } catch {
            Logger.gps.error("[RouteDataManager] Failed to delete all routes: \(error.localizedDescription)")
        }
    }

    /// Delete routes older than specified date
    /// - Parameter date: Cutoff date
    /// - Returns: Number of deleted routes
    @discardableResult
    func deleteRoutes(olderThan date: Date) -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: routesDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else {
            return 0
        }

        var deletedCount = 0
        for url in contents {
            guard let creationDate = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate,
                  creationDate < date else {
                continue
            }
            do {
                try fileManager.removeItem(at: url)
                deletedCount += 1
            } catch {
                Logger.gps.error("[RouteDataManager] Failed to delete old route: \(error.localizedDescription)")
            }
        }

        if deletedCount > 0 {
            Logger.gps.debug("[RouteDataManager] Deleted \(deletedCount) old routes")
        }
        return deletedCount
    }

    /// Get all route file URLs
    /// - Returns: Array of route file URLs
    func getAllRouteFileURLs() -> [URL] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: routesDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return contents.filter { $0.pathExtension == "gz" }
    }

    // MARK: - Private Methods

    private func routeFileURL(for tripId: UUID) -> URL {
        return routesDirectory.appendingPathComponent("\(tripId.uuidString).\(fileExtension)")
    }

    private func createRoutesDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: routesDirectory.path) {
            do {
                try fileManager.createDirectory(at: routesDirectory, withIntermediateDirectories: true)
                Logger.gps.debug("[RouteDataManager] Created routes directory")
            } catch {
                Logger.gps.error("[RouteDataManager] Failed to create routes directory: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Compression

    /// Compress data using ZLIB
    private func compress(_ data: Data) -> Data {
        let sourceSize = data.count
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: sourceSize)
        defer { destinationBuffer.deallocate() }

        let compressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_encode_buffer(
                destinationBuffer,
                sourceSize,
                sourceBuffer.bindMemory(to: UInt8.self).baseAddress!,
                sourceSize,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard compressedSize > 0 else { return data }
        return Data(bytes: destinationBuffer, count: compressedSize)
    }

    /// Decompress ZLIB compressed data
    private func decompress(_ data: Data) -> Data? {
        // Start with 10x buffer and grow if needed
        var destinationSize = data.count * 10
        var destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)

        var decompressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_decode_buffer(
                destinationBuffer,
                destinationSize,
                sourceBuffer.bindMemory(to: UInt8.self).baseAddress!,
                data.count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        // If buffer was too small, try larger
        if decompressedSize == 0 || decompressedSize == destinationSize {
            destinationBuffer.deallocate()
            destinationSize = data.count * 50
            destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)

            decompressedSize = data.withUnsafeBytes { sourceBuffer in
                compression_decode_buffer(
                    destinationBuffer,
                    destinationSize,
                    sourceBuffer.bindMemory(to: UInt8.self).baseAddress!,
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }

        defer { destinationBuffer.deallocate() }

        guard decompressedSize > 0 else { return nil }
        return Data(bytes: destinationBuffer, count: decompressedSize)
    }
}
