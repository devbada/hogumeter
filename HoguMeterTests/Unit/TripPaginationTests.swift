//
//  TripPaginationTests.swift
//  HoguMeterTests
//
//  Created on 2026-01-19.
//

import XCTest
@testable import HoguMeter

final class TripPaginationTests: XCTestCase {

    // MARK: - Properties
    private var tripRepository: TripRepository!
    private var testUserDefaults: UserDefaults!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Use a separate UserDefaults suite for testing
        testUserDefaults = UserDefaults(suiteName: "TripPaginationTests")!
        testUserDefaults.removePersistentDomain(forName: "TripPaginationTests")

        tripRepository = TripRepository(userDefaults: testUserDefaults)
    }

    override func tearDown() {
        tripRepository.deleteAll()
        testUserDefaults.removePersistentDomain(forName: "TripPaginationTests")
        testUserDefaults = nil
        tripRepository = nil

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

    private func populateTestTrips(count: Int) {
        for i in 0..<count {
            let trip = createTestTrip(startTime: Date().addingTimeInterval(TimeInterval(i * -3600)))
            tripRepository.save(trip)
        }
    }

    // MARK: - Pagination Tests

    /// TC-004: Initial load returns exactly pageSize items
    func testInitialLoadReturnsPageSizeItems() {
        // Given: 50 trips
        populateTestTrips(count: 50)

        // When: Load first page with pageSize 20
        let page0 = tripRepository.getSummaries(page: 0, pageSize: 20)

        // Then: Should return exactly 20 items
        XCTAssertEqual(page0.count, 20)
    }

    /// TC-005: Next page loads correctly with offset
    func testNextPageLoadsWithCorrectOffset() {
        // Given: 50 trips
        populateTestTrips(count: 50)

        // When: Load first two pages
        let page0 = tripRepository.getSummaries(page: 0, pageSize: 20)
        let page1 = tripRepository.getSummaries(page: 1, pageSize: 20)

        // Then: Pages should have different items
        XCTAssertEqual(page0.count, 20)
        XCTAssertEqual(page1.count, 20)

        // No overlapping IDs
        let page0Ids = Set(page0.map { $0.id })
        let page1Ids = Set(page1.map { $0.id })
        XCTAssertTrue(page0Ids.isDisjoint(with: page1Ids), "Pages should not have overlapping items")
    }

    /// TC-007: Empty state when no more pages
    func testEmptyStateWhenNoMorePages() {
        // Given: 25 trips
        populateTestTrips(count: 25)

        // When: Load page beyond available data
        let page0 = tripRepository.getSummaries(page: 0, pageSize: 20)
        let page1 = tripRepository.getSummaries(page: 1, pageSize: 20)  // Should have 5 items
        let page2 = tripRepository.getSummaries(page: 2, pageSize: 20)  // Should be empty

        // Then: Page 2 should be empty
        XCTAssertEqual(page0.count, 20)
        XCTAssertEqual(page1.count, 5)
        XCTAssertTrue(page2.isEmpty, "Page beyond data should be empty")
    }

    /// Test getTotalCount returns correct count
    func testGetTotalCountReturnsCorrectCount() {
        // Given: 35 trips
        populateTestTrips(count: 35)

        // When: Get total count
        let totalCount = tripRepository.getTotalCount()

        // Then: Should return 35
        XCTAssertEqual(totalCount, 35)
    }

    /// Test pagination with default page size
    func testPaginationWithDefaultPageSize() {
        // Given: 50 trips
        populateTestTrips(count: 50)

        // When: Use default page size (from PaginationConfig)
        let page = tripRepository.getSummaries(page: 0)

        // Then: Should return PaginationConfig.pageSize items
        XCTAssertEqual(page.count, PaginationConfig.pageSize)
    }

    /// Test all items can be retrieved through pagination
    func testAllItemsRetrievableThroughPagination() {
        // Given: 55 trips
        populateTestTrips(count: 55)
        let pageSize = 20

        // When: Load all pages
        var allItems: [TripSummary] = []
        var page = 0

        while true {
            let items = tripRepository.getSummaries(page: page, pageSize: pageSize)
            if items.isEmpty { break }
            allItems.append(contentsOf: items)
            page += 1
        }

        // Then: Should have retrieved all 55 items
        XCTAssertEqual(allItems.count, 55)

        // All IDs should be unique
        let uniqueIds = Set(allItems.map { $0.id })
        XCTAssertEqual(uniqueIds.count, 55, "All items should have unique IDs")
    }

    /// Test empty repository pagination
    func testEmptyRepositoryPagination() {
        // Given: Empty repository
        // When: Try to get first page
        let page = tripRepository.getSummaries(page: 0, pageSize: 20)

        // Then: Should return empty array
        XCTAssertTrue(page.isEmpty)
    }
}
