//
//  RegionFareRepository.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class RegionFareRepository {

    // MARK: - Properties
    private(set) var defaultFares: [RegionFare] = []

    // MARK: - Init
    init() {
        loadDefaultFares()
    }

    // MARK: - Public Methods
    func getFare(byCode code: String) -> RegionFare? {
        defaultFares.first { $0.code == code }
    }

    func getAllFares() -> [RegionFare] {
        defaultFares
    }

    // MARK: - Private Methods
    private func loadDefaultFares() {
        // JSON 파일에서 로드 (나중에 구현)
        // 현재는 하드코딩된 기본값 사용
        defaultFares = [
            RegionFare(
                code: "seoul",
                name: "서울",
                baseFare: 4800,
                baseDistance: 1600,
                distanceFare: 100,
                distanceUnit: 131,
                timeFare: 100,
                timeUnit: 30,
                nightSurchargeRate: 1.2,
                nightStartTime: "22:00",
                nightEndTime: "04:00"
            ),
            RegionFare(
                code: "gyeonggi",
                name: "경기",
                baseFare: 4800,
                baseDistance: 1600,
                distanceFare: 100,
                distanceUnit: 131,
                timeFare: 100,
                timeUnit: 30,
                nightSurchargeRate: 1.2,
                nightStartTime: "22:00",
                nightEndTime: "04:00"
            ),
            RegionFare(
                code: "incheon",
                name: "인천",
                baseFare: 4800,
                baseDistance: 1600,
                distanceFare: 100,
                distanceUnit: 131,
                timeFare: 100,
                timeUnit: 30,
                nightSurchargeRate: 1.2,
                nightStartTime: "22:00",
                nightEndTime: "04:00"
            )
        ]
    }
}
