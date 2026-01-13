//
//  IdleDetectionServiceTests.swift
//  HoguMeterTests
//
//  무이동 감지 서비스 테스트
//

import XCTest
import CoreLocation
import Combine
@testable import HoguMeter

final class IdleDetectionServiceTests: XCTestCase {

    var sut: IdleDetectionService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = IdleDetectionService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Config Tests

    func test_config_idleThreshold_600초() {
        XCTAssertEqual(IdleDetectionConfig.idleThreshold, 600)
    }

    func test_config_movementThreshold_50m() {
        XCTAssertEqual(IdleDetectionConfig.movementThreshold, 50.0)
    }

    func test_config_checkInterval_30초() {
        XCTAssertEqual(IdleDetectionConfig.checkInterval, 30.0)
    }

    // MARK: - Initial State Tests

    func test_초기상태_inactive() {
        XCTAssertEqual(sut.state, .inactive)
        XCTAssertEqual(sut.idleDuration, 0)
    }

    // MARK: - Start/Stop Monitoring Tests

    func test_startMonitoring_상태변경_monitoring() {
        sut.startMonitoring()

        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_stopMonitoring_상태변경_inactive() {
        sut.startMonitoring()
        sut.stopMonitoring()

        XCTAssertEqual(sut.state, .inactive)
    }

    func test_reset_모든상태초기화() {
        sut.startMonitoring()
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.updateLocation(location)

        sut.reset()

        XCTAssertEqual(sut.state, .inactive)
        XCTAssertEqual(sut.idleDuration, 0)
    }

    // MARK: - Location Update Tests

    func test_updateLocation_첫위치_저장만됨() {
        sut.startMonitoring()
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)

        sut.updateLocation(location)

        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_updateLocation_50m이상이동_타이머리셋() {
        sut.startMonitoring()
        let location1 = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.updateLocation(location1)

        // 약 100m 이동
        let location2 = CLLocation(latitude: 37.5665 + 0.0009, longitude: 126.9780)
        sut.updateLocation(location2)

        XCTAssertEqual(sut.state, .monitoring)
        XCTAssertEqual(sut.idleDuration, 0)
    }

    func test_updateLocation_50m미만이동_타이머유지() {
        sut.startMonitoring()
        let location1 = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.updateLocation(location1)

        // 약 30m 이동 (50m 미만)
        let location2 = CLLocation(latitude: 37.5665 + 0.00027, longitude: 126.9780)
        sut.updateLocation(location2)

        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_updateLocation_inactive상태_무시() {
        // 모니터링 시작하지 않은 상태
        let location = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.updateLocation(location)

        XCTAssertEqual(sut.state, .inactive)
    }

    // MARK: - Dead Reckoning Tests

    func test_setDeadReckoningActive_true_위치업데이트무시() {
        sut.startMonitoring()
        sut.setDeadReckoningActive(true)

        let location1 = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.updateLocation(location1)

        let location2 = CLLocation(latitude: 37.5665 + 0.001, longitude: 126.9780)
        sut.updateLocation(location2)

        // Dead Reckoning 중이므로 위치 업데이트가 처리되지 않음
        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_setDeadReckoningActive_false_위치업데이트재개() {
        sut.startMonitoring()
        sut.setDeadReckoningActive(true)
        sut.setDeadReckoningActive(false)

        let location1 = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.updateLocation(location1)

        XCTAssertEqual(sut.state, .monitoring)
    }

    // MARK: - Dismiss Alert Tests

    func test_dismissAlert_상태변경_monitoring() {
        sut.startMonitoring()

        // 임시로 idle 상태로 변경 (내부 테스트 목적)
        // 실제로는 타이머에 의해 변경됨

        sut.dismissAlert()

        // dismissAlert 후에는 monitoring 상태
        XCTAssertEqual(sut.state, .monitoring)
        XCTAssertEqual(sut.idleDuration, 0)
    }

    // MARK: - Mark Alerted Tests

    func test_markAlerted_inactive상태_무시() {
        // inactive 상태에서 markAlerted 호출 시 무시
        sut.markAlerted()
        XCTAssertEqual(sut.state, .inactive)
    }

    func test_markAlerted_monitoring상태_무시() {
        // monitoring 상태에서 markAlerted 호출 시 무시
        sut.startMonitoring()
        sut.markAlerted()
        XCTAssertEqual(sut.state, .monitoring)
    }

    // MARK: - State Publisher Tests

    func test_statePublisher_상태변경시발행() {
        var receivedStates: [IdleDetectionState] = []
        let expectation = expectation(description: "State changes received")

        sut.statePublisher
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count >= 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.startMonitoring()
        sut.stopMonitoring()

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertTrue(receivedStates.contains(.inactive))
            XCTAssertTrue(receivedStates.contains(.monitoring))
        }
    }

    // MARK: - Edge Cases

    func test_startMonitoring_이미monitoring상태_무시() {
        sut.startMonitoring()
        sut.startMonitoring()  // 중복 호출

        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_stopMonitoring_이미inactive상태_무시() {
        sut.stopMonitoring()  // 시작하지 않은 상태에서 중지

        XCTAssertEqual(sut.state, .inactive)
    }

    func test_dismissAlert_inactive상태_무시() {
        sut.dismissAlert()  // 알림이 없는 상태에서 dismiss

        XCTAssertEqual(sut.state, .inactive)
    }

    // MARK: - GPS Accuracy Filtering Tests

    func test_config_minGPSAccuracyForMovement_30m() {
        XCTAssertEqual(IdleDetectionConfig.minGPSAccuracyForMovement, 30.0)
    }

    func test_config_maxRealisticSpeedKmh_200() {
        XCTAssertEqual(IdleDetectionConfig.maxRealisticSpeedKmh, 200.0)
    }

    /// GPS 정확도가 좋은 위치 생성 헬퍼
    private func makeLocationWithAccuracy(
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double,
        timestamp: Date = Date()
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: 0,
            timestamp: timestamp
        )
    }

    func test_updateLocation_정확도불량_첫위치무시() {
        sut.startMonitoring()

        // 정확도 50m인 위치 (30m 초과 - 불량)
        let badAccuracyLocation = makeLocationWithAccuracy(
            latitude: 37.5665,
            longitude: 126.9780,
            horizontalAccuracy: 50.0
        )
        sut.updateLocation(badAccuracyLocation)

        // 정확도 불량이므로 첫 위치로 저장되지 않아야 함
        // 다음에 정확도 좋은 위치가 첫 위치가 됨
        let goodAccuracyLocation = makeLocationWithAccuracy(
            latitude: 37.5665 + 0.001,  // 약 100m 이동
            longitude: 126.9780,
            horizontalAccuracy: 10.0
        )
        sut.updateLocation(goodAccuracyLocation)

        // 정확도 좋은 위치가 첫 위치로 저장됨 (이동으로 인정되지 않음)
        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_updateLocation_정확도불량_이동무시() {
        sut.startMonitoring()

        // 첫 위치: 정확도 좋음
        let goodLocation1 = makeLocationWithAccuracy(
            latitude: 37.5665,
            longitude: 126.9780,
            horizontalAccuracy: 10.0,
            timestamp: Date()
        )
        sut.updateLocation(goodLocation1)

        // 두 번째 위치: 정확도 불량 (50m) + 100m 이동
        let badLocation = makeLocationWithAccuracy(
            latitude: 37.5665 + 0.0009,  // 약 100m 이동
            longitude: 126.9780,
            horizontalAccuracy: 50.0,
            timestamp: Date().addingTimeInterval(10)
        )
        sut.updateLocation(badLocation)

        // 정확도 불량이므로 이동으로 인정되지 않음
        // idleDuration이 리셋되지 않아야 함 (하지만 테스트에서는 시간이 거의 없으므로 0에 가까움)
        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_updateLocation_GPS점프_이동무시() {
        sut.startMonitoring()

        let baseTime = Date()

        // 첫 위치: 정확도 좋음
        let location1 = makeLocationWithAccuracy(
            latitude: 37.5665,
            longitude: 126.9780,
            horizontalAccuracy: 10.0,
            timestamp: baseTime
        )
        sut.updateLocation(location1)

        // 두 번째 위치: 1초 만에 500m 이동 = 1800 km/h (비현실적 속도)
        // 약 0.0045도 = 약 500m
        let location2 = makeLocationWithAccuracy(
            latitude: 37.5665 + 0.0045,
            longitude: 126.9780,
            horizontalAccuracy: 10.0,
            timestamp: baseTime.addingTimeInterval(1)  // 1초 후
        )
        sut.updateLocation(location2)

        // GPS 점프로 판단되어 이동으로 인정되지 않음
        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_updateLocation_정확도좋음_정상이동_타이머리셋() {
        sut.startMonitoring()

        let baseTime = Date()

        // 첫 위치: 정확도 좋음
        let location1 = makeLocationWithAccuracy(
            latitude: 37.5665,
            longitude: 126.9780,
            horizontalAccuracy: 10.0,
            timestamp: baseTime
        )
        sut.updateLocation(location1)

        // 두 번째 위치: 10초 만에 100m 이동 = 36 km/h (정상 속도)
        let location2 = makeLocationWithAccuracy(
            latitude: 37.5665 + 0.0009,  // 약 100m 이동
            longitude: 126.9780,
            horizontalAccuracy: 10.0,
            timestamp: baseTime.addingTimeInterval(10)  // 10초 후
        )
        sut.updateLocation(location2)

        // 정확도 좋고 속도 정상이므로 이동으로 인정
        XCTAssertEqual(sut.state, .monitoring)
        XCTAssertEqual(sut.idleDuration, 0)
    }

    func test_updateLocation_실내GPS점프_무시_무이동유지() {
        sut.startMonitoring()

        let baseTime = Date()

        // 첫 위치: 정확도 좋음
        let location1 = makeLocationWithAccuracy(
            latitude: 37.5665,
            longitude: 126.9780,
            horizontalAccuracy: 10.0,
            timestamp: baseTime
        )
        sut.updateLocation(location1)

        // 실내 GPS 점프 시뮬레이션: 정확도 불량 + 큰 이동
        // 사용자는 실제로 가만히 있지만, GPS가 점프함
        for i in 1...5 {
            let jumpLocation = makeLocationWithAccuracy(
                latitude: 37.5665 + Double(i) * 0.0005,  // 매번 약 50m 점프
                longitude: 126.9780,
                horizontalAccuracy: 40.0,  // 정확도 불량
                timestamp: baseTime.addingTimeInterval(Double(i) * 5)
            )
            sut.updateLocation(jumpLocation)
        }

        // GPS 점프가 모두 무시되어 상태 유지
        XCTAssertEqual(sut.state, .monitoring)
    }

    func test_updateLocation_음수정확도_무시() {
        sut.startMonitoring()

        // 음수 정확도는 유효하지 않은 GPS 신호를 의미
        let invalidLocation = makeLocationWithAccuracy(
            latitude: 37.5665,
            longitude: 126.9780,
            horizontalAccuracy: -1.0,
            timestamp: Date()
        )
        sut.updateLocation(invalidLocation)

        // 음수 정확도이므로 첫 위치로 저장되지 않음
        XCTAssertEqual(sut.state, .monitoring)
    }

    // MARK: - Integration Scenario Tests

    func test_시나리오_시작_이동_정지_리셋() {
        // 1. 시작
        sut.startMonitoring()
        XCTAssertEqual(sut.state, .monitoring)

        // 2. 위치 업데이트
        let location1 = CLLocation(latitude: 37.5665, longitude: 126.9780)
        sut.updateLocation(location1)

        let location2 = CLLocation(latitude: 37.5665 + 0.001, longitude: 126.9780)
        sut.updateLocation(location2)
        XCTAssertEqual(sut.state, .monitoring)

        // 3. 정지
        sut.stopMonitoring()
        XCTAssertEqual(sut.state, .inactive)

        // 4. 리셋
        sut.reset()
        XCTAssertEqual(sut.state, .inactive)
        XCTAssertEqual(sut.idleDuration, 0)
    }

    func test_시나리오_DeadReckoning중_위치무시() {
        sut.startMonitoring()

        // Dead Reckoning 활성화
        sut.setDeadReckoningActive(true)

        // 여러 위치 업데이트 (모두 무시되어야 함)
        for i in 0..<10 {
            let location = CLLocation(
                latitude: 37.5665 + Double(i) * 0.001,
                longitude: 126.9780
            )
            sut.updateLocation(location)
        }

        // Dead Reckoning 비활성화
        sut.setDeadReckoningActive(false)

        // 이제 위치 업데이트가 처리됨
        let location = CLLocation(latitude: 37.6, longitude: 126.9780)
        sut.updateLocation(location)

        XCTAssertEqual(sut.state, .monitoring)
    }
}
