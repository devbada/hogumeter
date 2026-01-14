//
//  LocationFormatterTests.swift
//  HoguMeterTests
//
//  Created on 2025-01-14.
//

import XCTest
@testable import HoguMeter

final class LocationFormatterTests: XCTestCase {

    // MARK: - 고속도로 테스트

    func test_고속도로_경부고속도로_천안시() {
        let address = AddressInfo(
            administrativeArea: "충청남도",
            locality: "천안시",
            thoroughfare: "경부고속도로"
        )
        XCTAssertEqual(LocationFormatter.format(address), "경부고속도로 · 천안시")
    }

    func test_고속도로_도로명만_있는경우() {
        let address = AddressInfo(
            thoroughfare: "영동고속도로"
        )
        XCTAssertEqual(LocationFormatter.format(address), "영동고속도로")
    }

    // MARK: - 대로 테스트

    func test_대로_서울_올림픽대로_강서구() {
        let address = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강서구",
            thoroughfare: "올림픽대로"
        )
        XCTAssertEqual(LocationFormatter.format(address), "올림픽대로 · 강서구")
    }

    func test_대로_광역시_해운대로_해운대구() {
        let address = AddressInfo(
            administrativeArea: "부산광역시",
            locality: "해운대구",
            thoroughfare: "해운대로"
        )
        XCTAssertEqual(LocationFormatter.format(address), "해운대로 · 해운대구")
    }

    func test_대로_도지역_김포대로_김포시() {
        let address = AddressInfo(
            administrativeArea: "경기도",
            locality: "김포시",
            thoroughfare: "김포대로"
        )
        XCTAssertEqual(LocationFormatter.format(address), "김포대로 · 김포시")
    }

    // MARK: - 대교 테스트

    func test_대교_한강대교() {
        let address = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "용산구",
            thoroughfare: "한강대교"
        )
        XCTAssertEqual(LocationFormatter.format(address), "한강대교")
    }

    func test_대교_광안대교() {
        let address = AddressInfo(
            administrativeArea: "부산광역시",
            locality: "수영구",
            thoroughfare: "광안대교"
        )
        XCTAssertEqual(LocationFormatter.format(address), "광안대교")
    }

    // MARK: - 서울 일반 도로 테스트

    func test_서울_강서구_화곡동() {
        let address = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강서구",
            subLocality: "화곡동"
        )
        XCTAssertEqual(LocationFormatter.format(address), "강서구 화곡동")
    }

    func test_서울_영등포구_여의도동() {
        let address = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "영등포구",
            subLocality: "여의도동"
        )
        XCTAssertEqual(LocationFormatter.format(address), "영등포구 여의도동")
    }

    func test_서울_구만있는경우() {
        let address = AddressInfo(
            administrativeArea: "서울특별시",
            locality: "강남구"
        )
        XCTAssertEqual(LocationFormatter.format(address), "강남구")
    }

    // MARK: - 광역시 테스트

    func test_부산_해운대구_우동() {
        let address = AddressInfo(
            administrativeArea: "부산광역시",
            locality: "해운대구",
            subLocality: "우동"
        )
        XCTAssertEqual(LocationFormatter.format(address), "해운대구 우동")
    }

    func test_대전_서구_둔산동() {
        let address = AddressInfo(
            administrativeArea: "대전광역시",
            locality: "서구",
            subLocality: "둔산동"
        )
        XCTAssertEqual(LocationFormatter.format(address), "서구 둔산동")
    }

    func test_인천_연수구_송도동() {
        let address = AddressInfo(
            administrativeArea: "인천광역시",
            locality: "연수구",
            subLocality: "송도동"
        )
        XCTAssertEqual(LocationFormatter.format(address), "연수구 송도동")
    }

    // MARK: - 도 + 시 (구 없음) 테스트

    func test_경기도_김포시_마산동() {
        let address = AddressInfo(
            administrativeArea: "경기도",
            locality: "김포시",
            subLocality: "마산동"
        )
        XCTAssertEqual(LocationFormatter.format(address), "김포시 마산동")
    }

    func test_경기도_파주시_운정동() {
        let address = AddressInfo(
            administrativeArea: "경기도",
            locality: "파주시",
            subLocality: "운정동"
        )
        XCTAssertEqual(LocationFormatter.format(address), "파주시 운정동")
    }

    // MARK: - 도 + 시 (구 있음) 테스트

    func test_충남_천안시_동남구_신부동() {
        let address = AddressInfo(
            administrativeArea: "충청남도",
            locality: "천안시",
            subLocality: "신부동",
            subAdministrativeArea: "동남구"
        )
        XCTAssertEqual(LocationFormatter.format(address), "천안시 동남구 신부동")
    }

    func test_경기도_수원시_팔달구_매교동() {
        let address = AddressInfo(
            administrativeArea: "경기도",
            locality: "수원시",
            subLocality: "매교동",
            subAdministrativeArea: "팔달구"
        )
        XCTAssertEqual(LocationFormatter.format(address), "수원시 팔달구 매교동")
    }

    // MARK: - 도 + 군 테스트

    func test_경북_고령군_개진면() {
        let address = AddressInfo(
            administrativeArea: "경상북도",
            locality: "고령군",
            subLocality: "개진면"
        )
        XCTAssertEqual(LocationFormatter.format(address), "고령군 개진면")
    }

    func test_경기도_연천군_전곡읍() {
        let address = AddressInfo(
            administrativeArea: "경기도",
            locality: "연천군",
            subLocality: "전곡읍"
        )
        XCTAssertEqual(LocationFormatter.format(address), "연천군 전곡읍")
    }

    // MARK: - 엣지 케이스 테스트

    func test_주소정보_없음() {
        let address = AddressInfo()
        XCTAssertEqual(LocationFormatter.format(address), "")
    }

    func test_시도만_있는경우() {
        let address = AddressInfo(
            administrativeArea: "서울특별시"
        )
        XCTAssertEqual(LocationFormatter.format(address), "-")
    }

    func test_세종특별자치시() {
        let address = AddressInfo(
            administrativeArea: "세종특별자치시",
            locality: "조치원읍"
        )
        // 세종시는 광역시로 분류되므로 구 + 동 형식
        XCTAssertEqual(LocationFormatter.format(address), "조치원읍")
    }

    // MARK: - AddressInfo Helper Properties 테스트

    func test_isExpressway() {
        let expressway = AddressInfo(thoroughfare: "경부고속도로")
        let mainRoad = AddressInfo(thoroughfare: "올림픽대로")
        let bridge = AddressInfo(thoroughfare: "한강대교")
        let normal = AddressInfo(thoroughfare: "강남대로")

        XCTAssertTrue(expressway.isExpressway)
        XCTAssertFalse(mainRoad.isExpressway)
        XCTAssertFalse(bridge.isExpressway)
        XCTAssertFalse(normal.isExpressway)
    }

    func test_isMainRoad() {
        let expressway = AddressInfo(thoroughfare: "경부고속도로")
        let mainRoad = AddressInfo(thoroughfare: "올림픽대로")
        let bridge = AddressInfo(thoroughfare: "한강대교")

        XCTAssertFalse(expressway.isMainRoad)
        XCTAssertTrue(mainRoad.isMainRoad)
        XCTAssertFalse(bridge.isMainRoad) // 대교는 대로가 아님
    }

    func test_isBridge() {
        let bridge1 = AddressInfo(thoroughfare: "한강대교")
        let bridge2 = AddressInfo(thoroughfare: "광안대교")
        let mainRoad = AddressInfo(thoroughfare: "올림픽대로")

        XCTAssertTrue(bridge1.isBridge)
        XCTAssertTrue(bridge2.isBridge)
        XCTAssertFalse(mainRoad.isBridge)
    }

    func test_isMetropolitanCity() {
        let seoul = AddressInfo(administrativeArea: "서울특별시")
        let busan = AddressInfo(administrativeArea: "부산광역시")
        let sejong = AddressInfo(administrativeArea: "세종특별자치시")
        let gyeonggi = AddressInfo(administrativeArea: "경기도")

        XCTAssertTrue(seoul.isMetropolitanCity)
        XCTAssertTrue(busan.isMetropolitanCity)
        XCTAssertTrue(sejong.isMetropolitanCity)
        XCTAssertFalse(gyeonggi.isMetropolitanCity)
    }

    func test_isSeoul() {
        let seoul1 = AddressInfo(administrativeArea: "서울특별시")
        let seoul2 = AddressInfo(administrativeArea: "서울")
        let busan = AddressInfo(administrativeArea: "부산광역시")

        XCTAssertTrue(seoul1.isSeoul)
        XCTAssertTrue(seoul2.isSeoul)
        XCTAssertFalse(busan.isSeoul)
    }

    func test_isEmpty() {
        let empty = AddressInfo()
        let notEmpty = AddressInfo(administrativeArea: "서울특별시")

        XCTAssertTrue(empty.isEmpty)
        XCTAssertFalse(notEmpty.isEmpty)
    }
}
