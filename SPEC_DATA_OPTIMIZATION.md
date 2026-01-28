# Trip History Data Optimization Specification

## Version History
| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 1.0 | 2026-01-19 | Claude Code | Initial specification |

---

## 1. Overview

### 1.1 Purpose
Optimize trip history data storage and retrieval to prevent storage bloat and performance degradation as records accumulate.

### 1.2 Current State Analysis

**Storage Architecture:**
- **Storage:** UserDefaults with JSON encoding
- **Limit:** Maximum 100 trips
- **Data:** All route coordinates embedded in Trip entity

**Current Trip Entity (`Trip.swift`):**
```swift
struct Trip: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let totalFare: Int
    let distance: Double        // km
    let duration: TimeInterval  // seconds
    let startRegion: String
    let endRegion: String
    let regionChanges: Int
    let isNightTrip: Bool
    let fareBreakdown: FareBreakdown
    let routePoints: [RoutePoint]  // <-- PROBLEM: All coordinates stored here
    let driverQuote: String?
    let surchargeMode: RegionalSurchargeMode
    let surchargeRate: Double
}
```

**Current RoutePoint (`RoutePoint.swift`):**
```swift
struct RoutePoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double       // km/h
    let accuracy: Double    // meters
}
```

### 1.3 Problem Statement

| Issue | Current Impact | Expected Growth |
|-------|----------------|-----------------|
| RoutePoints per trip | 300-3000 points | Unbounded |
| Size per RoutePoint | ~80-100 bytes | Fixed |
| Trip data size | 30-300KB | Linear |
| 100 trips total | 3-30MB in UserDefaults | At capacity |
| Load time | All 100 trips loaded | O(n) degradation |
| No pagination | Full deserialization | Memory pressure |

### 1.4 Existing Optimizations

The `RouteManager` already implements:
1. **Dynamic distance-based sampling:** 5m-200m intervals based on total distance
2. **Douglas-Peucker simplification:** Applied when >5000 points, targets 3000 points
3. **Max point limit:** 10,000 points maximum

However, all points are still stored within the Trip entity.

---

## 2. Feature 1: Enhanced Route Coordinate Sampling

### 2.1 Objective
Further reduce coordinate storage by applying time-based sampling on save.

### 2.2 Implementation

**New: `RouteOptimizer.swift`**

```swift
// Location: HoguMeter/Domain/Services/RouteOptimizer.swift

import Foundation
import CoreLocation

/// Route optimization utilities for storage efficiency
enum RouteOptimizer {

    /// Sampling interval in seconds when saving trip
    static let saveInterval: TimeInterval = 5.0

    /// Downsample route points to 5-second intervals
    /// - Parameter points: Original route points (collected at ~1 second intervals)
    /// - Returns: Downsampled route points
    static func downsample(_ points: [RoutePoint]) -> [RoutePoint] {
        guard points.count > 2 else { return points }

        var result: [RoutePoint] = []
        var lastTimestamp: Date?

        // Always keep first point
        result.append(points[0])
        lastTimestamp = points[0].timestamp

        for point in points.dropFirst() {
            guard let last = lastTimestamp else { continue }

            // Keep point if 5+ seconds have passed
            if point.timestamp.timeIntervalSince(last) >= saveInterval {
                result.append(point)
                lastTimestamp = point.timestamp
            }
        }

        // Always keep last point
        if let lastPoint = points.last, result.last?.timestamp != lastPoint.timestamp {
            result.append(lastPoint)
        }

        return result
    }

    /// Apply Douglas-Peucker simplification for curve preservation
    /// - Parameters:
    ///   - points: Route points to simplify
    ///   - tolerance: Distance tolerance in meters
    /// - Returns: Simplified route points
    static func simplify(_ points: [RoutePoint], tolerance: Double = 10.0) -> [RoutePoint] {
        guard points.count > 2 else { return points }

        var keep = [Bool](repeating: false, count: points.count)
        keep[0] = true
        keep[points.count - 1] = true

        var stack: [(Int, Int)] = [(0, points.count - 1)]

        while !stack.isEmpty {
            let (start, end) = stack.removeLast()
            guard end - start > 1 else { continue }

            var maxDistance: Double = 0
            var maxIndex = start

            let startCoord = points[start].coordinate
            let endCoord = points[end].coordinate

            for i in (start + 1)..<end {
                let distance = perpendicularDistance(
                    point: points[i].coordinate,
                    lineStart: startCoord,
                    lineEnd: endCoord
                )
                if distance > maxDistance {
                    maxDistance = distance
                    maxIndex = i
                }
            }

            if maxDistance > tolerance {
                keep[maxIndex] = true
                stack.append((start, maxIndex))
                stack.append((maxIndex, end))
            }
        }

        return points.enumerated().compactMap { keep[$0.offset] ? $0.element : nil }
    }

    /// Optimize route for storage (downsample + simplify)
    static func optimizeForStorage(_ points: [RoutePoint]) -> [RoutePoint] {
        let downsampled = downsample(points)
        return simplify(downsampled, tolerance: 10.0)
    }

    // MARK: - Private Helpers

    private static func perpendicularDistance(
        point: CLLocationCoordinate2D,
        lineStart: CLLocationCoordinate2D,
        lineEnd: CLLocationCoordinate2D
    ) -> Double {
        let lineLength = distance(from: lineStart, to: lineEnd)
        if lineLength == 0 { return distance(from: point, to: lineStart) }

        let dx = lineEnd.longitude - lineStart.longitude
        let dy = lineEnd.latitude - lineStart.latitude
        let t = max(0, min(1, (
            (point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy
        ) / (dx * dx + dy * dy)))

        let closest = CLLocationCoordinate2D(
            latitude: lineStart.latitude + t * dy,
            longitude: lineStart.longitude + t * dx
        )
        return distance(from: point, to: closest)
    }

    private static func distance(from c1: CLLocationCoordinate2D, to c2: CLLocationCoordinate2D) -> Double {
        let l1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
        let l2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
        return l1.distance(from: l2)
    }
}
```

### 2.3 Expected Results

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| Points (60 min trip) | ~3,600 | ~720 | 80% |
| After simplification | ~720 | ~200-400 | 90%+ total |

---

## 3. Feature 2: Separated Data Storage

### 3.1 Architecture

```
UserDefaults (Trip metadata)     File System (Route data)
├── id: UUID                     /Documents/Routes/
├── startTime                    ├── {tripId}.route.gz
├── endTime                      └── (gzip compressed JSON)
├── totalFare
├── distance
├── duration
├── startRegion
├── endRegion
├── regionChanges
├── isNightTrip
├── fareBreakdown
├── driverQuote
├── surchargeMode
├── surchargeRate
└── hasRouteData: Bool ─────────→ Indicates external file exists
```

### 3.2 New Entities

**`TripSummary.swift` - Lightweight model for list display:**

```swift
// Location: HoguMeter/Domain/Entities/TripSummary.swift

import Foundation

/// Lightweight trip model for list display (no route data)
struct TripSummary: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let totalFare: Int
    let distance: Double
    let duration: TimeInterval
    let startRegion: String
    let endRegion: String
    let regionChanges: Int
    let isNightTrip: Bool
    let fareBreakdown: FareBreakdown
    let driverQuote: String?
    let surchargeMode: RegionalSurchargeMode
    let surchargeRate: Double
    let hasRouteData: Bool

    /// Convert from full Trip (for migration)
    init(from trip: Trip, hasRouteData: Bool = true) {
        self.id = trip.id
        self.startTime = trip.startTime
        self.endTime = trip.endTime
        self.totalFare = trip.totalFare
        self.distance = trip.distance
        self.duration = trip.duration
        self.startRegion = trip.startRegion
        self.endRegion = trip.endRegion
        self.regionChanges = trip.regionChanges
        self.isNightTrip = trip.isNightTrip
        self.fareBreakdown = trip.fareBreakdown
        self.driverQuote = trip.driverQuote
        self.surchargeMode = trip.surchargeMode
        self.surchargeRate = trip.surchargeRate
        self.hasRouteData = hasRouteData
    }

    /// Create full Trip by loading route data
    func toTrip(routePoints: [RoutePoint] = []) -> Trip {
        Trip(
            id: id,
            startTime: startTime,
            endTime: endTime,
            totalFare: totalFare,
            distance: distance,
            duration: duration,
            startRegion: startRegion,
            endRegion: endRegion,
            regionChanges: regionChanges,
            isNightTrip: isNightTrip,
            fareBreakdown: fareBreakdown,
            routePoints: routePoints,
            driverQuote: driverQuote,
            surchargeMode: surchargeMode,
            surchargeRate: surchargeRate
        )
    }
}
```

### 3.3 Route Data Manager

**`RouteDataManager.swift`:**

```swift
// Location: HoguMeter/Domain/Services/RouteDataManager.swift

import Foundation
import CoreLocation
import Compression

/// Manages separate storage of route data files
final class RouteDataManager {

    // MARK: - Singleton
    static let shared = RouteDataManager()

    // MARK: - Properties
    private let fileManager = FileManager.default
    private let routesDirectoryName = "Routes"

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
            return true
        } catch {
            print("[RouteDataManager] Failed to save route: \(error)")
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
                return nil
            }
            return try JSONDecoder().decode([RoutePoint].self, from: decompressedData)
        } catch {
            print("[RouteDataManager] Failed to load route: \(error)")
            return nil
        }
    }

    /// Delete route file
    /// - Parameter tripId: UUID of the trip
    func deleteRoute(tripId: UUID) {
        let fileURL = routeFileURL(for: tripId)
        try? fileManager.removeItem(at: fileURL)
    }

    /// Check if route file exists
    func hasRoute(tripId: UUID) -> Bool {
        return fileManager.fileExists(atPath: routeFileURL(for: tripId).path)
    }

    /// Get size of route file in bytes
    func routeFileSize(tripId: UUID) -> Int64 {
        let fileURL = routeFileURL(for: tripId)
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        return size
    }

    /// Get total size of all route files
    func totalRouteFilesSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: routesDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    /// Delete all route files
    func deleteAllRoutes() {
        try? fileManager.removeItem(at: routesDirectory)
        createRoutesDirectoryIfNeeded()
    }

    /// Delete routes older than specified date
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
            try? fileManager.removeItem(at: url)
            deletedCount += 1
        }
        return deletedCount
    }

    // MARK: - Private Methods

    private func routeFileURL(for tripId: UUID) -> URL {
        return routesDirectory.appendingPathComponent("\(tripId.uuidString).route.gz")
    }

    private func createRoutesDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: routesDirectory.path) {
            try? fileManager.createDirectory(at: routesDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Compression

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

    private func decompress(_ data: Data) -> Data? {
        let destinationSize = data.count * 10  // Assume 10x compression ratio
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
        defer { destinationBuffer.deallocate() }

        let decompressedSize = data.withUnsafeBytes { sourceBuffer in
            compression_decode_buffer(
                destinationBuffer,
                destinationSize,
                sourceBuffer.bindMemory(to: UInt8.self).baseAddress!,
                data.count,
                nil,
                COMPRESSION_ZLIB
            )
        }

        guard decompressedSize > 0 else { return nil }
        return Data(bytes: destinationBuffer, count: decompressedSize)
    }
}
```

### 3.4 Updated TripRepository

**`TripRepository.swift` (updated):**

```swift
// Location: HoguMeter/Data/Repositories/TripRepository.swift

import Foundation

final class TripRepository {

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let tripsKey = "saved_trips_v2"  // New key for migrated data
    private let legacyTripsKey = "saved_trips"  // Old key for migration
    private let maxTripsCount = 100
    private let routeDataManager = RouteDataManager.shared

    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// Save a trip with separated route storage
    func save(_ trip: Trip) {
        // Save route data to separate file
        let hasRouteData = routeDataManager.saveRoute(tripId: trip.id, points: trip.routePoints)

        // Create summary without route points
        let summary = TripSummary(from: trip, hasRouteData: hasRouteData)

        var summaries = getAllSummaries()
        summaries.insert(summary, at: 0)

        // Limit to max count
        if summaries.count > maxTripsCount {
            let removed = summaries.suffix(from: maxTripsCount)
            for summary in removed {
                routeDataManager.deleteRoute(tripId: summary.id)
            }
            summaries = Array(summaries.prefix(maxTripsCount))
        }

        saveSummariesToDisk(summaries)
    }

    /// Get all trip summaries (lightweight, for list display)
    func getAllSummaries() -> [TripSummary] {
        guard let data = userDefaults.data(forKey: tripsKey) else {
            return migrateFromLegacy()
        }

        do {
            return try JSONDecoder().decode([TripSummary].self, from: data)
        } catch {
            print("[TripRepository] Failed to decode summaries: \(error)")
            return []
        }
    }

    /// Get paginated trip summaries
    func getSummaries(page: Int, pageSize: Int = 20) -> [TripSummary] {
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
    func getTrip(id: UUID) -> Trip? {
        guard let summary = getAllSummaries().first(where: { $0.id == id }) else {
            return nil
        }

        let routePoints = routeDataManager.loadRoute(tripId: id) ?? []
        return summary.toTrip(routePoints: routePoints)
    }

    /// Get all full trips (legacy compatibility)
    func getAll() -> [Trip] {
        return getAllSummaries().map { summary in
            let routePoints = routeDataManager.loadRoute(tripId: summary.id) ?? []
            return summary.toTrip(routePoints: routePoints)
        }
    }

    /// Delete a trip and its route data
    func delete(_ trip: Trip) {
        routeDataManager.deleteRoute(tripId: trip.id)
        var summaries = getAllSummaries()
        summaries.removeAll { $0.id == trip.id }
        saveSummariesToDisk(summaries)
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
        userDefaults.removeObject(forKey: tripsKey)
    }

    // MARK: - Private Methods

    private func saveSummariesToDisk(_ summaries: [TripSummary]) {
        do {
            let data = try JSONEncoder().encode(summaries)
            userDefaults.set(data, forKey: tripsKey)
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
```

---

## 4. Feature 3: Pagination

### 4.1 Configuration

```swift
// Location: HoguMeter/Core/Constants/PaginationConfig.swift

enum PaginationConfig {
    static let pageSize: Int = 20
    static let prefetchThreshold: Int = 5
}
```

### 4.2 TripHistoryViewModel

```swift
// Location: HoguMeter/Presentation/ViewModels/TripHistoryViewModel.swift

import Foundation
import Combine

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

    /// Load initial page
    func loadInitialPage() {
        guard !isLoading else { return }

        currentPage = 0
        isLoading = true

        let newTrips = repository.getSummaries(page: 0, pageSize: pageSize)
        totalCount = repository.getTotalCount()

        trips = newTrips
        hasMorePages = newTrips.count >= pageSize
        isLoading = false
    }

    /// Load next page if needed
    func loadNextPageIfNeeded(currentItem: TripSummary) {
        guard !isLoading, hasMorePages else { return }

        // Check if current item is near the end
        guard let index = trips.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let threshold = trips.count - PaginationConfig.prefetchThreshold
        guard index >= threshold else { return }

        loadNextPage()
    }

    /// Load next page
    func loadNextPage() {
        guard !isLoading, hasMorePages else { return }

        isLoading = true
        currentPage += 1

        let newTrips = repository.getSummaries(page: currentPage, pageSize: pageSize)

        trips.append(contentsOf: newTrips)
        hasMorePages = newTrips.count >= pageSize
        isLoading = false
    }

    /// Refresh (pull-to-refresh)
    func refresh() async {
        loadInitialPage()
    }

    /// Delete a trip
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

    /// Get full trip for detail view
    func getFullTrip(id: UUID) -> Trip? {
        return repository.getTrip(id: id)
    }
}
```

### 4.3 Updated TripHistoryView

```swift
// Location: HoguMeter/Presentation/Views/History/TripHistoryView.swift

import SwiftUI

struct TripHistoryView: View {
    @StateObject private var viewModel = TripHistoryViewModel()
    @State private var showDeleteAllAlert = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.trips.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "주행 기록 없음",
                        systemImage: "clock",
                        description: Text("아직 저장된 주행 기록이 없습니다")
                    )
                } else {
                    List {
                        ForEach(viewModel.trips) { trip in
                            NavigationLink {
                                TripDetailView(
                                    tripId: trip.id,
                                    viewModel: viewModel
                                )
                            } label: {
                                TripRowView(trip: trip)
                                    .onAppear {
                                        viewModel.loadNextPageIfNeeded(currentItem: trip)
                                    }
                            }
                        }
                        .onDelete(perform: onDelete)

                        // Loading indicator
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
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
            .onAppear {
                if viewModel.trips.isEmpty {
                    viewModel.loadInitialPage()
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
```

---

## 5. Feature 4: User Settings UI

### 5.1 Data Management Settings Model

```swift
// Location: HoguMeter/Domain/Entities/DataManagementSettings.swift

import Foundation

/// Cleanup policy types
enum CleanupPolicy: Codable, Equatable {
    case ageBased(months: Int)
    case countBased(maxCount: Int)
    case sizeBased(maxMB: Int)

    var displayName: String {
        switch self {
        case .ageBased(let months):
            return "\(months)개월 이후 삭제"
        case .countBased(let count):
            return "\(count)개 초과 시 삭제"
        case .sizeBased(let mb):
            return "\(mb)MB 초과 시 삭제"
        }
    }
}

/// Data management settings
struct DataManagementSettings: Codable, Equatable {
    var saveRouteData: Bool = true
    var autoCleanupEnabled: Bool = false
    var cleanupPolicy: CleanupPolicy = .ageBased(months: 6)
    var deleteRouteOnly: Bool = true

    static let `default` = DataManagementSettings()
}
```

### 5.2 Storage Statistics

```swift
// Location: HoguMeter/Domain/Entities/StorageStats.swift

import Foundation

/// Storage usage statistics
struct StorageStats {
    let totalTripCount: Int
    let totalSizeBytes: Int64
    let routeDataSizeBytes: Int64
    let metadataSizeBytes: Int64

    var totalSizeMB: Double {
        Double(totalSizeBytes) / 1_048_576
    }

    var routeDataSizeMB: Double {
        Double(routeDataSizeBytes) / 1_048_576
    }

    var metadataSizeMB: Double {
        Double(metadataSizeBytes) / 1_048_576
    }

    var formattedTotalSize: String {
        formatBytes(totalSizeBytes)
    }

    var formattedRouteDataSize: String {
        formatBytes(routeDataSizeBytes)
    }

    var formattedMetadataSize: String {
        formatBytes(metadataSizeBytes)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
```

### 5.3 Data Management View

```swift
// Location: HoguMeter/Presentation/Views/Settings/DataManagementView.swift

import SwiftUI

struct DataManagementView: View {
    @StateObject private var viewModel = DataManagementViewModel()
    @State private var showCleanupAlert = false
    @State private var showDeleteAllAlert = false

    var body: some View {
        Form {
            // Storage Status Section
            Section {
                LabeledContent("총 기록 수", value: "\(viewModel.stats.totalTripCount)개")
                LabeledContent("사용 중인 용량", value: viewModel.stats.formattedTotalSize)
                LabeledContent("경로 데이터", value: viewModel.stats.formattedRouteDataSize)
                LabeledContent("메타데이터", value: viewModel.stats.formattedMetadataSize)
            } header: {
                Label("저장 현황", systemImage: "chart.bar")
            }

            // Storage Settings Section
            Section {
                Toggle(isOn: $viewModel.settings.saveRouteData) {
                    VStack(alignment: .leading) {
                        Text("경로 데이터 저장")
                        Text("지도에 경로 표시용")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Label("저장 설정", systemImage: "gearshape")
            }

            // Auto Cleanup Section
            Section {
                Toggle(isOn: $viewModel.settings.autoCleanupEnabled) {
                    Text("자동 정리 사용")
                }

                if viewModel.settings.autoCleanupEnabled {
                    Picker("정리 기준", selection: $viewModel.cleanupPolicyType) {
                        Text("기간 기반").tag(CleanupPolicyType.ageBased)
                        Text("개수 기반").tag(CleanupPolicyType.countBased)
                        Text("용량 기반").tag(CleanupPolicyType.sizeBased)
                    }

                    switch viewModel.cleanupPolicyType {
                    case .ageBased:
                        Stepper(value: $viewModel.ageMonths, in: 1...12) {
                            Text("\(viewModel.ageMonths)개월 이후 삭제")
                        }
                    case .countBased:
                        Stepper(value: $viewModel.maxCount, in: 50...500, step: 50) {
                            Text("\(viewModel.maxCount)개 초과 시 삭제")
                        }
                    case .sizeBased:
                        Stepper(value: $viewModel.maxMB, in: 50...500, step: 50) {
                            Text("\(viewModel.maxMB)MB 초과 시 삭제")
                        }
                    }

                    Toggle(isOn: $viewModel.settings.deleteRouteOnly) {
                        VStack(alignment: .leading) {
                            Text("경로만 삭제")
                            Text("메타데이터(요금, 거리 등)는 유지")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Label("자동 정리", systemImage: "arrow.3.trianglepath")
            }

            // Manual Cleanup Section
            Section {
                Button {
                    showCleanupAlert = true
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        VStack(alignment: .leading) {
                            Text("오래된 경로 데이터 정리")
                            Text("3개월 이상 된 경로만 삭제")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button(role: .destructive) {
                    showDeleteAllAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        VStack(alignment: .leading) {
                            Text("전체 기록 삭제")
                            Text("모든 주행 기록 삭제 (복구 불가)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Label("수동 정리", systemImage: "trash")
            }
        }
        .navigationTitle("데이터 관리")
        .onAppear {
            viewModel.loadStats()
        }
        .alert("경로 데이터 정리", isPresented: $showCleanupAlert) {
            Button("취소", role: .cancel) { }
            Button("정리") {
                viewModel.cleanupOldRoutes()
            }
        } message: {
            Text("3개월 이상 된 경로 데이터를 삭제합니다.\n요금, 거리 등 기본 정보는 유지됩니다.")
        }
        .alert("전체 기록 삭제", isPresented: $showDeleteAllAlert) {
            Button("취소", role: .cancel) { }
            Button("전체 삭제", role: .destructive) {
                viewModel.deleteAllData()
            }
        } message: {
            Text("모든 주행 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
        }
    }
}

enum CleanupPolicyType {
    case ageBased
    case countBased
    case sizeBased
}
```

### 5.4 Data Management ViewModel

```swift
// Location: HoguMeter/Presentation/ViewModels/DataManagementViewModel.swift

import Foundation
import Combine

@MainActor
final class DataManagementViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var settings: DataManagementSettings
    @Published var stats: StorageStats
    @Published var cleanupPolicyType: CleanupPolicyType = .ageBased
    @Published var ageMonths: Int = 6
    @Published var maxCount: Int = 100
    @Published var maxMB: Int = 100

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    private let cleanupService: DataCleanupService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        settingsRepository: SettingsRepository = SettingsRepository(),
        cleanupService: DataCleanupService = DataCleanupService()
    ) {
        self.settingsRepository = settingsRepository
        self.cleanupService = cleanupService
        self.settings = settingsRepository.dataManagementSettings
        self.stats = cleanupService.getStorageStats()

        setupBindings()
        loadPolicyValues()
    }

    // MARK: - Public Methods

    func loadStats() {
        stats = cleanupService.getStorageStats()
    }

    func cleanupOldRoutes() {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        cleanupService.cleanupByAge(olderThan: threeMonthsAgo, routeOnly: true)
        loadStats()
    }

    func deleteAllData() {
        cleanupService.deleteAllData()
        loadStats()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        $settings
            .dropFirst()
            .sink { [weak self] settings in
                self?.settingsRepository.dataManagementSettings = settings
            }
            .store(in: &cancellables)

        // Sync cleanup policy
        Publishers.CombineLatest3($cleanupPolicyType, $ageMonths, $maxCount)
            .combineLatest($maxMB)
            .dropFirst()
            .sink { [weak self] values in
                let ((policyType, ageMonths, maxCount), maxMB) = values
                self?.updateCleanupPolicy(type: policyType, ageMonths: ageMonths, maxCount: maxCount, maxMB: maxMB)
            }
            .store(in: &cancellables)
    }

    private func loadPolicyValues() {
        switch settings.cleanupPolicy {
        case .ageBased(let months):
            cleanupPolicyType = .ageBased
            ageMonths = months
        case .countBased(let count):
            cleanupPolicyType = .countBased
            maxCount = count
        case .sizeBased(let mb):
            cleanupPolicyType = .sizeBased
            maxMB = mb
        }
    }

    private func updateCleanupPolicy(type: CleanupPolicyType, ageMonths: Int, maxCount: Int, maxMB: Int) {
        switch type {
        case .ageBased:
            settings.cleanupPolicy = .ageBased(months: ageMonths)
        case .countBased:
            settings.cleanupPolicy = .countBased(maxCount: maxCount)
        case .sizeBased:
            settings.cleanupPolicy = .sizeBased(maxMB: maxMB)
        }
    }
}
```

---

## 6. Feature 5: Auto Cleanup Service

### 6.1 Implementation

```swift
// Location: HoguMeter/Domain/Services/DataCleanupService.swift

import Foundation

/// Service for managing data cleanup
final class DataCleanupService {

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

    /// Perform cleanup based on settings
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
    func cleanupByAge(olderThan date: Date, routeOnly: Bool) {
        let summaries = tripRepository.getAllSummaries()

        for summary in summaries where summary.startTime < date {
            if routeOnly {
                routeDataManager.deleteRoute(tripId: summary.id)
            } else {
                tripRepository.delete(summary)
            }
        }
    }

    /// Keep only N most recent trips
    func cleanupByCount(keepRecent count: Int, routeOnly: Bool) {
        let summaries = tripRepository.getAllSummaries()
        guard summaries.count > count else { return }

        let toRemove = summaries.suffix(from: count)
        for summary in toRemove {
            if routeOnly {
                routeDataManager.deleteRoute(tripId: summary.id)
            } else {
                tripRepository.delete(summary)
            }
        }
    }

    /// Cleanup until total size is under limit
    func cleanupBySize(maxBytes: Int64, routeOnly: Bool) {
        var stats = getStorageStats()
        let summaries = tripRepository.getAllSummaries().reversed()  // Oldest first

        for summary in summaries {
            guard stats.totalSizeBytes > maxBytes else { break }

            if routeOnly {
                routeDataManager.deleteRoute(tripId: summary.id)
            } else {
                tripRepository.delete(summary)
            }

            stats = getStorageStats()
        }
    }

    /// Get current storage statistics
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

    /// Delete all data
    func deleteAllData() {
        tripRepository.deleteAll()
    }

    // MARK: - Private Methods

    private func estimateMetadataSize() -> Int64 {
        // Estimate ~500 bytes per TripSummary in UserDefaults
        return Int64(tripRepository.getTotalCount() * 500)
    }
}
```

### 6.2 Cleanup Triggers

Add to `AppDelegate` or `App` entry point:

```swift
// In HoguMeterApp.swift
@main
struct HoguMeterApp: App {
    init() {
        // Perform cleanup on app launch (background)
        DispatchQueue.global(qos: .background).async {
            DataCleanupService().performCleanupIfNeeded()
        }
    }
}
```

---

## 7. Feature 6: Storage Statistics

Already implemented in `DataCleanupService.getStorageStats()` and displayed in `DataManagementView`.

---

## 8. Data Migration

### 8.1 Migration Strategy

The migration is handled automatically in `TripRepository.migrateFromLegacy()`:

1. On first access to new storage key (`saved_trips_v2`)
2. Check for legacy data in `saved_trips`
3. For each legacy trip:
   - Extract route points
   - Save to compressed file via `RouteDataManager`
   - Create `TripSummary` without route points
4. Save all summaries to new storage
5. Delete legacy data

### 8.2 Migration is:
- **Automatic:** Triggered on first app launch after update
- **Non-blocking:** Can run in background
- **Resumable:** If interrupted, incomplete data is handled gracefully
- **One-time:** Legacy key is removed after successful migration

---

## 9. File Structure

```
HoguMeter/
├── Core/
│   └── Constants/
│       └── PaginationConfig.swift (new)
├── Domain/
│   ├── Entities/
│   │   ├── Trip.swift (unchanged)
│   │   ├── TripSummary.swift (new)
│   │   ├── RoutePoint.swift (unchanged)
│   │   ├── DataManagementSettings.swift (new)
│   │   └── StorageStats.swift (new)
│   └── Services/
│       ├── RouteManager.swift (unchanged)
│       ├── RouteOptimizer.swift (new)
│       ├── RouteDataManager.swift (new)
│       └── DataCleanupService.swift (new)
├── Data/
│   └── Repositories/
│       ├── TripRepository.swift (updated)
│       └── SettingsRepository.swift (updated)
├── Presentation/
│   ├── Views/
│   │   ├── History/
│   │   │   └── TripHistoryView.swift (updated)
│   │   └── Settings/
│   │       ├── SettingsView.swift (updated)
│   │       └── DataManagementView.swift (new)
│   └── ViewModels/
│       ├── TripHistoryViewModel.swift (new)
│       └── DataManagementViewModel.swift (new)
└── Tests/
    └── Unit/
        ├── RouteOptimizerTests.swift (new)
        ├── DataCleanupServiceTests.swift (new)
        └── TripPaginationTests.swift (new)
```

---

## 10. Test Cases

### 10.1 Route Optimization Tests
| ID | Test Case | Expected Result |
|----|-----------|-----------------|
| TC-001 | 5-second sampling on 60-minute trip | 80% reduction (3600 → ~720 points) |
| TC-002 | Douglas-Peucker preserves curves | Curves maintained within 10m tolerance |
| TC-003 | Compression ratio | 60%+ file size reduction |

### 10.2 Pagination Tests
| ID | Test Case | Expected Result |
|----|-----------|-----------------|
| TC-004 | Initial load | Returns exactly 20 items |
| TC-005 | Next page load | Correct offset, no duplicates |
| TC-006 | Prefetch trigger | Loads at 5 items from end |
| TC-007 | Empty state | hasMorePages = false when exhausted |

### 10.3 Cleanup Tests
| ID | Test Case | Expected Result |
|----|-----------|-----------------|
| TC-008 | Age-based cleanup | Deletes trips older than N months |
| TC-009 | Count-based cleanup | Keeps only N most recent |
| TC-010 | Size-based cleanup | Reduces to target size |
| TC-011 | Route-only cleanup | Preserves TripSummary metadata |

### 10.4 Storage Stats Tests
| ID | Test Case | Expected Result |
|----|-----------|-----------------|
| TC-012 | Route files size | Accurate byte count |
| TC-013 | Metadata size | Reasonable estimate (~500 bytes/trip) |

---

## 11. Implementation Phases

### Phase 1: Core Optimization
- RouteOptimizer.swift
- RouteDataManager.swift
- TripSummary.swift
- Updated TripRepository.swift
- TripHistoryViewModel.swift
- Updated TripHistoryView.swift

**Commit:**
```
feat: [Phase 1] Route sampling, separated storage, pagination

- Add 5-second coordinate sampling (80% reduction)
- Separate route data to compressed files
- Implement paginated trip list (20 items/page)
- Add lazy loading for route data
```

### Phase 2: User Settings
- DataManagementSettings.swift
- StorageStats.swift
- DataCleanupService.swift
- DataManagementView.swift
- DataManagementViewModel.swift
- Updated SettingsView.swift
- Updated SettingsRepository.swift

**Commit:**
```
feat: [Phase 2] Data management settings UI and auto cleanup

- Add data management settings screen
- Implement auto cleanup service (age/count/size based)
- Add manual cleanup options
```

### Phase 3: Polish & Migration
- PaginationConfig.swift
- Unit tests
- App launch cleanup trigger
- Migration testing

**Commit:**
```
feat: [Phase 3] Storage statistics and data migration

- Add storage usage calculation
- Implement migration for existing users
- Add unit tests for all features
```

---

## 12. Appendix

### A. Compression Benchmark

| Data Size | Uncompressed | Compressed (ZLIB) | Ratio |
|-----------|--------------|-------------------|-------|
| 100 points | 8 KB | 2.5 KB | 69% |
| 500 points | 40 KB | 12 KB | 70% |
| 1000 points | 80 KB | 23 KB | 71% |

### B. Memory Usage Comparison

| Scenario | Before | After |
|----------|--------|-------|
| List view (100 trips) | ~30 MB | ~500 KB |
| Detail view (1 trip) | ~300 KB | ~300 KB |
| Background memory | ~30 MB | ~500 KB |

### C. Performance Metrics

| Operation | Before | After |
|-----------|--------|-------|
| Initial list load | 500-2000ms | 50-100ms |
| Scroll performance | Laggy (all in memory) | Smooth (paginated) |
| Trip save | Instant | +50ms (compression) |
| Detail view open | Instant | +30ms (lazy load) |
