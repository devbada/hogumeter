//
//  RegionalSurchargeServiceTests.swift
//  HoguMeterTests
//
//  Created on 2025-01-14.
//

import XCTest
@testable import HoguMeter

final class RegionalSurchargeServiceTests: XCTestCase {

    // MARK: - RegionalSurchargeMode Tests

    func test_모드_displayName_리얼모드() {
        let mode = RegionalSurchargeMode.realistic
        XCTAssertEqual(mode.displayName, "리얼 모드 🚕")
    }

    func test_모드_displayName_재미모드() {
        let mode = RegionalSurchargeMode.fun
        XCTAssertEqual(mode.displayName, "재미 모드 🎮")
    }

    func test_모드_displayName_끄기() {
        let mode = RegionalSurchargeMode.off
        XCTAssertEqual(mode.displayName, "끄기")
    }

    func test_모드_allCases_3개() {
        XCTAssertEqual(RegionalSurchargeMode.allCases.count, 3)
    }

    func test_모드_description_리얼모드() {
        let mode = RegionalSurchargeMode.realistic
        XCTAssertEqual(mode.description, "실제 택시처럼 사업구역(시/도) 경계를 벗어날 때만 할증 적용")
    }

    func test_모드_description_재미모드() {
        let mode = RegionalSurchargeMode.fun
        XCTAssertEqual(mode.description, "동네가 바뀔 때마다 할증 (가볍게 즐기는 용도)")
    }

    func test_모드_description_끄기() {
        let mode = RegionalSurchargeMode.off
        XCTAssertEqual(mode.description, "지역 할증 미적용")
    }

    func test_모드_rawValue_인코딩() {
        XCTAssertEqual(RegionalSurchargeMode.realistic.rawValue, "realistic")
        XCTAssertEqual(RegionalSurchargeMode.fun.rawValue, "fun")
        XCTAssertEqual(RegionalSurchargeMode.off.rawValue, "off")
    }

    // MARK: - 도시별 할증률 Tests

    func test_서울_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "서울특별시")
        XCTAssertEqual(rate, 0.20)
    }

    func test_부산_할증률_30퍼센트() {
        let rate = CitySurchargeRate.rate(for: "부산광역시")
        XCTAssertEqual(rate, 0.30)
    }

    func test_인천_할증률_30퍼센트() {
        let rate = CitySurchargeRate.rate(for: "인천광역시")
        XCTAssertEqual(rate, 0.30)
    }

    func test_대전_할증률_30퍼센트() {
        let rate = CitySurchargeRate.rate(for: "대전광역시")
        XCTAssertEqual(rate, 0.30)
    }

    func test_대구_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "대구광역시")
        XCTAssertEqual(rate, 0.20)
    }

    func test_광주_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "광주광역시")
        XCTAssertEqual(rate, 0.20)
    }

    func test_울산_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "울산광역시")
        XCTAssertEqual(rate, 0.20)
    }

    func test_세종_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "세종특별자치시")
        XCTAssertEqual(rate, 0.20)
    }

    func test_경기도_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "경기도")
        XCTAssertEqual(rate, 0.20)
    }

    func test_기타지역_기본_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "충청남도")
        XCTAssertEqual(rate, 0.20)
    }

    func test_전라북도_기본_할증률_20퍼센트() {
        let rate = CitySurchargeRate.rate(for: "전라북도")
        XCTAssertEqual(rate, 0.20)
    }

    // MARK: - 리얼 모드 기본 테스트

    func test_리얼모드_서울에서_서울_이동_할증미적용() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: "역삼동"
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "송파구",
            subLocality: "잠실동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)
        XCTAssertEqual(status.rate, 0)
    }

    func test_리얼모드_서울에서_경기도_이동_할증적용_20퍼센트() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: "역삼동"
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: "분당동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.20)  // 출발지(서울) 기준 20%
    }

    func test_리얼모드_서울에서_인천_이동_할증적용_20퍼센트() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강서구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "인천광역시",
            locality: "계양구",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.20)  // 출발지(서울) 기준 20%
    }

    func test_리얼모드_부산에서_경남_이동_할증적용_30퍼센트() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "부산광역시",
            locality: "해운대구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경상남도",
            locality: "김해시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.30)  // 출발지(부산) 기준 30%
    }

    func test_리얼모드_인천에서_경기도_이동_할증적용_30퍼센트() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "인천광역시",
            locality: "남동구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "시흥시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.30)  // 출발지(인천) 기준 30%
    }

    func test_리얼모드_대전에서_충남_이동_할증적용_30퍼센트() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "대전광역시",
            locality: "유성구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "충청남도",
            locality: "계룡시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.30)
    }

    func test_리얼모드_경기도에서_서울_이동_할증적용_20퍼센트() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: "분당동"
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: "역삼동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.20)  // 출발지(경기도) 기준 20%
    }

    func test_리얼모드_대구에서_경북_이동_할증적용_20퍼센트() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "대구광역시",
            locality: "수성구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경상북도",
            locality: "경산시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.20)
    }

    // MARK: - 리얼 모드 서울 특수 구역 테스트

    func test_리얼모드_서울에서_광명시_이동_할증미적용_통합사업구역() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "금천구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "광명시",
            subLocality: "철산동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)  // 광명시는 서울 통합사업구역
    }

    func test_리얼모드_서울에서_위례동_성남_이동_할증미적용_공동사업구역() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "송파구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: "위례동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)  // 위례신도시는 서울 공동사업구역
    }

    func test_리얼모드_서울에서_하남위례_이동_할증미적용() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "송파구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "하남시",
            subLocality: "위례동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)  // 하남시 위례동도 공동사업구역
    }

    func test_리얼모드_부산에서_광명시_이동_할증적용_부산출발은예외아님() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "부산광역시",
            locality: "해운대구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "광명시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        // 부산 출발은 광명시 예외 적용 안됨
        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.30)
    }

    // MARK: - 리얼 모드 구역 전환 테스트

    func test_리얼모드_서울_출발_경기_진입_서울_복귀_할증해제() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "도봉구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 경기도 진입 - 할증 시작
        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "의정부시",
            subLocality: nil
        )
        var status = service.updateLocation(addressInfo: gyeonggiAddress)
        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.20)

        // 서울 복귀 - 할증 해제
        let seoulAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "노원구",
            subLocality: nil
        )
        status = service.updateLocation(addressInfo: seoulAddress)
        XCTAssertFalse(status.isActive)
    }

    func test_리얼모드_같은_도내_시_이동_할증미적용() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "수원시",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "용인시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)  // 같은 경기도 내 이동
    }

    func test_리얼모드_할증상태_유지_같은구역내이동() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 경기도 진입
        let gyeonggi1 = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        var status = service.updateLocation(addressInfo: gyeonggi1)
        XCTAssertTrue(status.isActive)

        // 경기도 내 다른 시로 이동 (할증 유지)
        let gyeonggi2 = AddressInfo(
            administrativeArea: "경기도",
            locality: "용인시",
            subLocality: nil
        )
        status = service.updateLocation(addressInfo: gyeonggi2)
        XCTAssertTrue(status.isActive)  // 여전히 할증 적용
    }

    // MARK: - 재미 모드 테스트

    func test_재미모드_항상_비활성_반환() {
        let service = RegionalSurchargeService()
        service.mode = .fun

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: "역삼동"
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: "분당동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        // 재미 모드는 FareCalculator에서 regionChanges로 처리하므로 서비스는 항상 inactive
        XCTAssertFalse(status.isActive)
    }

    func test_재미모드_서울내_동변경_비활성() {
        let service = RegionalSurchargeService()
        service.mode = .fun

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: "역삼동"
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: "삼성동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)
    }

    // MARK: - 끄기 모드 테스트

    func test_끄기모드_시도_경계_벗어나도_할증미적용() {
        let service = RegionalSurchargeService()
        service.mode = .off

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: "분당동"
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)
        XCTAssertEqual(status.rate, 0)
    }

    func test_끄기모드_부산에서_경남도_할증미적용() {
        let service = RegionalSurchargeService()
        service.mode = .off

        let departureAddress = AddressInfo(
            administrativeArea: "부산광역시",
            locality: "해운대구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "경상남도",
            locality: "김해시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)
    }

    // MARK: - SurchargeStatus Tests

    func test_SurchargeStatus_ratePercentage_20퍼센트() {
        let status = SurchargeStatus(isActive: true, rate: 0.20)
        XCTAssertEqual(status.ratePercentage, 20)
    }

    func test_SurchargeStatus_ratePercentage_30퍼센트() {
        let status = SurchargeStatus(isActive: true, rate: 0.30)
        XCTAssertEqual(status.ratePercentage, 30)
    }

    func test_SurchargeStatus_비활성_rate_0() {
        let status = SurchargeStatus(isActive: false, rate: 0)
        XCTAssertEqual(status.ratePercentage, 0)
    }

    func test_SurchargeStatus_inactive_상수() {
        let status = SurchargeStatus.inactive
        XCTAssertFalse(status.isActive)
        XCTAssertEqual(status.rate, 0)
        XCTAssertEqual(status.ratePercentage, 0)
    }

    func test_SurchargeStatus_Equatable() {
        let status1 = SurchargeStatus(isActive: true, rate: 0.20)
        let status2 = SurchargeStatus(isActive: true, rate: 0.20)
        let status3 = SurchargeStatus(isActive: true, rate: 0.30)

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
    }

    // MARK: - 엣지 케이스 테스트

    func test_출발지_nil_할증미적용() {
        let service = RegionalSurchargeService()
        service.mode = .realistic
        // startTracking 호출 안 함

        let currentAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)
    }

    func test_현재위치_빈문자열_처리() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "",
            locality: nil,
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        // 빈 문자열은 같은 구역으로 처리
        XCTAssertFalse(status.isActive)
    }

    func test_현재위치_nil_처리() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: nil,
            locality: nil,
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)
    }

    func test_stopTracking_후_updateLocation_할증미적용() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)
        service.stopTracking()

        let currentAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)
    }

    func test_reset_후_상태초기화() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 경기도로 이동하여 할증 상태 만들기
        let gyeonggiAddress = AddressInfo(
            administrativeArea: "경기도",
            locality: "성남시",
            subLocality: nil
        )
        _ = service.updateLocation(addressInfo: gyeonggiAddress)

        // reset 호출
        service.reset()

        // 상태 확인
        XCTAssertNil(service.departureBusinessZone)
        XCTAssertFalse(service.isSurchargeActive)
    }

    func test_세종시_사업구역_처리() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "세종특별자치시",
            locality: nil,
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        let currentAddress = AddressInfo(
            administrativeArea: "충청남도",
            locality: "공주시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.rate, 0.20)
    }

    func test_제주도_사업구역_처리() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "제주특별자치도",
            locality: "제주시",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        // 제주도 내 다른 시로 이동
        let currentAddress = AddressInfo(
            administrativeArea: "제주특별자치도",
            locality: "서귀포시",
            subLocality: nil
        )
        let status = service.updateLocation(addressInfo: currentAddress)

        XCTAssertFalse(status.isActive)  // 같은 제주도 내
    }

    // MARK: - 서비스 속성 테스트

    func test_서비스_초기_모드는_리얼모드() {
        let service = RegionalSurchargeService()
        XCTAssertEqual(service.mode, .realistic)
    }

    func test_서비스_모드변경() {
        let service = RegionalSurchargeService()

        service.mode = .fun
        XCTAssertEqual(service.mode, .fun)

        service.mode = .off
        XCTAssertEqual(service.mode, .off)

        service.mode = .realistic
        XCTAssertEqual(service.mode, .realistic)
    }

    func test_startTracking_출발지_기록() {
        let service = RegionalSurchargeService()
        service.mode = .realistic

        let departureAddress = AddressInfo(
            administrativeArea: "부산광역시",
            locality: "해운대구",
            subLocality: nil
        )
        service.startTracking(addressInfo: departureAddress)

        XCTAssertEqual(service.departureBusinessZone, "부산광역시")
    }

    func test_할증구간_거리_누적() {
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

        // 첫 진입 (거리 0)
        _ = service.updateLocation(addressInfo: gyeonggiAddress, distanceDelta: 0)
        XCTAssertEqual(service.surchargeDistance, 0)

        // 추가 이동 (100m)
        _ = service.updateLocation(addressInfo: gyeonggiAddress, distanceDelta: 100)
        XCTAssertEqual(service.surchargeDistance, 100)

        // 추가 이동 (200m)
        _ = service.updateLocation(addressInfo: gyeonggiAddress, distanceDelta: 200)
        XCTAssertEqual(service.surchargeDistance, 300)  // 누적
    }

    // MARK: - CitySurchargeRate 추가 테스트

    func test_CitySurchargeRate_displayRate() {
        let rate = CitySurchargeRate(city: "서울특별시", rate: 0.20)
        XCTAssertEqual(rate.displayRate, "20%")

        let rate2 = CitySurchargeRate(city: "부산광역시", rate: 0.30)
        XCTAssertEqual(rate2.displayRate, "30%")
    }

    func test_CitySurchargeRate_rates_배열_존재() {
        XCTAssertFalse(CitySurchargeRate.rates.isEmpty)
        XCTAssertEqual(CitySurchargeRate.rates.count, 9)  // 9개 도시
    }

    func test_부분문자열_매칭_서울() {
        let rate = CitySurchargeRate.rate(for: "서울")
        XCTAssertEqual(rate, 0.20)
    }

    func test_부분문자열_매칭_부산() {
        let rate = CitySurchargeRate.rate(for: "부산")
        XCTAssertEqual(rate, 0.30)
    }
}
