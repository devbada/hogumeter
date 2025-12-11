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
                    baseFare: regionData.baseFare,
                    baseDistance: regionData.baseDistance,
                    distanceFare: regionData.distanceFare,
                    distanceUnit: regionData.distanceUnit,
                    timeFare: regionData.timeFare,
                    timeUnit: regionData.timeUnit,
                    nightSurchargeRate: regionData.nightSurchargeRate,
                    nightStartTime: regionData.nightStartTime,
                    nightEndTime: regionData.nightEndTime
                )
            }
        } catch {
            print("Failed to load DefaultFares.json: \(error)")
            return createHardcodedDefaults()
        }
    }

    /// JSON 로드 실패 시 하드코딩된 기본값
    private func createHardcodedDefaults() -> [RegionFare] {
        [
            RegionFare(
                code: "seoul",
                name: "서울",
                isDefault: true,
                isUserCreated: false,
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
                isDefault: true,
                isUserCreated: false,
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
                isDefault: true,
                isUserCreated: false,
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
                code: "busan",
                name: "부산",
                isDefault: true,
                isUserCreated: false,
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
    let baseFare: Int
    let baseDistance: Int
    let distanceFare: Int
    let distanceUnit: Int
    let timeFare: Int
    let timeUnit: Int
    let nightSurchargeRate: Double
    let nightStartTime: String
    let nightEndTime: String
}
