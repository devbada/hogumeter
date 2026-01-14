//
//  RegionalSurchargeService.swift
//  HoguMeter
//
//  Created on 2025-01-14.
//

import Foundation

/// 지역 할증 서비스
/// 리얼 모드(사업구역 기반)와 재미 모드(동 변경 기반)를 지원
final class RegionalSurchargeService {

    // MARK: - Properties

    /// 현재 모드
    var mode: RegionalSurchargeMode = .realistic

    /// 출발지 사업구역 (시/도 단위)
    private(set) var departureBusinessZone: String?

    /// 현재 할증 적용 중인지 여부
    private(set) var isSurchargeActive: Bool = false

    /// 할증이 시작된 시점 (리얼 모드에서 할증 구간 거리/시간 계산용)
    private(set) var surchargeStartTime: Date?

    /// 할증 구간에서 이동한 거리 (meters)
    private(set) var surchargeDistance: Double = 0

    /// 할증 구간에서 경과한 시간 (seconds)
    private(set) var surchargeDuration: TimeInterval = 0

    /// 마지막 위치 업데이트 시간 (할증 구간 시간 계산용)
    private var lastUpdateTime: Date?

    // MARK: - 서울 특수 구역 (할증 미적용)

    /// 서울 통합사업구역
    private let seoulIntegratedZones = ["광명시", "광명"]

    /// 서울 공동사업구역 (동 이름에 포함되면 예외)
    private let seoulSharedZones = ["위례"]

    // MARK: - Public Methods

    /// 미터기 시작 시 호출 - 출발지 기록
    /// - Parameters:
    ///   - addressInfo: 출발지 주소 정보
    func startTracking(addressInfo: AddressInfo) {
        let city = addressInfo.administrativeArea ?? ""
        departureBusinessZone = extractBusinessZone(from: city)
        isSurchargeActive = false
        surchargeStartTime = nil
        surchargeDistance = 0
        surchargeDuration = 0
        lastUpdateTime = nil
    }

    /// 위치 업데이트 시 호출 - 할증 상태 확인
    /// - Parameters:
    ///   - addressInfo: 현재 주소 정보
    ///   - distanceDelta: 이전 위치에서 이동한 거리 (meters)
    /// - Returns: 할증 상태
    func updateLocation(addressInfo: AddressInfo, distanceDelta: Double = 0) -> SurchargeStatus {
        guard mode != .off else {
            return .inactive
        }

        switch mode {
        case .realistic:
            return checkRealisticSurcharge(addressInfo: addressInfo, distanceDelta: distanceDelta)
        case .fun:
            // 재미 모드는 FareCalculator에서 regionChanges로 처리
            return .inactive
        case .off:
            return .inactive
        }
    }

    /// 미터기 종료 시 호출
    func stopTracking() {
        departureBusinessZone = nil
        isSurchargeActive = false
        surchargeStartTime = nil
        surchargeDistance = 0
        surchargeDuration = 0
        lastUpdateTime = nil
    }

    /// 상태 초기화
    func reset() {
        stopTracking()
    }

    // MARK: - Realistic Mode Logic

    /// 리얼 모드: 사업구역(시/도) 경계 체크
    private func checkRealisticSurcharge(addressInfo: AddressInfo, distanceDelta: Double) -> SurchargeStatus {
        guard let departure = departureBusinessZone else {
            return .inactive
        }

        let currentCity = addressInfo.administrativeArea ?? ""
        let currentZone = extractBusinessZone(from: currentCity)

        // 같은 사업구역이면 할증 없음
        if departure == currentZone || currentZone.isEmpty {
            if isSurchargeActive {
                // 할증 구역에서 복귀
                isSurchargeActive = false
            }
            return .inactive
        }

        // 특수 구역 예외 체크
        if isSpecialZoneException(departure: departure, currentAddressInfo: addressInfo) {
            if isSurchargeActive {
                isSurchargeActive = false
            }
            return .inactive
        }

        // 사업구역 벗어남 → 할증 적용
        let rate = CitySurchargeRate.rate(for: departure)

        if !isSurchargeActive {
            // 할증 시작
            isSurchargeActive = true
            surchargeStartTime = Date()
            surchargeDistance = 0
            surchargeDuration = 0
            lastUpdateTime = Date()
        } else {
            // 할증 구간 거리/시간 누적
            surchargeDistance += distanceDelta
            if let lastTime = lastUpdateTime {
                surchargeDuration += Date().timeIntervalSince(lastTime)
            }
            lastUpdateTime = Date()
        }

        return SurchargeStatus(
            isActive: true,
            rate: rate,
            departureZone: departure,
            currentZone: currentZone
        )
    }

    // MARK: - Helper Methods

    /// 사업구역 추출 (시/도 단위)
    private func extractBusinessZone(from city: String) -> String {
        // 광역시/특별시/특별자치시: 그대로 사용
        if city.contains("특별시") || city.contains("광역시") || city.contains("특별자치") {
            // "서울특별시" → "서울특별시"
            return city
        }

        // 도 지역: 도 이름 그대로 반환
        // "경기도" → "경기도"
        return city
    }

    /// 특수 구역 예외 체크
    /// - 서울 → 광명시: 통합사업구역
    /// - 서울 → 위례동: 공동사업구역
    private func isSpecialZoneException(departure: String, currentAddressInfo: AddressInfo) -> Bool {
        // 서울 출발인 경우만 특수 구역 체크
        guard departure.contains("서울") else {
            return false
        }

        let currentCity = currentAddressInfo.administrativeArea ?? ""
        let currentDistrict = currentAddressInfo.locality ?? ""
        let currentDong = currentAddressInfo.subLocality ?? ""

        // 광명시 체크 (통합사업구역)
        for zone in seoulIntegratedZones {
            if currentCity.contains(zone) || currentDistrict.contains(zone) {
                return true
            }
        }

        // 위례신도시 체크 (공동사업구역)
        // 송파구 위례동, 성남시 위례동, 하남시 위례동
        for zone in seoulSharedZones {
            if currentDong.contains(zone) || currentDistrict.contains(zone) {
                return true
            }
        }

        return false
    }
}
