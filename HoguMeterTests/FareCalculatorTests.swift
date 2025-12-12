//
//  FareCalculatorTests.swift
//  HoguMeterTests
//
//  서울시 택시요금 정책 기반 요금 계산 테스트
//  기준: 2024년 서울시 택시요금
//
//  주간 (04:00 ~ 22:00):
//    - 기본요금: 4,800원 (1,600m까지)
//    - 거리요금: 131m당 100원
//    - 시간요금: 30초당 100원
//
//  심야1 (22:00 ~ 23:00, 02:00 ~ 04:00) - 20% 할증:
//    - 기본요금: 5,800원 (1,600m까지)
//    - 거리요금: 131m당 120원
//    - 시간요금: 30초당 120원
//
//  심야2 (23:00 ~ 02:00) - 40% 할증:
//    - 기본요금: 6,700원 (1,600m까지)
//    - 거리요금: 131m당 140원
//    - 시간요금: 30초당 140원
//

import XCTest
@testable import HoguMeter

final class FareCalculatorTests: XCTestCase {

    var calculator: FareCalculator!
    var mockSettings: MockSettingsRepository!

    override func setUp() {
        super.setUp()
        mockSettings = MockSettingsRepository()
        calculator = FareCalculator(settingsRepository: mockSettings)
    }

    override func tearDown() {
        calculator = nil
        mockSettings = nil
        super.tearDown()
    }

    // MARK: - 주간 요금 테스트 (04:00 ~ 22:00)

    func test_주간_기본거리이하_기본요금만() {
        // Given: 주간 시간대, 1.6km 이하, 저속 시간 없음
        let date = createDate(hour: 12, minute: 0)  // 정오
        let distance: Double = 1600  // 1.6km (기본거리)
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then: 기본요금 4,800원
        XCTAssertEqual(fare, 4800, "주간 기본거리 이하는 기본요금 4,800원이어야 합니다")
    }

    func test_주간_거리요금_계산() {
        // Given: 주간 시간대, 3km 주행
        let date = createDate(hour: 14, minute: 0)
        let distance: Double = 3000  // 3km
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 기본요금: 4,800원
        // 추가거리: 3,000 - 1,600 = 1,400m
        // 거리요금: floor(1,400 / 131) * 100 = 10 * 100 = 1,000원
        // 총합: 4,800 + 1,000 = 5,800원
        XCTAssertEqual(fare, 5800, "주간 3km 주행 시 5,800원이어야 합니다")
    }

    func test_주간_시간요금_계산() {
        // Given: 주간 시간대, 저속 2분 (고속 이동 없음)
        // 병산제: 저속 시간만 유닛으로 계산
        let date = createDate(hour: 10, minute: 0)
        let distance: Double = 0  // 고속 이동 없음
        let lowSpeedDuration: TimeInterval = 120  // 2분 = 120초

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 병산제 계산:
        // - 시간 유닛: 120 / 30 = 4 유닛
        // - 기본 유닛: 1600 / 131 ≈ 12.2 유닛
        // - 추가 유닛: max(0, 4 - 12.2) = 0
        // - 기본요금만: 4,800원
        XCTAssertEqual(fare, 4800, "병산제: 2분 저속은 기본 유닛 이내이므로 기본요금만 부과")
    }

    func test_주간_거리_시간_복합요금() {
        // Given: 주간 시간대, 5km 고속 주행, 저속 3분
        // 병산제: 고속 거리와 저속 시간을 유닛으로 환산
        let date = createDate(hour: 15, minute: 30)
        let distance: Double = 5000  // 5km 고속 주행
        let lowSpeedDuration: TimeInterval = 180  // 3분 = 180초 저속

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 병산제 계산:
        // - 거리 유닛: 5000 / 131 = 38.17 유닛
        // - 시간 유닛: 180 / 30 = 6 유닛
        // - 총 유닛: 44.17 유닛
        // - 기본 유닛: 1600 / 131 = 12.21 유닛
        // - 추가 유닛: 44.17 - 12.21 = 31.96 → 31 유닛
        // - 추가 요금: 31 * 100 = 3,100원
        // - 총합: 4,800 + 3,100 = 7,900원
        XCTAssertEqual(fare, 7900, "병산제: 5km+3분 저속 시 7,900원이어야 합니다")
    }

    func test_주간_10km_주행() {
        // Given: 주간 시간대, 10km 주행, 저속 없음
        let date = createDate(hour: 11, minute: 0)
        let distance: Double = 10000  // 10km
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 기본요금: 4,800원
        // 추가거리: 10,000 - 1,600 = 8,400m
        // 거리요금: floor(8,400 / 131) * 100 = 64 * 100 = 6,400원
        // 총합: 4,800 + 6,400 = 11,200원
        XCTAssertEqual(fare, 11200, "주간 10km 주행 시 11,200원이어야 합니다")
    }

    // MARK: - 심야1 요금 테스트 (22:00 ~ 23:00, 02:00 ~ 04:00) - 20% 할증

    func test_심야1_22시_기본요금() {
        // Given: 심야1 시간대 (22:00~23:00)
        let date = createDate(hour: 22, minute: 30)
        let distance: Double = 1600  // 기본거리
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then: 심야1 기본요금 5,800원
        XCTAssertEqual(fare, 5800, "심야1(22시) 기본요금은 5,800원이어야 합니다")
    }

    func test_심야1_03시_기본요금() {
        // Given: 심야1 시간대 (02:00~04:00)
        let date = createDate(hour: 3, minute: 0)
        let distance: Double = 1600
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then: 심야1 기본요금 5,800원
        XCTAssertEqual(fare, 5800, "심야1(03시) 기본요금은 5,800원이어야 합니다")
    }

    func test_심야1_거리요금() {
        // Given: 심야1 시간대, 5km 주행
        let date = createDate(hour: 22, minute: 0)
        let distance: Double = 5000  // 5km
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 기본요금: 5,800원
        // 추가거리: 5,000 - 1,600 = 3,400m
        // 거리요금: floor(3,400 / 131) * 120 = 25 * 120 = 3,000원
        // 총합: 5,800 + 3,000 = 8,800원
        XCTAssertEqual(fare, 8800, "심야1 5km 주행 시 8,800원이어야 합니다")
    }

    func test_심야1_시간요금() {
        // Given: 심야1 시간대, 저속 2분 (고속 이동 없음)
        // 병산제: 저속 시간만 유닛으로 계산
        let date = createDate(hour: 2, minute: 30)
        let distance: Double = 0  // 고속 이동 없음
        let lowSpeedDuration: TimeInterval = 120  // 2분

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 병산제 계산:
        // - 시간 유닛: 120 / 30 = 4 유닛
        // - 기본 유닛: 1600 / 131 = 12.21 유닛
        // - 추가 유닛: max(0, 4 - 12.21) = 0
        // - 기본요금만: 5,800원
        XCTAssertEqual(fare, 5800, "병산제: 2분 저속은 기본 유닛 이내이므로 기본요금만 부과")
    }

    // MARK: - 심야2 요금 테스트 (23:00 ~ 02:00) - 40% 할증

    func test_심야2_23시_기본요금() {
        // Given: 심야2 시간대 (23:00)
        let date = createDate(hour: 23, minute: 0)
        let distance: Double = 1600
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then: 심야2 기본요금 6,700원
        XCTAssertEqual(fare, 6700, "심야2(23시) 기본요금은 6,700원이어야 합니다")
    }

    func test_심야2_00시_기본요금() {
        // Given: 심야2 시간대 (00:00)
        let date = createDate(hour: 0, minute: 30)
        let distance: Double = 1600
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then: 심야2 기본요금 6,700원
        XCTAssertEqual(fare, 6700, "심야2(00시) 기본요금은 6,700원이어야 합니다")
    }

    func test_심야2_01시_기본요금() {
        // Given: 심야2 시간대 (01:00)
        let date = createDate(hour: 1, minute: 0)
        let distance: Double = 1600
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then: 심야2 기본요금 6,700원
        XCTAssertEqual(fare, 6700, "심야2(01시) 기본요금은 6,700원이어야 합니다")
    }

    func test_심야2_거리요금() {
        // Given: 심야2 시간대, 5km 주행
        let date = createDate(hour: 0, minute: 0)
        let distance: Double = 5000
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 기본요금: 6,700원
        // 추가거리: 5,000 - 1,600 = 3,400m
        // 거리요금: floor(3,400 / 131) * 140 = 25 * 140 = 3,500원
        // 총합: 6,700 + 3,500 = 10,200원
        XCTAssertEqual(fare, 10200, "심야2 5km 주행 시 10,200원이어야 합니다")
    }

    func test_심야2_시간요금() {
        // Given: 심야2 시간대, 저속 2분 (고속 이동 없음)
        // 병산제: 저속 시간만 유닛으로 계산
        let date = createDate(hour: 1, minute: 30)
        let distance: Double = 0  // 고속 이동 없음
        let lowSpeedDuration: TimeInterval = 120

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 병산제 계산:
        // - 시간 유닛: 120 / 30 = 4 유닛
        // - 기본 유닛: 1600 / 131 = 12.21 유닛
        // - 추가 유닛: max(0, 4 - 12.21) = 0
        // - 기본요금만: 6,700원
        XCTAssertEqual(fare, 6700, "병산제: 2분 저속은 기본 유닛 이내이므로 기본요금만 부과")
    }

    func test_심야2_10km_5분저속_복합요금() {
        // Given: 심야2 시간대, 10km, 저속 5분
        let date = createDate(hour: 23, minute: 30)
        let distance: Double = 10000  // 10km
        let lowSpeedDuration: TimeInterval = 300  // 5분

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 기본요금: 6,700원
        // 추가거리: 10,000 - 1,600 = 8,400m
        // 거리요금: floor(8,400 / 131) * 140 = 64 * 140 = 8,960원
        // 시간요금: floor(300 / 30) * 140 = 10 * 140 = 1,400원
        // 총합: 6,700 + 8,960 + 1,400 = 17,060원
        XCTAssertEqual(fare, 17060, "심야2 10km+5분 저속 시 17,060원이어야 합니다")
    }

    // MARK: - 시간대 경계값 테스트

    func test_시간대_04시_주간시작() {
        let date = createDate(hour: 4, minute: 0)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 4800, "04:00은 주간 요금이어야 합니다")
    }

    func test_시간대_21시59분_주간() {
        let date = createDate(hour: 21, minute: 59)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 4800, "21:59은 주간 요금이어야 합니다")
    }

    func test_시간대_22시_심야1시작() {
        let date = createDate(hour: 22, minute: 0)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 5800, "22:00은 심야1 요금이어야 합니다")
    }

    func test_시간대_22시59분_심야1() {
        let date = createDate(hour: 22, minute: 59)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 5800, "22:59은 심야1 요금이어야 합니다")
    }

    func test_시간대_23시_심야2시작() {
        let date = createDate(hour: 23, minute: 0)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 6700, "23:00은 심야2 요금이어야 합니다")
    }

    func test_시간대_01시59분_심야2() {
        let date = createDate(hour: 1, minute: 59)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 6700, "01:59은 심야2 요금이어야 합니다")
    }

    func test_시간대_02시_심야1() {
        let date = createDate(hour: 2, minute: 0)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 5800, "02:00은 심야1 요금이어야 합니다")
    }

    func test_시간대_03시59분_심야1() {
        let date = createDate(hour: 3, minute: 59)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 5800, "03:59은 심야1 요금이어야 합니다")
    }

    // MARK: - 지역 할증 테스트

    func test_지역할증_1회() {
        // Given: 지역 변경 1회
        mockSettings.isRegionSurchargeEnabled = true
        let date = createDate(hour: 12, minute: 0)
        let distance: Double = 5000  // 5km
        let lowSpeedDuration: TimeInterval = 0

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 1,
            at: date
        )

        // Then:
        // 기본요금: 4,800원
        // 거리요금: floor(3,400 / 131) * 100 = 2,500원
        // 지역할증: (2,500) * 0.2 * 1 = 500원
        // 총합: 4,800 + 2,500 + 500 = 7,800원
        XCTAssertEqual(fare, 7800, "지역할증 1회 적용 시 7,800원이어야 합니다")
    }

    func test_지역할증_비활성화() {
        // Given: 지역할증 비활성화
        mockSettings.isRegionSurchargeEnabled = false
        let date = createDate(hour: 12, minute: 0)
        let distance: Double = 5000

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: 0,
            regionChanges: 1,
            at: date
        )

        // Then: 지역할증 없이 계산
        // 기본요금: 4,800원
        // 거리요금: 2,500원
        // 총합: 7,300원
        XCTAssertEqual(fare, 7300, "지역할증 비활성화 시 7,300원이어야 합니다")
    }

    // MARK: - FareBreakdown 테스트

    func test_breakdown_주간_상세내역() {
        // Given: 5km 고속 주행, 2분 저속
        let date = createDate(hour: 14, minute: 0)
        let distance: Double = 5000
        let lowSpeedDuration: TimeInterval = 120

        // When
        let breakdown = calculator.breakdown(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 병산제 계산:
        // - 거리 유닛: 5000 / 131 = 38.17 유닛
        // - 시간 유닛: 120 / 30 = 4 유닛
        // - 총 유닛: 42.17 유닛
        // - 기본 유닛: 12.21 유닛
        // - 추가 유닛: 29 유닛
        // - 추가 요금: 2,900원 (비율 분배)
        XCTAssertEqual(breakdown.baseFare, 4800, "기본요금은 4,800원")
        // 병산제에서는 거리/시간 비율에 따라 분배 (38.17 : 4 ≈ 90.5% : 9.5%)
        XCTAssertEqual(breakdown.distanceFare + breakdown.timeFare, 2900, "추가요금 합계는 2,900원")
        XCTAssertEqual(breakdown.regionSurcharge, 0, "지역할증은 0원")
        XCTAssertEqual(breakdown.nightSurcharge, 0, "야간할증은 0원")
    }

    func test_breakdown_심야2_상세내역() {
        // Given: 5km 고속 주행, 2분 저속 (심야2)
        let date = createDate(hour: 0, minute: 30)
        let distance: Double = 5000
        let lowSpeedDuration: TimeInterval = 120

        // When
        let breakdown = calculator.breakdown(
            distance: distance,
            lowSpeedDuration: lowSpeedDuration,
            regionChanges: 0,
            at: date
        )

        // Then:
        // 병산제 계산 (심야2: 140원/유닛):
        // - 거리 유닛: 5000 / 131 = 38.17 유닛
        // - 시간 유닛: 120 / 30 = 4 유닛
        // - 총 유닛: 42.17 유닛
        // - 기본 유닛: 12.21 유닛
        // - 추가 유닛: 29 유닛
        // - 추가 요금: 29 * 140 = 4,060원
        XCTAssertEqual(breakdown.baseFare, 6700, "심야2 기본요금은 6,700원")
        XCTAssertEqual(breakdown.distanceFare + breakdown.timeFare, 4060, "심야2 추가요금 합계는 4,060원")
    }

    // MARK: - 반올림 테스트

    func test_반올림_십원단위() {
        // Given: 계산 결과가 십원단위로 반올림되는지 확인
        let date = createDate(hour: 12, minute: 0)
        // 131m 단위로 나누어 떨어지지 않는 경우
        let distance: Double = 1731  // 1,600 + 131 = 정확히 1단위 추가

        // When
        let fare = calculator.calculate(
            distance: distance,
            lowSpeedDuration: 0,
            regionChanges: 0,
            at: date
        )

        // Then: 4,800 + 100 = 4,900원
        XCTAssertEqual(fare, 4900, "반올림 후 4,900원이어야 합니다")
    }

    // MARK: - 엣지 케이스 테스트

    func test_거리_0() {
        let date = createDate(hour: 12, minute: 0)
        let fare = calculator.calculate(distance: 0, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 4800, "거리 0이어도 기본요금은 부과됩니다")
    }

    func test_저속시간_29초() {
        // Given: 29초 저속 (30초 미만이므로 시간요금 0)
        let date = createDate(hour: 12, minute: 0)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 29, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 4800, "29초 저속은 시간요금이 추가되지 않습니다")
    }

    func test_저속시간_30초() {
        // Given: 정확히 30초 저속
        let date = createDate(hour: 12, minute: 0)
        let fare = calculator.calculate(distance: 1600, lowSpeedDuration: 30, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 4900, "30초 저속은 100원이 추가됩니다")
    }

    func test_거리_130m추가() {
        // Given: 130m 추가 (131m 미만이므로 거리요금 0)
        let date = createDate(hour: 12, minute: 0)
        let fare = calculator.calculate(distance: 1730, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 4800, "130m 추가는 거리요금이 추가되지 않습니다")
    }

    func test_거리_131m추가() {
        // Given: 정확히 131m 추가
        let date = createDate(hour: 12, minute: 0)
        let fare = calculator.calculate(distance: 1731, lowSpeedDuration: 0, regionChanges: 0, at: date)
        XCTAssertEqual(fare, 4900, "131m 추가는 100원이 추가됩니다")
    }

    // MARK: - Helper Methods

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

// MARK: - Mock Settings Repository

final class MockSettingsRepository: SettingsRepositoryProtocol {

    var currentRegionFare: RegionFare = .seoul()
    var isRegionSurchargeEnabled: Bool = true
}
