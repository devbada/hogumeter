//
//  LocationFormatter.swift
//  HoguMeter
//
//  Created on 2025-01-14.
//

import Foundation

/// 주소를 간결한 형식으로 포맷팅하는 유틸리티
///
/// 표시 규칙:
/// 1. 고속도로: "도로명 · 시/군" (예: 경부고속도로 · 천안시)
/// 2. 대로: "도로명 · 구/시" (예: 올림픽대로 · 강서구)
/// 3. 대교: "도로명" (예: 한강대교)
/// 4. 일반도로: 지역 기반 (예: 강서구 화곡동)
enum LocationFormatter {

    /// 주소를 간결한 형식으로 포맷팅
    /// - Parameter address: AddressInfo 객체
    /// - Returns: 포맷팅된 지역 문자열
    static func format(_ address: AddressInfo) -> String {
        // 주소 정보가 없으면 빈 문자열 반환
        guard !address.isEmpty else { return "" }

        // 1. 고속도로 체크
        if address.isExpressway, let roadName = address.thoroughfare {
            return formatExpressway(roadName: roadName, address: address)
        }

        // 2. 대로 체크 (대교 제외)
        if address.isMainRoad, let roadName = address.thoroughfare {
            return formatMainRoad(roadName: roadName, address: address)
        }

        // 3. 대교 체크
        if address.isBridge, let roadName = address.thoroughfare {
            return roadName
        }

        // 4. 일반 도로: 동/읍/면 기반
        return formatByRegion(address)
    }

    // MARK: - Private Methods

    /// 고속도로 포맷: "도로명 · 시/군"
    private static func formatExpressway(roadName: String, address: AddressInfo) -> String {
        // locality에 시/군 정보가 있으면 사용
        if let region = address.locality, !region.isEmpty {
            return "\(roadName) · \(region)"
        }
        // 없으면 도로명만 반환
        return roadName
    }

    /// 대로 포맷: "도로명 · 구/시"
    private static func formatMainRoad(roadName: String, address: AddressInfo) -> String {
        if address.isMetropolitanCity {
            // 서울/광역시: 도로명 · 구
            if let district = address.locality, !district.isEmpty {
                return "\(roadName) · \(district)"
            }
        } else {
            // 도 지역: 도로명 · 시/군
            if let region = address.locality, !region.isEmpty {
                return "\(roadName) · \(region)"
            }
        }
        // 지역 정보 없으면 도로명만 반환
        return roadName
    }

    /// 지역 기반 포맷팅 (일반 도로용)
    private static func formatByRegion(_ address: AddressInfo) -> String {
        // 서울특별시: 구 + 동
        if address.isSeoul {
            return formatSeoul(address)
        }

        // 광역시: 구 + 동
        if address.isMetropolitanCity {
            return formatMetropolitan(address)
        }

        // 도 지역
        return formatProvince(address)
    }

    /// 서울 포맷: "구 동"
    private static func formatSeoul(_ address: AddressInfo) -> String {
        var components: [String] = []

        // 구 (locality)
        if let district = address.locality, !district.isEmpty {
            components.append(district)
        }

        // 동 (subLocality)
        if let dong = address.subLocality, !dong.isEmpty {
            components.append(dong)
        }

        let result = components.joined(separator: " ")
        return result.isEmpty ? "-" : result
    }

    /// 광역시 포맷: "구 동"
    private static func formatMetropolitan(_ address: AddressInfo) -> String {
        var components: [String] = []

        // 구 (locality)
        if let district = address.locality, !district.isEmpty {
            components.append(district)
        }

        // 동 (subLocality)
        if let dong = address.subLocality, !dong.isEmpty {
            components.append(dong)
        }

        let result = components.joined(separator: " ")
        return result.isEmpty ? "-" : result
    }

    /// 도 지역 포맷
    /// - 도 + 군: "군 읍/면" (예: 고령군 개진면)
    /// - 도 + 시 (구 있음): "시 구 동" (예: 천안시 동남구 신부동)
    /// - 도 + 시 (구 없음): "시 동" (예: 김포시 마산동)
    private static func formatProvince(_ address: AddressInfo) -> String {
        var components: [String] = []

        // locality가 군인 경우: "군 읍/면"
        if let locality = address.locality, locality.hasSuffix("군") {
            components.append(locality)
            if let dong = address.subLocality, !dong.isEmpty {
                components.append(dong)
            }
            let result = components.joined(separator: " ")
            return result.isEmpty ? "-" : result
        }

        // 시 (locality)
        if let city = address.locality, !city.isEmpty {
            components.append(city)
        }

        // 구 (subAdministrativeArea) - 도 지역의 시 안에 있는 구
        if let district = address.subAdministrativeArea, !district.isEmpty {
            components.append(district)
        }

        // 동/읍/면 (subLocality)
        if let dong = address.subLocality, !dong.isEmpty {
            components.append(dong)
        }

        let result = components.joined(separator: " ")
        return result.isEmpty ? "-" : result
    }
}
