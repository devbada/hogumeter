//
//  AddressInfo.swift
//  HoguMeter
//
//  Created on 2025-01-14.
//

import Foundation
import CoreLocation

/// 상세 주소 정보를 담는 구조체
/// CLPlacemark의 주요 속성들을 매핑
struct AddressInfo: Equatable, Codable {
    /// 시/도 (서울특별시, 경기도, 부산광역시 등)
    let administrativeArea: String?

    /// 시/군/구 (천안시, 강서구, 김포시 등)
    let locality: String?

    /// 동/읍/면 (화곡동, 개진면, 전곡읍 등)
    let subLocality: String?

    /// 군/구 - 도 지역의 세부 구역 (동남구, 서북구 등)
    let subAdministrativeArea: String?

    /// 도로명 (올림픽대로, 경부고속도로, 한강대교 등)
    let thoroughfare: String?

    // MARK: - Convenience Initializer

    init(
        administrativeArea: String? = nil,
        locality: String? = nil,
        subLocality: String? = nil,
        subAdministrativeArea: String? = nil,
        thoroughfare: String? = nil
    ) {
        self.administrativeArea = administrativeArea
        self.locality = locality
        self.subLocality = subLocality
        self.subAdministrativeArea = subAdministrativeArea
        self.thoroughfare = thoroughfare
    }

    /// CLPlacemark에서 AddressInfo 생성
    init(placemark: CLPlacemark) {
        self.administrativeArea = placemark.administrativeArea
        self.locality = placemark.locality
        self.subLocality = placemark.subLocality
        self.subAdministrativeArea = placemark.subAdministrativeArea
        self.thoroughfare = placemark.thoroughfare
    }

    // MARK: - Helper Properties

    /// 도로명이 고속도로인지 확인
    var isExpressway: Bool {
        guard let road = thoroughfare else { return false }
        return road.contains("고속도로")
    }

    /// 도로명이 대로인지 확인 (대교 제외)
    var isMainRoad: Bool {
        guard let road = thoroughfare else { return false }
        return road.contains("대로") && !road.contains("대교")
    }

    /// 도로명이 대교인지 확인
    var isBridge: Bool {
        guard let road = thoroughfare else { return false }
        return road.contains("대교")
    }

    /// 광역시/특별시 여부 확인
    var isMetropolitanCity: Bool {
        guard let area = administrativeArea else { return false }
        let metropolitanCities = [
            "서울특별시", "서울",
            "부산광역시", "부산",
            "대구광역시", "대구",
            "인천광역시", "인천",
            "광주광역시", "광주",
            "대전광역시", "대전",
            "울산광역시", "울산",
            "세종특별자치시", "세종"
        ]
        return metropolitanCities.contains(area)
    }

    /// 서울 여부 확인
    var isSeoul: Bool {
        guard let area = administrativeArea else { return false }
        return area == "서울특별시" || area == "서울"
    }

    /// 구/군 정보 (locality 우선, 없으면 subAdministrativeArea)
    var district: String? {
        locality ?? subAdministrativeArea
    }

    /// 동/읍/면 정보
    var dong: String? {
        subLocality
    }

    /// 주소 정보가 비어있는지 확인
    var isEmpty: Bool {
        administrativeArea == nil &&
        locality == nil &&
        subLocality == nil &&
        subAdministrativeArea == nil &&
        thoroughfare == nil
    }
}
