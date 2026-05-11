//
//  ReceiptShareServiceTests.swift
//  HoguMeterTests
//
//  공유 텍스트 빌더(`buildShareText`)의 채널별 분기 및 포맷팅을 검증한다.
//  - 인스타그램/사진저장/복사 채널은 텍스트 미전달 (nil)
//  - 카카오톡/iMessage/더보기 채널은 자랑용 멘트 + 앱스토어 링크 포함
//

import XCTest
@testable import HoguMeter

final class ReceiptShareServiceTests: XCTestCase {

    private var sut: ReceiptShareService!

    override func setUp() {
        super.setUp()
        sut = ReceiptShareService.shared
    }

    // MARK: - fare가 nil인 경우 모든 채널에서 nil 반환

    func test_buildShareText_fare가_nil이면_모든_채널에서_nil_반환() {
        ShareDestination.allCases.forEach { destination in
            XCTAssertNil(
                sut.buildShareText(for: destination, fare: nil),
                "fare가 nil이면 \(destination) 채널은 텍스트를 만들지 않아야 한다."
            )
        }
    }

    // MARK: - 텍스트 미전달 채널

    func test_buildShareText_인스타그램은_텍스트_없음() {
        // 인스타그램 스토리는 스티커 방식이라 텍스트가 전달되지 않는다.
        XCTAssertNil(sut.buildShareText(for: .instagram, fare: 12345))
    }

    func test_buildShareText_사진저장은_텍스트_없음() {
        // 사진첩 저장은 텍스트가 의미 없는 액션.
        XCTAssertNil(sut.buildShareText(for: .saveToPhotos, fare: 12345))
    }

    func test_buildShareText_복사는_텍스트_없음() {
        // 클립보드에는 이미지만 복사. 텍스트는 별도 처리.
        XCTAssertNil(sut.buildShareText(for: .copyImage, fare: 12345))
    }

    // MARK: - 텍스트 전달 채널: 본문에 요금/해시태그/앱스토어 링크 포함

    func test_buildShareText_카카오톡은_본문에_요금_해시태그_링크_포함() {
        let text = sut.buildShareText(for: .kakaoTalk, fare: 12345)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("12,345"), "콤마 포맷된 요금이 포함되어야 한다.")
        XCTAssertTrue(text!.contains("#호구미터"), "브랜드 해시태그가 포함되어야 한다.")
        XCTAssertTrue(text!.contains(Constants.Share.appStoreURL), "앱스토어 URL이 포함되어야 한다.")
    }

    func test_buildShareText_iMessage도_동일한_본문_사용() {
        let text = sut.buildShareText(for: .iMessage, fare: 4444)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("4,444"))
        XCTAssertTrue(text!.contains("#호구미터"))
        XCTAssertTrue(text!.contains(Constants.Share.appStoreURL))
    }

    func test_buildShareText_더보기도_동일한_본문_사용() {
        let text = sut.buildShareText(for: .more, fare: 100000)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("100,000"))
        XCTAssertTrue(text!.contains("#호구미터"))
        XCTAssertTrue(text!.contains(Constants.Share.appStoreURL))
    }

    // MARK: - 경계값

    func test_buildShareText_요금이_0원이어도_본문_생성() {
        // 0원도 유효한 케이스(스타트 직후 정지 등). 정책상 fare == nil 만 미생성.
        let text = sut.buildShareText(for: .kakaoTalk, fare: 0)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("0"))
    }

    func test_buildShareText_플레이스홀더가_본문에_남아있지_않음() {
        // 템플릿 치환이 누락되어 "{fare}" 가 그대로 노출되는 사고 방지.
        let text = sut.buildShareText(for: .kakaoTalk, fare: 50000)
        XCTAssertNotNil(text)
        XCTAssertFalse(text!.contains("{fare}"), "치환되지 않은 placeholder가 남으면 안 된다.")
    }

    // MARK: - 상수 sanity check

    func test_appStoreURL은_실제_호구미터_링크() {
        XCTAssertTrue(
            Constants.Share.appStoreURL.contains("id6757376286"),
            "Constants.Share.appStoreURL은 실제 출시된 호구미터 앱 ID를 포함해야 한다."
        )
    }

    func test_워터마크_텍스트가_해시태그_포함() {
        XCTAssertTrue(
            Constants.Share.watermarkText.contains("#호구미터"),
            "영수증 워터마크에는 브랜드 해시태그가 포함되어야 한다."
        )
    }
}
