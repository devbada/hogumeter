//
//  FareTimeZoneTests.swift
//  HoguMeterTests
//
//  시간대 판별 로직 테스트
//

import XCTest
@testable import HoguMeter

final class FareTimeZoneTests: XCTestCase {

    // MARK: - 주간 시간대 테스트 (04:00 ~ 22:00)

    func test_04시00분_주간() {
        let date = createDate(hour: 4, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .day)
    }

    func test_12시00분_주간() {
        let date = createDate(hour: 12, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .day)
    }

    func test_21시59분_주간() {
        let date = createDate(hour: 21, minute: 59)
        XCTAssertEqual(FareTimeZone.current(from: date), .day)
    }

    // MARK: - 심야1 시간대 테스트 (22:00 ~ 23:00, 02:00 ~ 04:00)

    func test_22시00분_심야1() {
        let date = createDate(hour: 22, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .night1)
    }

    func test_22시30분_심야1() {
        let date = createDate(hour: 22, minute: 30)
        XCTAssertEqual(FareTimeZone.current(from: date), .night1)
    }

    func test_22시59분_심야1() {
        let date = createDate(hour: 22, minute: 59)
        XCTAssertEqual(FareTimeZone.current(from: date), .night1)
    }

    func test_02시00분_심야1() {
        let date = createDate(hour: 2, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .night1)
    }

    func test_03시00분_심야1() {
        let date = createDate(hour: 3, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .night1)
    }

    func test_03시59분_심야1() {
        let date = createDate(hour: 3, minute: 59)
        XCTAssertEqual(FareTimeZone.current(from: date), .night1)
    }

    // MARK: - 심야2 시간대 테스트 (23:00 ~ 02:00)

    func test_23시00분_심야2() {
        let date = createDate(hour: 23, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .night2)
    }

    func test_23시30분_심야2() {
        let date = createDate(hour: 23, minute: 30)
        XCTAssertEqual(FareTimeZone.current(from: date), .night2)
    }

    func test_00시00분_심야2() {
        let date = createDate(hour: 0, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .night2)
    }

    func test_00시30분_심야2() {
        let date = createDate(hour: 0, minute: 30)
        XCTAssertEqual(FareTimeZone.current(from: date), .night2)
    }

    func test_01시00분_심야2() {
        let date = createDate(hour: 1, minute: 0)
        XCTAssertEqual(FareTimeZone.current(from: date), .night2)
    }

    func test_01시59분_심야2() {
        let date = createDate(hour: 1, minute: 59)
        XCTAssertEqual(FareTimeZone.current(from: date), .night2)
    }

    // MARK: - 할증률 테스트

    func test_주간_할증률() {
        XCTAssertEqual(FareTimeZone.day.surchargeRate, 0.0)
    }

    func test_심야1_할증률() {
        XCTAssertEqual(FareTimeZone.night1.surchargeRate, 0.2)
    }

    func test_심야2_할증률() {
        XCTAssertEqual(FareTimeZone.night2.surchargeRate, 0.4)
    }

    // MARK: - Helper

    private func createDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}
