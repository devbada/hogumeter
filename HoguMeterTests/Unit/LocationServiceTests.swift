//
//  LocationServiceTests.swift
//  HoguMeterTests
//
//  LocationService GPS 신호 감지 및 Dead Reckoning 통합 테스트
//

import XCTest
import CoreLocation
import Combine
@testable import HoguMeter

final class LocationServiceTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - LocationServiceProtocol 프로퍼티 존재 확인 테스트

    func test_LocationServiceProtocol_isEstimatedDistance_존재() {
        // LocationServiceProtocol에 isEstimatedDistance가 정의되어 있는지 확인
        let mockService = MockLocationServiceForGPS()
        XCTAssertFalse(mockService.isEstimatedDistance)
    }

    func test_LocationServiceProtocol_deadReckoningState_존재() {
        let mockService = MockLocationServiceForGPS()
        XCTAssertEqual(mockService.deadReckoningState, .inactive)
    }

    func test_LocationServiceProtocol_estimatedDistance_존재() {
        let mockService = MockLocationServiceForGPS()
        XCTAssertEqual(mockService.estimatedDistance, 0)
    }

    func test_LocationServiceProtocol_gpsSignalState_존재() {
        let mockService = MockLocationServiceForGPS()
        XCTAssertEqual(mockService.gpsSignalState, .normal)
    }

    func test_LocationServiceProtocol_lastKnownLocationInfo_존재() {
        let mockService = MockLocationServiceForGPS()
        XCTAssertNil(mockService.lastKnownLocationInfo)
    }

    // MARK: - GPS 신호 상태 전환 시나리오 테스트

    func test_GPS정상에서손실_DeadReckoning시작() {
        let mockService = MockLocationServiceForGPS()

        mockService.simulateTunnelEntry(lastSpeed: 80)  // 80 km/h

        XCTAssertEqual(mockService.gpsSignalState, .lost)
        XCTAssertEqual(mockService.deadReckoningState, .active)
        XCTAssertTrue(mockService.isEstimatedDistance)
        XCTAssertNotNil(mockService.lastKnownLocationInfo)
    }

    func test_GPS손실에서정상_DeadReckoning중지_거리반영() {
        let mockService = MockLocationServiceForGPS()

        // 터널 진입
        mockService.simulateTunnelEntry(lastSpeed: 80)
        XCTAssertEqual(mockService.gpsSignalState, .lost)

        // 터널 탈출 (추정 거리 100m 반영)
        mockService.simulateTunnelExit(estimatedDistanceToAdd: 100)

        XCTAssertEqual(mockService.gpsSignalState, .normal)
        XCTAssertEqual(mockService.deadReckoningState, .inactive)
        XCTAssertFalse(mockService.isEstimatedDistance)
        XCTAssertEqual(mockService.totalDistance, 100, accuracy: 0.1)
    }

    func test_터널시나리오_전체흐름() {
        let mockService = MockLocationServiceForGPS()

        // 1. 주행 시작
        mockService.startTracking()
        XCTAssertEqual(mockService.gpsSignalState, .normal)

        // 2. 일반 주행 (100m 이동)
        mockService.totalDistance = 100

        // 3. 터널 진입 (마지막 속도 60 km/h)
        mockService.simulateTunnelEntry(lastSpeed: 60)
        XCTAssertEqual(mockService.gpsSignalState, .lost)
        XCTAssertNotNil(mockService.lastKnownLocationInfo)

        // 4. 터널 내부에서 추정 거리 누적 (예: 500m)
        mockService.estimatedDistance = 500

        // 5. 터널 탈출 (추정 거리 반영)
        mockService.simulateTunnelExit(estimatedDistanceToAdd: 500)

        // 6. 검증: 총 거리 = 기존 100m + 추정 500m = 600m
        XCTAssertEqual(mockService.totalDistance, 600, accuracy: 0.1)
        XCTAssertEqual(mockService.gpsSignalState, .normal)
    }

    // MARK: - startTracking / stopTracking 호출 테스트

    func test_startTracking호출_추적카운트증가() {
        let mockService = MockLocationServiceForGPS()

        mockService.startTracking()
        mockService.startTracking()

        XCTAssertEqual(mockService.startTrackingCallCount, 2)
    }

    func test_stopTracking호출_추적카운트증가() {
        let mockService = MockLocationServiceForGPS()

        mockService.stopTracking()

        XCTAssertEqual(mockService.stopTrackingCallCount, 1)
    }

    // MARK: - 정차 상태에서 GPS 손실 테스트

    func test_정차상태_GPS손실_DeadReckoning미시작() {
        let mockService = MockLocationServiceForGPS()

        // 속도 0에서 터널 진입
        mockService.simulateTunnelEntry(lastSpeed: 0)

        // GPS는 손실되지만 속도가 0이므로 Dead Reckoning이 의미 없음
        XCTAssertEqual(mockService.gpsSignalState, .lost)

        // lastKnownLocationInfo의 speed가 0
        XCTAssertEqual(mockService.lastKnownLocationInfo?.speed, 0)

        // 추정 거리도 0이어야 함
        XCTAssertEqual(mockService.lastKnownLocationInfo?.estimatedDistance ?? 0, 0)
    }

    // MARK: - Reset 테스트

    func test_reset_모든상태초기화() {
        let mockService = MockLocationServiceForGPS()

        // 상태 변경
        mockService.simulateTunnelEntry(lastSpeed: 80)
        mockService.totalDistance = 500
        mockService.highSpeedDistance = 400
        mockService.lowSpeedDuration = 60

        // 리셋
        mockService.reset()

        // 검증
        XCTAssertEqual(mockService.gpsSignalState, .normal)
        XCTAssertEqual(mockService.deadReckoningState, .inactive)
        XCTAssertFalse(mockService.isEstimatedDistance)
        XCTAssertEqual(mockService.totalDistance, 0)
        XCTAssertEqual(mockService.highSpeedDistance, 0)
        XCTAssertEqual(mockService.lowSpeedDuration, 0)
        XCTAssertNil(mockService.lastKnownLocationInfo)
    }
}

// MARK: - MockDeadReckoningService 테스트

final class MockDeadReckoningServiceTests: XCTestCase {

    var sut: MockDeadReckoningService!

    override func setUp() {
        super.setUp()
        sut = MockDeadReckoningService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_start_호출카운트증가() {
        let locationInfo = createLocationInfo(speedKmh: 50)

        sut.start(with: locationInfo)

        XCTAssertEqual(sut.startCallCount, 1)
        XCTAssertNotNil(sut.lastStartLocationInfo)
    }

    func test_stop_호출카운트증가() {
        let locationInfo = createLocationInfo(speedKmh: 50)
        sut.start(with: locationInfo)

        _ = sut.stop()

        XCTAssertEqual(sut.stopCallCount, 1)
    }

    func test_reset_호출카운트증가() {
        sut.reset()

        XCTAssertEqual(sut.resetCallCount, 1)
    }

    func test_simulatedValues_stop시반환() {
        let locationInfo = createLocationInfo(speedKmh: 50)
        sut.simulatedEstimatedDistance = 500
        sut.simulatedElapsedTime = 30
        sut.simulatedIsExpired = false

        sut.start(with: locationInfo)
        let result = sut.stop()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.estimatedDistance, 500)
        XCTAssertEqual(result?.elapsedTime, 30)
        XCTAssertFalse(result?.isExpired ?? true)
    }

    func test_simulateExpiration_상태변경() {
        let locationInfo = createLocationInfo(speedKmh: 50)
        sut.start(with: locationInfo)

        sut.simulateExpiration()

        XCTAssertEqual(sut.state, .expired)
        XCTAssertTrue(sut.simulatedIsExpired)
    }

    // MARK: - Helper

    private func createLocationInfo(speedKmh: Double) -> LastKnownLocationInfo {
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        return LastKnownLocationInfo(
            location: location,
            speed: speedKmh / 3.6,
            signalLostAt: Date()
        )
    }
}

// MARK: - MockCLLocationManager 테스트

final class MockCLLocationManagerTests: XCTestCase {

    func test_createLocation_정확도설정() {
        let location = MockCLLocationManager.createLocation(accuracy: 50)

        XCTAssertEqual(location.horizontalAccuracy, 50)
    }

    func test_createLocation_속도설정() {
        let speedMps = 50.0 / 3.6  // 50 km/h
        let location = MockCLLocationManager.createLocation(speed: speedMps)

        XCTAssertEqual(location.speed, speedMps, accuracy: 0.01)
    }

    func test_createNormalSignalSequence_정확도30미만() {
        let locations = MockCLLocationManager.createNormalSignalSequence(count: 5)

        XCTAssertEqual(locations.count, 5)
        for location in locations {
            XCTAssertLessThan(location.horizontalAccuracy, 30)
        }
    }

    func test_createWeakSignalSequence_정확도30에서100() {
        let locations = MockCLLocationManager.createWeakSignalSequence(count: 5)

        XCTAssertEqual(locations.count, 5)
        for location in locations {
            XCTAssertGreaterThanOrEqual(location.horizontalAccuracy, 30)
            XCTAssertLessThan(location.horizontalAccuracy, 100)
        }
    }

    func test_createLostSignalSequence_정확도100이상() {
        let locations = MockCLLocationManager.createLostSignalSequence(count: 5)

        XCTAssertEqual(locations.count, 5)
        for location in locations {
            XCTAssertGreaterThanOrEqual(location.horizontalAccuracy, 100)
        }
    }

    func test_createTunnelScenario_시퀀스생성() {
        let locations = MockCLLocationManager.createTunnelScenario()

        // 최소 15개 위치 (정상3 + 약함2 + 손실5 + 약함2 + 정상3)
        XCTAssertGreaterThanOrEqual(locations.count, 15)

        // 첫 3개는 정상 신호
        for i in 0..<3 {
            XCTAssertLessThan(locations[i].horizontalAccuracy, 30)
        }

        // 마지막 3개도 정상 신호
        for i in (locations.count - 3)..<locations.count {
            XCTAssertLessThan(locations[i].horizontalAccuracy, 30)
        }
    }
}
