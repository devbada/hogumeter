//
//  RegionFareViewModel.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import Foundation
import Observation

@MainActor
@Observable
final class RegionFareViewModel {

    // MARK: - Properties
    private(set) var fares: [RegionFare] = []
    private(set) var selectedFareCode: String = "seoul"

    var errorMessage: String?
    var showError: Bool = false

    private let repository: RegionFareRepository

    // MARK: - Init
    init(repository: RegionFareRepository) {
        self.repository = repository
        loadFares()
    }

    // MARK: - Public Methods

    /// 지역 목록 로드
    func loadFares() {
        fares = repository.getAllFares()
        selectedFareCode = repository.selectedFareCode
    }

    /// 지역 선택
    func selectFare(_ fare: RegionFare) {
        repository.selectFare(code: fare.code)
        selectedFareCode = fare.code
    }

    /// 지역 추가
    func addFare(name: String, basedOn baseCode: String? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            showErrorMessage("지역명을 입력해주세요")
            return
        }

        // 중복 체크
        if fares.contains(where: { $0.name == trimmedName }) {
            showErrorMessage("이미 존재하는 지역명입니다")
            return
        }

        // 기준 지역 가져오기
        let baseFare: RegionFare
        if let baseCode = baseCode,
           let fare = repository.getFare(byCode: baseCode) {
            baseFare = fare
        } else {
            baseFare = repository.getSelectedFare()
        }

        // 새 지역 생성
        let newFare = RegionFare(
            code: trimmedName.lowercased().replacingOccurrences(of: " ", with: "_"),
            name: trimmedName,
            isDefault: false,
            isUserCreated: true,
            baseFare: baseFare.baseFare,
            baseDistance: baseFare.baseDistance,
            distanceFare: baseFare.distanceFare,
            distanceUnit: baseFare.distanceUnit,
            timeFare: baseFare.timeFare,
            timeUnit: baseFare.timeUnit,
            nightSurchargeRate: baseFare.nightSurchargeRate,
            nightStartTime: baseFare.nightStartTime,
            nightEndTime: baseFare.nightEndTime
        )

        repository.addFare(newFare)
        loadFares()
    }

    /// 지역 수정
    func updateFare(_ fare: RegionFare) {
        // 유효성 검사
        let errors = FareValidation.validate(fare)
        if !errors.isEmpty {
            showErrorMessage(errors.joined(separator: "\n"))
            return
        }

        repository.updateFare(fare)
        loadFares()
    }

    /// 지역 삭제
    func deleteFare(_ fare: RegionFare) {
        repository.deleteFare(fare)
        loadFares()
    }

    /// 기본값으로 초기화
    func resetToDefault(_ fare: RegionFare) {
        repository.resetToDefault(fare)
        loadFares()
    }

    /// 기본 제공 지역 목록
    func getDefaultRegionCodes() -> [String] {
        ["seoul", "gyeonggi", "incheon", "busan"]
    }

    /// 기본 제공 지역 이름 가져오기
    func getDefaultRegionName(code: String) -> String {
        switch code {
        case "seoul": return "서울"
        case "gyeonggi": return "경기"
        case "incheon": return "인천"
        case "busan": return "부산"
        default: return code
        }
    }

    // MARK: - Private Methods

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
