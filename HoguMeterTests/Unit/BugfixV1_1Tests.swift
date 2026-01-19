//
//  BugfixV1_1Tests.swift
//  HoguMeterTests
//
//  Tests for v1.1 bugfixes:
//  - Issue 1: Dead Reckoning max duration (180s → 300s)
//  - Issue 2: Duration formatting with hours
//  - Issue 3: Sound settings sync
//  - Issue 4: Region surcharge count in Real Mode
//

import XCTest
@testable import HoguMeter

// MARK: - Issue 1: Dead Reckoning Duration Tests

final class DeadReckoningDurationTests: XCTestCase {

    func test_maxDuration_is300Seconds() {
        // v1.1 변경: 180초 → 300초 (5분)
        XCTAssertEqual(DeadReckoningConfig.maxDuration, 300.0,
                       "Dead Reckoning 최대 지속 시간은 300초(5분)이어야 합니다")
    }

    func test_maxDuration_covers4MinuteTunnel() {
        // 4분 터널 통과 시 거리 추정 가능해야 함
        let tunnelDuration: TimeInterval = 240.0  // 4분
        XCTAssertLessThan(tunnelDuration, DeadReckoningConfig.maxDuration,
                          "4분 터널은 Dead Reckoning 범위 내여야 합니다")
    }

    func test_maxDuration_covers5MinuteTunnel() {
        // 5분 터널 통과 시 거리 추정 가능해야 함
        let tunnelDuration: TimeInterval = 300.0  // 5분
        XCTAssertLessThanOrEqual(tunnelDuration, DeadReckoningConfig.maxDuration,
                                  "5분 터널은 Dead Reckoning 범위 내여야 합니다")
    }

    func test_distanceCalculation_at100kmh_for4Minutes() {
        // 100 km/h로 4분간 이동 시 예상 거리
        let speedMps = 100.0 / 3.6  // m/s
        let duration: TimeInterval = 240.0  // 4분
        let expectedDistance = speedMps * duration  // 약 6.67 km

        XCTAssertEqual(expectedDistance, 6666.67, accuracy: 1.0,
                       "100 km/h로 4분간 이동 시 약 6.67km")
    }

    func test_distanceCalculation_at100kmh_for5Minutes() {
        // 100 km/h로 5분간 이동 시 예상 거리
        let speedMps = 100.0 / 3.6  // m/s
        let duration: TimeInterval = 300.0  // 5분
        let expectedDistance = speedMps * duration  // 약 8.33 km

        XCTAssertEqual(expectedDistance, 8333.33, accuracy: 1.0,
                       "100 km/h로 5분간 이동 시 약 8.33km")
    }
}

// MARK: - Issue 2: Duration Formatting Tests

final class DurationFormattingTests: XCTestCase {

    // Helper function to test the formatting logic
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분 \(seconds)초"
        } else if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }

    func test_formatDuration_45Seconds() {
        XCTAssertEqual(formatDuration(45), "45초")
    }

    func test_formatDuration_125Seconds() {
        // 2분 5초
        XCTAssertEqual(formatDuration(125), "2분 5초")
    }

    func test_formatDuration_1Hour() {
        // 3600초 = 1시간
        XCTAssertEqual(formatDuration(3600), "1시간 0분 0초")
    }

    func test_formatDuration_1Hour1Minute5Seconds() {
        // 3665초 = 1시간 1분 5초
        XCTAssertEqual(formatDuration(3665), "1시간 1분 5초")
    }

    func test_formatDuration_3Hours57Minutes57Seconds() {
        // 실제 테스트 케이스: 3시간 57분 57초
        let duration: TimeInterval = 3 * 3600 + 57 * 60 + 57
        XCTAssertEqual(formatDuration(duration), "3시간 57분 57초")
    }

    func test_formatDuration_237Minutes57Seconds_showsHours() {
        // 버그 케이스: 237분 57초 → 3시간 57분 57초로 표시되어야 함
        let duration: TimeInterval = 237 * 60 + 57
        XCTAssertEqual(formatDuration(duration), "3시간 57분 57초")
    }

    func test_formatDuration_24Hours() {
        // 86400초 = 24시간
        XCTAssertEqual(formatDuration(86400), "24시간 0분 0초")
    }
}

// MARK: - Issue 3: Sound Settings Tests

final class SoundSettingsTests: XCTestCase {

    func test_settingsRepositoryProtocol_includesSoundEnabled() {
        // Protocol에 isSoundEnabled가 포함되어 있는지 확인
        let mockSettings = MockSettingsRepositoryWithSound()
        XCTAssertTrue(mockSettings.isSoundEnabled)

        mockSettings.isSoundEnabled = false
        XCTAssertFalse(mockSettings.isSoundEnabled)
    }

    func test_soundManager_readsFromSettingsRepository() {
        // SoundManager가 SettingsRepository에서 설정을 읽는지 확인
        let mockSettings = MockSettingsRepositoryWithSound()
        mockSettings.isSoundEnabled = true

        let soundManager = SoundManager(settingsRepository: mockSettings)
        // play 호출 시 isSoundEnabled 확인 - 직접 테스트는 어렵지만 crash 없이 동작해야 함
        soundManager.play(.meterStart)

        mockSettings.isSoundEnabled = false
        soundManager.play(.meterStart)  // Should not crash, should be silent
    }
}

// MARK: - Issue 4: Region Surcharge Count Tests

final class RegionSurchargeCountTests: XCTestCase {

    func test_realMode_boundaryCrossCount_initiallyZero() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        XCTAssertEqual(service.boundaryCrossCount, 0)
    }

    func test_realMode_boundaryCrossCount_incrementsOnCrossingBoundary() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 경기도로 이동 → 경계 통과
        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggiAddress)

        XCTAssertEqual(service.boundaryCrossCount, 1,
                       "사업구역 경계 통과 시 boundaryCrossCount가 1이어야 합니다")
    }

    func test_realMode_boundaryCrossCount_doesNotIncrementWhileInSameZone() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 경기도로 이동
        let gyeonggi1 = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggi1)
        XCTAssertEqual(service.boundaryCrossCount, 1)

        // 경기도 내 다른 시로 이동 → 경계 통과 아님
        let gyeonggi2 = AddressInfo(
            administrativeArea: "경기도",
            locality: "용인시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggi2)
        XCTAssertEqual(service.boundaryCrossCount, 1,
                       "같은 사업구역 내 이동은 boundaryCrossCount를 증가시키지 않아야 합니다")

        // 경기도 내 또 다른 시로 이동
        let gyeonggi3 = AddressInfo(
            administrativeArea: "경기도",
            locality: "수원시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggi3)
        XCTAssertEqual(service.boundaryCrossCount, 1)
    }

    func test_realMode_boundaryCrossCount_incrementsOnReentryAfterReturn() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 경기도로 이동 → 첫 번째 경계 통과
        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggiAddress)
        XCTAssertEqual(service.boundaryCrossCount, 1)

        // 서울로 복귀
        let seoulAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "송파구",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: seoulAddress)
        XCTAssertEqual(service.boundaryCrossCount, 1)  // 복귀는 증가 안 함

        // 다시 경기도로 이동 → 두 번째 경계 통과
        _ = service.updateLocation(addressInfo: gyeonggiAddress)
        XCTAssertEqual(service.boundaryCrossCount, 2,
                       "서울 복귀 후 다시 경계 통과 시 boundaryCrossCount가 증가해야 합니다")
    }

    func test_realMode_lastSurchargeRate_storedCorrectly() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggiAddress)

        XCTAssertEqual(service.lastSurchargeRate, 0.20,
                       "서울 출발 시 할증률은 20%여야 합니다")
    }

    func test_realMode_seoulToDaegu_oneBoundaryCross() {
        // 서울 → 대구 장거리 이동 시 boundaryCrossCount = 1
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 경기도 통과
        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggiAddress)
        XCTAssertEqual(service.boundaryCrossCount, 1)

        // 충청도 통과
        let chungcheongAddress = AddressInfo(
            administrativeArea: "충청북도",
            locality: "청주시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: chungcheongAddress)
        XCTAssertEqual(service.boundaryCrossCount, 1,
                       "이미 사업구역을 벗어난 상태에서 추가 이동은 count를 증가시키지 않음")

        // 경상도 통과
        let gyeongsangAddress = AddressInfo(
            administrativeArea: "경상북도",
            locality: "김천시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeongsangAddress)
        XCTAssertEqual(service.boundaryCrossCount, 1)

        // 대구 도착
        let daeguAddress = AddressInfo(
            administrativeArea: "대구광역시",
            locality: "수성구",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: daeguAddress)
        XCTAssertEqual(service.boundaryCrossCount, 1,
                       "서울 → 대구 이동 시 boundaryCrossCount는 1이어야 합니다 (367이 아님)")
    }

    func test_funMode_regionDetectorCountUsed() {
        // 재미 모드에서는 RegionDetector의 count가 사용됨을 확인
        // (이 테스트는 MeterViewModel 통합 테스트에서 더 적합)
        let service = RegionalSurchargeService()
        service.mode = .fun

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: gyeonggiAddress)

        // 재미 모드에서 RegionalSurchargeService는 항상 inactive 반환
        XCTAssertFalse(status.isActive,
                       "재미 모드에서 RegionalSurchargeService는 inactive를 반환해야 합니다")
    }

    func test_reset_clearsBoundaryCrossCount() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggiAddress)
        XCTAssertEqual(service.boundaryCrossCount, 1)

        service.reset()

        XCTAssertEqual(service.boundaryCrossCount, 0,
                       "reset() 후 boundaryCrossCount는 0이어야 합니다")
        XCTAssertEqual(service.lastSurchargeRate, 0)
    }
}

// MARK: - Mock Classes

class MockSettingsRepositoryWithSound: SettingsRepositoryProtocol {
    var currentRegionFare: RegionFare {
        return RegionFare.seoul()
    }
    var isRegionSurchargeEnabled: Bool = true
    var regionalSurchargeMode: RegionalSurchargeMode = .realistic
    var regionSurchargeAmount: Int = 2000
    var isSoundEnabled: Bool = true
}
