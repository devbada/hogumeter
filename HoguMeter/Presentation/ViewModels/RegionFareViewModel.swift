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
        // 기본 제공 지역은 DefaultFares.json에서, 사용자 지역은 저장된 데이터에서 가져옴
        let baseFare: RegionFare
        if let baseCode = baseCode {
            // 기본 제공 지역 코드인 경우 DefaultFares.json에서 가져옴
            if let defaultFare = repository.getDefaultFare(code: baseCode) {
                baseFare = defaultFare
            } else if let userFare = repository.getFare(byCode: baseCode) {
                // 사용자가 추가한 지역인 경우
                baseFare = userFare
            } else {
                baseFare = repository.getSelectedFare()
            }
        } else {
            baseFare = repository.getSelectedFare()
        }

        // 새 지역 생성
        let newFare = RegionFare(
            code: trimmedName.lowercased().replacingOccurrences(of: " ", with: "_"),
            name: trimmedName,
            isDefault: false,
            isUserCreated: true,
            // 주간 요금
            dayBaseFare: baseFare.dayBaseFare,
            dayBaseDistance: baseFare.dayBaseDistance,
            dayDistanceFare: baseFare.dayDistanceFare,
            dayDistanceUnit: baseFare.dayDistanceUnit,
            dayTimeFare: baseFare.dayTimeFare,
            dayTimeUnit: baseFare.dayTimeUnit,
            // 심야1 요금
            night1BaseFare: baseFare.night1BaseFare,
            night1BaseDistance: baseFare.night1BaseDistance,
            night1DistanceFare: baseFare.night1DistanceFare,
            night1DistanceUnit: baseFare.night1DistanceUnit,
            night1TimeFare: baseFare.night1TimeFare,
            night1TimeUnit: baseFare.night1TimeUnit,
            // 심야2 요금
            night2BaseFare: baseFare.night2BaseFare,
            night2BaseDistance: baseFare.night2BaseDistance,
            night2DistanceFare: baseFare.night2DistanceFare,
            night2DistanceUnit: baseFare.night2DistanceUnit,
            night2TimeFare: baseFare.night2TimeFare,
            night2TimeUnit: baseFare.night2TimeUnit
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
        ["seoul", "busan", "daegu", "incheon", "gwangju", "daejeon", "gyeonggi"]
    }

    /// 기본 제공 지역 이름 가져오기
    func getDefaultRegionName(code: String) -> String {
        switch code {
        case "seoul": return "서울"
        case "busan": return "부산"
        case "daegu": return "대구"
        case "incheon": return "인천"
        case "gwangju": return "광주"
        case "daejeon": return "대전"
        case "gyeonggi": return "경기"
        default: return code
        }
    }

    // MARK: - Private Methods

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
