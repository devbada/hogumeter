//
//  RegionalSurchargeMode.swift
//  HoguMeter
//
//  Created on 2025-01-14.
//

import Foundation

/// 지역 할증 모드
/// - realistic: 실제 택시처럼 사업구역(시/도) 경계를 벗어날 때만 할증
/// - fun: 동네가 바뀔 때마다 할증 (기존 방식, 가볍게 즐기는 용도)
/// - off: 지역 할증 미적용
enum RegionalSurchargeMode: String, CaseIterable, Codable {
    case realistic = "realistic"
    case fun = "fun"
    case off = "off"

    /// 사용자에게 표시되는 이름
    var displayName: String {
        switch self {
        case .realistic:
            return "리얼 모드 🚕"
        case .fun:
            return "재미 모드 🎮"
        case .off:
            return "끄기"
        }
    }

    /// 모드 설명
    var description: String {
        switch self {
        case .realistic:
            return "실제 택시처럼 사업구역(시/도) 경계를 벗어날 때만 할증 적용"
        case .fun:
            return "동네가 바뀔 때마다 할증 (가볍게 즐기는 용도)"
        case .off:
            return "지역 할증 미적용"
        }
    }
}

/// 할증 상태 정보
struct SurchargeStatus: Equatable {
    /// 할증 적용 중인지 여부
    let isActive: Bool

    /// 할증률 (0.0 ~ 1.0, 예: 0.20 = 20%)
    let rate: Double

    /// 출발지 사업구역 (리얼 모드용)
    var departureZone: String?

    /// 현재 위치 사업구역 (리얼 모드용)
    var currentZone: String?

    /// 할증률 퍼센트 (정수, 예: 20)
    var ratePercentage: Int {
        return Int(rate * 100)
    }

    /// 할증 미적용 상태
    static let inactive = SurchargeStatus(isActive: false, rate: 0)
}

/// 도시별 할증률 정보
struct CitySurchargeRate {
    /// 도시 이름 (시/도)
    let city: String

    /// 할증률 (0.0 ~ 1.0)
    let rate: Double

    /// 표시용 할증률 문자열
    var displayRate: String {
        return "\(Int(rate * 100))%"
    }

    // MARK: - 도시별 할증률 상수

    static let rates: [CitySurchargeRate] = [
        CitySurchargeRate(city: "서울특별시", rate: 0.20),
        CitySurchargeRate(city: "부산광역시", rate: 0.30),
        CitySurchargeRate(city: "인천광역시", rate: 0.30),
        CitySurchargeRate(city: "대구광역시", rate: 0.20),
        CitySurchargeRate(city: "광주광역시", rate: 0.20),
        CitySurchargeRate(city: "대전광역시", rate: 0.30),
        CitySurchargeRate(city: "울산광역시", rate: 0.20),
        CitySurchargeRate(city: "세종특별자치시", rate: 0.20),
        CitySurchargeRate(city: "경기도", rate: 0.20),
    ]

    /// 도시에 해당하는 할증률 반환 (기본값 20%)
    static func rate(for city: String) -> Double {
        for info in rates {
            if city.contains(info.city) || info.city.contains(city) {
                return info.rate
            }
        }
        // 기타 도 지역은 기본 20%
        return 0.20
    }
}
