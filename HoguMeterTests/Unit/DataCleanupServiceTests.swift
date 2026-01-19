//
//  DataCleanupServiceTests.swift
//  HoguMeterTests
//
//  Created on 2026-01-19.
//

import XCTest
@testable import HoguMeter

final class DataCleanupServiceTests: XCTestCase {

    // MARK: - Properties
    private var cleanupService: DataCleanupService!
    private var tripRepository: TripRepository!
    private var testUserDefaults: UserDefaults!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Use a separate UserDefaults suite for testing
        testUserDefaults = UserDefaults(suiteName: "DataCleanupServiceTests")!
        testUserDefaults.removePersistentDomain(forName: "DataCleanupServiceTests")

        tripRepository = TripRepository(userDefaults: testUserDefaults)
        cleanupService = DataCleanupService(
            tripRepository: tripRepository,
            routeDataManager: .shared,
            settingsRepository: SettingsRepository(userDefaults: testUserDefaults)
        )
    }

    override func tearDown() {
        // Clean up test data
        tripRepository.deleteAll()
        testUserDefaults.removePersistentDomain(forName: "DataCleanupServiceTests")
        testUserDefaults = nil
        tripRepository = nil
        cleanupService = nil

        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestTrip(startTime: Date = Date()) -> Trip {
        return Trip(
            id: UUID(),
            startTime: startTime,
            endTime: startTime.addingTimeInterval(3600),
            totalFare: 15000,
            distance: 10.5,
            duration: 3600,
            startRegion: "강남구",
            endRegion: "서초구",
            regionChanges: 1,
            isNightTrip: false,
            fareBreakdown: FareBreakdown(
                baseFare: 4800,
                distanceFare: 7200,
                timeFare: 3000,
                regionSurcharge: 0,
                nightSurcharge: 0
            ),
            routePoints: [],
            driverQuote: nil,
            surchargeMode: .realistic,
            surchargeRate: 0
        )
    }

    // MARK: - Storage Stats Tests

    /// TC-012: Storage stats returns correct trip count
    func testStorageStatsReturnsCorrectTripCount() {
        // Given: 5 saved trips
        for _ in 0..<5 {
            tripRepository.save(createTestTrip())
        }

        // When: Get storage stats
        let stats = cleanupService.getStorageStats()

        // Then: Should report 5 trips
        XCTAssertEqual(stats.totalTripCount, 5)
    }

    /// TC-013: Storage stats calculates reasonable metadata size
    func testStorageStatsCalculatesMetadataSize() {
        // Given: 10 saved trips
        for _ in 0..<10 {
            tripRepository.save(createTestTrip())
        }

        // When: Get storage stats
        let stats = cleanupService.getStorageStats()

        // Then: Metadata size should be positive and reasonable
        // Estimate: ~500 bytes per TripSummary
        XCTAssertGreaterThan(stats.metadataSizeBytes, 0)
        XCTAssertLessThan(stats.metadataSizeBytes, 100_000)  // Less than 100KB for 10 trips
    }

    // MARK: - Age-Based Cleanup Tests

    /// TC-008: Age-based cleanup deletes old trips
    func testAgeBasedCleanupDeletesOldTrips() {
        // Given: 3 trips - 1 recent, 2 old (4 months ago)
        let recentTrip = createTestTrip(startTime: Date())
        let oldTrip1 = createTestTrip(startTime: Calendar.current.date(byAdding: .month, value: -4, to: Date())!)
        let oldTrip2 = createTestTrip(startTime: Calendar.current.date(byAdding: .month, value: -5, to: Date())!)

        tripRepository.save(recentTrip)
        tripRepository.save(oldTrip1)
        tripRepository.save(oldTrip2)

        // When: Cleanup trips older than 3 months
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let cleanedCount = cleanupService.cleanupByAge(olderThan: cutoffDate, routeOnly: false)

        // Then: 2 old trips should be deleted
        XCTAssertEqual(cleanedCount, 2)
        XCTAssertEqual(tripRepository.getTotalCount(), 1)
    }

    // MARK: - Count-Based Cleanup Tests

    /// TC-009: Count-based cleanup keeps N most recent
    func testCountBasedCleanupKeepsNMostRecent() {
        // Given: 10 trips
        for i in 0..<10 {
            let trip = createTestTrip(startTime: Date().addingTimeInterval(TimeInterval(i * 3600)))
            tripRepository.save(trip)
        }

        // When: Keep only 5 most recent
        let cleanedCount = cleanupService.cleanupByCount(keepRecent: 5, routeOnly: false)

        // Then: 5 trips should be deleted, 5 remain
        XCTAssertEqual(cleanedCount, 5)
        XCTAssertEqual(tripRepository.getTotalCount(), 5)
    }

    /// Test count-based cleanup does nothing when below limit
    func testCountBasedCleanupDoesNothingWhenBelowLimit() {
        // Given: 3 trips
        for _ in 0..<3 {
            tripRepository.save(createTestTrip())
        }

        // When: Keep 10 most recent (more than we have)
        let cleanedCount = cleanupService.cleanupByCount(keepRecent: 10, routeOnly: false)

        // Then: Nothing should be deleted
        XCTAssertEqual(cleanedCount, 0)
        XCTAssertEqual(tripRepository.getTotalCount(), 3)
    }

    // MARK: - Route-Only Cleanup Tests

    /// TC-011: Route-only cleanup preserves metadata
    func testRouteOnlyCleanupPreservesMetadata() {
        // Given: 3 trips
        for _ in 0..<3 {
            tripRepository.save(createTestTrip())
        }
        let initialCount = tripRepository.getTotalCount()

        // When: Age-based cleanup with route-only
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        _ = cleanupService.cleanupByAge(olderThan: cutoffDate, routeOnly: true)

        // Then: Trip count should remain the same (only routes deleted)
        XCTAssertEqual(tripRepository.getTotalCount(), initialCount)
    }

    // MARK: - Delete All Tests

    func testDeleteAllDataRemovesEverything() {
        // Given: 5 trips
        for _ in 0..<5 {
            tripRepository.save(createTestTrip())
        }
        XCTAssertEqual(tripRepository.getTotalCount(), 5)

        // When: Delete all
        cleanupService.deleteAllData()

        // Then: No trips remain
        XCTAssertEqual(tripRepository.getTotalCount(), 0)
    }
}
