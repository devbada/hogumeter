//
//  Constants.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

enum Constants {

    // MARK: - App
    enum App {
        static let name = "호구미터"
        static var version: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        }
        static var build: String {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }
        static let slogan = "내 차 탔으면 내놔"
    }

    // MARK: - Location
    enum Location {
        static let lowSpeedThreshold: Double = 15.0  // km/h
        static let gpsUpdateInterval: TimeInterval = 1.0  // seconds
        static let distanceFilter: Double = 10.0  // meters
    }

    // MARK: - Fare
    enum Fare {
        static let defaultRegionCode = "seoul"
        static let defaultRegionSurcharge = 2000  // 원
    }

    // MARK: - Animation
    enum Animation {
        static let transitionDuration: Double = 0.3
        static let targetFPS: Double = 60.0
    }

    // MARK: - Share / Branding
    /// 영수증 공유 및 브랜딩에 사용되는 상수들.
    /// App Store URL 또는 카피 변경이 필요할 경우 이 곳을 수정한다.
    enum Share {
        /// 앱스토어 앱 ID
        static let appStoreID = "6757376286"

        /// 앱스토어 URL (한국 스토어 기준)
        static let appStoreURL = "https://apps.apple.com/kr/app/id\(appStoreID)"

        /// 앱스토어 리뷰 작성 URL
        static let appStoreReviewURL = "\(appStoreURL)?action=write-review"

        /// 브랜드 해시태그 (영수증 워터마크 및 공유 텍스트에 사용)
        static let brandHashtag = "#호구미터"

        /// 영수증 이미지 하단 워터마크 (한 줄, 단정한 톤)
        static let watermarkText = "🐴 호구미터 · #호구미터"

        /// 공유 시 함께 보내는 본문 템플릿
        /// `{fare}` 는 콤마 포함 요금 문자열로 치환된다.
        /// 인스타그램 스토리는 텍스트가 함께 전달되지 않으므로 적용 대상에서 제외된다.
        static let shareCaptionTemplate =
            "오늘의 호구비용 {fare}원 🐴\n#호구미터 로 측정함\n→ \(appStoreURL)"
    }
}
