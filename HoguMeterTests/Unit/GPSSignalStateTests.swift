//
//  GPSSignalStateTests.swift
//  HoguMeterTests
//
//  GPS 신호 상태 테스트
//

import XCTest
import CoreLocation
@testable import HoguMeter

final class GPSSignalStateTests: XCTestCase {

    // MARK: - GPSSignalState.from(accuracy:) 테스트

    // MARK: 정상 신호 (< 30m)

    func test_정확도_0m_정상() {
        let state = GPSSignalState.from(accuracy: 0)
        XCTAssertEqual(state, .normal)
    }

    func test_정확도_10m_정상() {
        let state = GPSSignalState.from(accuracy: 10)
        XCTAssertEqual(state, .normal)
    }

    func test_정확도_29m_정상() {
        let state = GPSSignalState.from(accuracy: 29.9)
        XCTAssertEqual(state, .normal)
    }

    // MARK: 약한 신호 (30m ~ 100m)

    func test_정확도_30m_약함() {
        let state = GPSSignalState.from(accuracy: 30)
        XCTAssertEqual(state, .weak)
    }

    func test_정확도_50m_약함() {
        let state = GPSSignalState.from(accuracy: 50)
        XCTAssertEqual(state, .weak)
    }

    func test_정확도_99m_약함() {
        let state = GPSSignalState.from(accuracy: 99.9)
        XCTAssertEqual(state, .weak)
    }

    // MARK: 손실 신호 (>= 100m 또는 음수)

    func test_정확도_100m_손실() {
        let state = GPSSignalState.from(accuracy: 100)
        XCTAssertEqual(state, .lost)
    }

    func test_정확도_500m_손실() {
        let state = GPSSignalState.from(accuracy: 500)
        XCTAssertEqual(state, .lost)
    }

    func test_정확도_음수_손실() {
        let state = GPSSignalState.from(accuracy: -1)
        XCTAssertEqual(state, .lost)
    }

    // MARK: - 상태 전환 시나리오 테스트

    func test_상태전환_정상에서약함() {
        let normalState = GPSSignalState.from(accuracy: 20)
        let weakState = GPSSignalState.from(accuracy: 50)

        XCTAssertEqual(normalState, .normal)
        XCTAssertEqual(weakState, .weak)
        XCTAssertNotEqual(normalState, weakState)
    }

    func test_상태전환_약함에서손실() {
        let weakState = GPSSignalState.from(accuracy: 80)
        let lostState = GPSSignalState.from(accuracy: 150)

        XCTAssertEqual(weakState, .weak)
        XCTAssertEqual(lostState, .lost)
    }

    func test_상태전환_손실에서정상() {
        let lostState = GPSSignalState.from(accuracy: 200)
        let normalState = GPSSignalState.from(accuracy: 15)

        XCTAssertEqual(lostState, .lost)
        XCTAssertEqual(normalState, .normal)
    }

    func test_상태전환_전체순환() {
        // 정상 → 약함 → 손실 → 정상
        let states: [GPSSignalState] = [
            GPSSignalState.from(accuracy: 10),   // 정상
            GPSSignalState.from(accuracy: 50),   // 약함
            GPSSignalState.from(accuracy: 150),  // 손실
            GPSSignalState.from(accuracy: 5)     // 정상 복구
        ]

        XCTAssertEqual(states[0], .normal)
        XCTAssertEqual(states[1], .weak)
        XCTAssertEqual(states[2], .lost)
        XCTAssertEqual(states[3], .normal)
    }

    // MARK: - displayName 테스트

    func test_displayName_정상() {
        XCTAssertEqual(GPSSignalState.normal.displayName, "정상")
    }

    func test_displayName_약함() {
        XCTAssertEqual(GPSSignalState.weak.displayName, "약함")
    }

    func test_displayName_손실() {
        XCTAssertEqual(GPSSignalState.lost.displayName, "손실")
    }

    // MARK: - icon 테스트

    func test_icon_정상() {
        XCTAssertEqual(GPSSignalState.normal.icon, "location.fill")
    }

    func test_icon_약함() {
        XCTAssertEqual(GPSSignalState.weak.icon, "location")
    }

    func test_icon_손실() {
        XCTAssertEqual(GPSSignalState.lost.icon, "location.slash")
    }

    // MARK: - LastKnownLocationInfo 테스트

    func test_LastKnownLocationInfo_생성() {
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        let speed: Double = 50.0 / 3.6  // 50 km/h → m/s
        let signalLostAt = Date()

        let info = LastKnownLocationInfo(
            location: location,
            speed: speed,
            signalLostAt: signalLostAt
        )

        XCTAssertEqual(info.location.coordinate.latitude, 37.5665, accuracy: 0.0001)
        XCTAssertEqual(info.location.coordinate.longitude, 126.9780, accuracy: 0.0001)
        XCTAssertEqual(info.speed, speed, accuracy: 0.01)
    }

    func test_LastKnownLocationInfo_경과시간계산() {
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        let speed: Double = 50.0 / 3.6
        let signalLostAt = Date().addingTimeInterval(-10)  // 10초 전

        let info = LastKnownLocationInfo(
            location: location,
            speed: speed,
            signalLostAt: signalLostAt
        )

        // 약간의 시간 오차 허용
        XCTAssertEqual(info.elapsedSinceSignalLost, 10, accuracy: 0.5)
    }

    func test_LastKnownLocationInfo_추정거리계산() {
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        let speed: Double = 10.0  // 10 m/s = 36 km/h
        let signalLostAt = Date().addingTimeInterval(-5)  // 5초 전

        let info = LastKnownLocationInfo(
            location: location,
            speed: speed,
            signalLostAt: signalLostAt
        )

        // 예상 거리: 10 m/s × 5초 = 50m
        XCTAssertEqual(info.estimatedDistance, 50, accuracy: 5)
    }

    func test_LastKnownLocationInfo_속도0일때_추정거리0() {
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        let speed: Double = 0
        let signalLostAt = Date().addingTimeInterval(-10)

        let info = LastKnownLocationInfo(
            location: location,
            speed: speed,
            signalLostAt: signalLostAt
        )

        XCTAssertEqual(info.estimatedDistance, 0)
    }

    func test_LastKnownLocationInfo_음수속도_추정거리0() {
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        let speed: Double = -5
        let signalLostAt = Date().addingTimeInterval(-10)

        let info = LastKnownLocationInfo(
            location: location,
            speed: speed,
            signalLostAt: signalLostAt
        )

        XCTAssertEqual(info.estimatedDistance, 0)
    }

    // MARK: - 경계값 테스트

    func test_경계값_29점9m_정상() {
        XCTAssertEqual(GPSSignalState.from(accuracy: 29.9), .normal)
    }

    func test_경계값_30점0m_약함() {
        XCTAssertEqual(GPSSignalState.from(accuracy: 30.0), .weak)
    }

    func test_경계값_99점9m_약함() {
        XCTAssertEqual(GPSSignalState.from(accuracy: 99.9), .weak)
    }

    func test_경계값_100점0m_손실() {
        XCTAssertEqual(GPSSignalState.from(accuracy: 100.0), .lost)
    }
}
