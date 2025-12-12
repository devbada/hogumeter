//
//  RegionFareRepository.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class RegionFareRepository: ObservableObject {

    // MARK: - Properties
    @Published private(set) var allFares: [RegionFare] = []
    @Published private(set) var selectedFareCode: String = "seoul"

    private let userDefaultsKey = "region_fares"
    private let selectedFareKey = "selected_fare_code"

    // MARK: - Init
    init() {
        loadFares()
    }

    // MARK: - Public Methods

    /// 모든 지역 요금 가져오기
    func getAllFares() -> [RegionFare] {
        allFares
    }

    /// 코드로 지역 요금 가져오기
    func getFare(byCode code: String) -> RegionFare? {
        allFares.first { $0.code == code }
    }

    /// 현재 선택된 지역 요금 가져오기
    func getSelectedFare() -> RegionFare {
        allFares.first { $0.code == selectedFareCode } ?? allFares.first!
    }

    /// 지역 선택
    func selectFare(code: String) {
        selectedFareCode = code
        UserDefaults.standard.set(code, forKey: selectedFareKey)
    }

    /// 지역 요금 추가
    func addFare(_ fare: RegionFare) {
        allFares.append(fare)
        saveFares()
    }

    /// 지역 요금 업데이트
    func updateFare(_ fare: RegionFare) {
        if let index = allFares.firstIndex(where: { $0.id == fare.id }) {
            var updatedFare = fare
            updatedFare.updatedAt = Date()
            allFares[index] = updatedFare
            saveFares()
        }
    }

    /// 지역 요금 삭제
    func deleteFare(_ fare: RegionFare) {
        guard fare.canDelete else { return }
        allFares.removeAll { $0.id == fare.id }

        // 삭제한 지역이 선택된 지역이면 첫 번째 지역으로 변경
        if selectedFareCode == fare.code, let firstFare = allFares.first {
            selectFare(code: firstFare.code)
        }

        saveFares()
    }

    /// 기본값으로 초기화
    func resetToDefault(_ fare: RegionFare) {
        guard fare.isDefault else { return }

        if let defaultFare = loadDefaultFares().first(where: { $0.code == fare.code }) {
            updateFare(defaultFare)
        }
    }

    /// 기본 제공 지역 요금 가져오기
    func getDefaultFare(code: String) -> RegionFare? {
        loadDefaultFares().first { $0.code == code }
    }

    // MARK: - Private Methods

    /// 요금 데이터 로드
    private func loadFares() {
        // UserDefaults에서 먼저 시도
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedFares = try? JSONDecoder().decode([RegionFare].self, from: data),
           !savedFares.isEmpty {
            allFares = savedFares
        } else {
            // 없으면 기본 요금 로드
            allFares = loadDefaultFares()
            saveFares()
        }

        // 선택된 지역 로드
        if let savedCode = UserDefaults.standard.string(forKey: selectedFareKey),
           allFares.contains(where: { $0.code == savedCode }) {
            selectedFareCode = savedCode
        }
    }

    /// 요금 데이터 저장
    private func saveFares() {
        if let data = try? JSONEncoder().encode(allFares) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    /// DefaultFares.json 파일에서 기본 요금 로드
    private func loadDefaultFares() -> [RegionFare] {
        guard let url = Bundle.main.url(forResource: "DefaultFares", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return createHardcodedDefaults()
        }

        do {
            let decoder = JSONDecoder()
            let fareData = try decoder.decode(DefaultFareData.self, from: data)

            return fareData.regions.map { regionData in
                RegionFare(
                    code: regionData.code,
                    name: regionData.name,
                    isDefault: regionData.isDefault,
                    isUserCreated: regionData.isUserCreated,
                    // 주간 요금
                    dayBaseFare: regionData.dayBaseFare,
                    dayBaseDistance: regionData.dayBaseDistance,
                    dayDistanceFare: regionData.dayDistanceFare,
                    dayDistanceUnit: regionData.dayDistanceUnit,
                    dayTimeFare: regionData.dayTimeFare,
                    dayTimeUnit: regionData.dayTimeUnit,
                    // 심야1 요금
                    night1BaseFare: regionData.night1BaseFare,
                    night1BaseDistance: regionData.night1BaseDistance,
                    night1DistanceFare: regionData.night1DistanceFare,
                    night1DistanceUnit: regionData.night1DistanceUnit,
                    night1TimeFare: regionData.night1TimeFare,
                    night1TimeUnit: regionData.night1TimeUnit,
                    // 심야2 요금
                    night2BaseFare: regionData.night2BaseFare,
                    night2BaseDistance: regionData.night2BaseDistance,
                    night2DistanceFare: regionData.night2DistanceFare,
                    night2DistanceUnit: regionData.night2DistanceUnit,
                    night2TimeFare: regionData.night2TimeFare,
                    night2TimeUnit: regionData.night2TimeUnit
                )
            }
        } catch {
            print("Failed to load DefaultFares.json: \(error)")
            return createHardcodedDefaults()
        }
    }

    /// JSON 로드 실패 시 하드코딩된 기본값 (서울시 택시요금 기준)
    private func createHardcodedDefaults() -> [RegionFare] {
        [
            // 서울 (기본)
            RegionFare.seoul()
        ]
    }
}

// MARK: - Helper Structs for JSON Decoding

private struct DefaultFareData: Codable {
    let version: String
    let lastUpdated: String
    let defaultRegions: [String]
    let regions: [RegionData]
}

private struct RegionData: Codable {
    let code: String
    let name: String
    let isDefault: Bool
    let isUserCreated: Bool

    // 주간 요금
    let dayBaseFare: Int
    let dayBaseDistance: Int
    let dayDistanceFare: Int
    let dayDistanceUnit: Int
    let dayTimeFare: Int
    let dayTimeUnit: Int

    // 심야1 요금
    let night1BaseFare: Int
    let night1BaseDistance: Int
    let night1DistanceFare: Int
    let night1DistanceUnit: Int
    let night1TimeFare: Int
    let night1TimeUnit: Int

    // 심야2 요금
    let night2BaseFare: Int
    let night2BaseDistance: Int
    let night2DistanceFare: Int
    let night2DistanceUnit: Int
    let night2TimeFare: Int
    let night2TimeUnit: Int
}
