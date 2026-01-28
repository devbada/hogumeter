//
//  CoachMarkManagerTests.swift
//  HoguMeterTests
//
//  Created for Onboarding Coach Mark System.
//

import XCTest
@testable import HoguMeter

@MainActor
final class CoachMarkManagerTests: XCTestCase {

    var sut: CoachMarkManager!

    override func setUp() {
        super.setUp()
        sut = CoachMarkManager.shared
        // Reset all coach marks before each test
        sut.resetAllCoachMarks()
    }

    override func tearDown() {
        sut.resetAllCoachMarks()
        sut = nil
        super.tearDown()
    }

    // MARK: - TC-001: First app launch → Main screen shows coach marks

    func testShouldShowCoachMarksForMainScreenOnFirstLaunch() {
        // Given: Fresh state (reset in setUp)

        // When/Then
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "main"))
    }

    // MARK: - TC-002: First visit to History tab → History coach marks appear

    func testShouldShowCoachMarksForHistoryScreenOnFirstVisit() {
        // Given: Fresh state

        // When/Then
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "history"))
    }

    // MARK: - TC-003: First visit to Settings tab → Settings coach marks appear

    func testShouldShowCoachMarksForSettingsScreenOnFirstVisit() {
        // Given: Fresh state

        // When/Then
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "settings"))
    }

    // MARK: - TC-004: First time opening map during trip → Map coach marks appear

    func testShouldShowCoachMarksForMapScreenOnFirstOpen() {
        // Given: Fresh state

        // When/Then
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "map"))
    }

    // MARK: - TC-005: "다음" advances through all coach marks in order

    func testNextCoachMarkAdvancesThroughMarks() {
        // Given: Started coach marks for main screen
        sut.startCoachMarks(for: "main")
        XCTAssertEqual(sut.currentMarkIndex, 0)

        // When: Advance to next
        sut.nextCoachMark()

        // Then: Index should be 1
        XCTAssertEqual(sut.currentMarkIndex, 1)
    }

    // MARK: - TC-006: "건너뛰기" completes coach marks for that screen

    func testSkipCoachMarksCompletesCurrentScreen() {
        // Given: Started coach marks for main screen
        sut.startCoachMarks(for: "main")
        XCTAssertTrue(sut.isShowingCoachMark)

        // When: Skip
        sut.skipCoachMarks()

        // Then: Coach marks should be hidden and main should be completed
        XCTAssertFalse(sut.isShowingCoachMark)
        XCTAssertFalse(sut.shouldShowCoachMarks(for: "main"))
    }

    // MARK: - TC-007: Subsequent visits don't show coach marks again

    func testSubsequentVisitsDoNotShowCoachMarks() {
        // Given: Main screen coach marks completed
        sut.startCoachMarks(for: "main")
        sut.skipCoachMarks()

        // When/Then
        XCTAssertFalse(sut.shouldShowCoachMarks(for: "main"))
    }

    // MARK: - TC-008: "가이드 다시 보기" resets all screens

    func testResetAllCoachMarksResetsAllScreens() {
        // Given: All screens completed
        sut.startCoachMarks(for: "main")
        sut.skipCoachMarks()
        sut.startCoachMarks(for: "map")
        sut.skipCoachMarks()
        sut.startCoachMarks(for: "history")
        sut.skipCoachMarks()
        sut.startCoachMarks(for: "settings")
        sut.skipCoachMarks()

        // When: Reset all
        sut.resetAllCoachMarks()

        // Then: All screens should show coach marks again
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "main"))
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "map"))
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "history"))
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "settings"))
    }

    // MARK: - TC-009: After reset, visiting each screen shows coach marks again

    func testAfterResetCoachMarksShowAgain() {
        // Given: Main completed then reset
        sut.startCoachMarks(for: "main")
        sut.skipCoachMarks()
        XCTAssertFalse(sut.shouldShowCoachMarks(for: "main"))

        sut.resetAllCoachMarks()

        // When/Then: Main should show coach marks again
        XCTAssertTrue(sut.shouldShowCoachMarks(for: "main"))
    }

    // MARK: - Additional Tests

    func testStartCoachMarksSetsCorrectState() {
        // When
        sut.startCoachMarks(for: "main")

        // Then
        XCTAssertTrue(sut.isShowingCoachMark)
        XCTAssertEqual(sut.currentScreenId, "main")
        XCTAssertEqual(sut.currentMarkIndex, 0)
    }

    func testCurrentCoachMarkReturnsCorrectMark() {
        // Given
        sut.startCoachMarks(for: "main")

        // When
        let currentMark = sut.currentCoachMark

        // Then
        XCTAssertNotNil(currentMark)
        XCTAssertEqual(currentMark?.id, "main_fare")
    }

    func testCompleteCurrentScreenMarksScreenAsCompleted() {
        // Given
        sut.startCoachMarks(for: "main")

        // When
        sut.completeCurrentScreen()

        // Then
        XCTAssertFalse(sut.isShowingCoachMark)
        XCTAssertNil(sut.currentScreenId)
        XCTAssertFalse(sut.shouldShowCoachMarks(for: "main"))
    }

    func testCurrentScreenCoachMarkCountReturnsCorrectCount() {
        // Given
        sut.startCoachMarks(for: "main")

        // When
        let count = sut.currentScreenCoachMarkCount

        // Then
        XCTAssertEqual(count, 4) // Main screen has 4 coach marks
    }

    func testNextCoachMarkOnLastMarkCompletesScreen() {
        // Given
        sut.startCoachMarks(for: "history")  // History has 2 marks

        // When: Advance through all marks
        sut.nextCoachMark()  // Now at index 1 (last mark)
        sut.nextCoachMark()  // Should complete

        // Then
        XCTAssertFalse(sut.isShowingCoachMark)
        XCTAssertFalse(sut.shouldShowCoachMarks(for: "history"))
    }
}
