//
//  CoachMarkData.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import Foundation

/// Static data for all coach mark screens
enum CoachMarkData {

    // MARK: - Main Screen (메인 미터기)

    static let mainScreen = CoachMarkScreen(
        id: "main",
        screenName: "미터기",
        coachMarks: [
            CoachMark(
                id: "main_fare",
                targetView: "fareDisplay",
                title: "요금 표시",
                description: "실시간으로 계산되는 택시 요금이 여기에 표시됩니다.",
                position: .bottom,
                order: 1
            ),
            CoachMark(
                id: "main_horse",
                targetView: "horseAnimation",
                title: "말 애니메이션",
                description: "속도에 따라 말이 달리는 속도가 변해요! 80km/h 이상이면 폭주합니다.",
                position: .bottom,
                order: 2
            ),
            CoachMark(
                id: "main_stats",
                targetView: "statsGrid",
                title: "주행 정보",
                description: "거리, 시간, 속도, 현재 지역을 실시간으로 확인하세요.",
                position: .top,
                order: 3
            ),
            CoachMark(
                id: "main_start",
                targetView: "startButton",
                title: "시작 버튼",
                description: "여기를 눌러 미터기를 시작하세요! 정지하면 영수증을 확인할 수 있어요.",
                position: .top,
                order: 4
            )
        ]
    )

    // MARK: - Map Screen (지도) - accessed during trip

    static let mapScreen = CoachMarkScreen(
        id: "map",
        screenName: "지도",
        coachMarks: [
            CoachMark(
                id: "map_route",
                targetView: "routeMap",
                title: "경로 표시",
                description: "주행 경로가 지도에 실시간으로 그려집니다.",
                position: .bottom,
                order: 1
            ),
            CoachMark(
                id: "map_info",
                targetView: "mapInfoGrid",
                title: "주행 정보",
                description: "요금, 속도, 거리, 시간을 한눈에 확인할 수 있어요.",
                position: .top,
                order: 2
            ),
            CoachMark(
                id: "map_close",
                targetView: "closeButton",
                title: "미터기로 돌아가기",
                description: "여기를 누르면 미터기 화면으로 돌아갑니다.",
                position: .bottom,
                order: 3
            )
        ]
    )

    // MARK: - History Screen (기록)

    static let historyScreen = CoachMarkScreen(
        id: "history",
        screenName: "기록",
        coachMarks: [
            CoachMark(
                id: "history_list",
                targetView: "tripList",
                title: "주행 기록",
                description: "완료된 주행 기록이 여기에 저장됩니다. 아래로 스크롤하면 더 많은 기록을 볼 수 있어요.",
                position: .bottom,
                order: 1
            ),
            CoachMark(
                id: "history_item",
                targetView: "tripItem",
                title: "상세 보기",
                description: "기록을 탭하면 영수증과 상세 정보를 다시 볼 수 있어요.",
                position: .bottom,
                order: 2
            )
        ]
    )

    // MARK: - Settings Screen (설정)

    static let settingsScreen = CoachMarkScreen(
        id: "settings",
        screenName: "설정",
        coachMarks: [
            CoachMark(
                id: "settings_region",
                targetView: "regionSetting",
                title: "지역 설정",
                description: "출발 지역의 택시 요금 기준을 선택하세요. (서울, 부산, 대구 등)",
                position: .bottom,
                order: 1
            ),
            CoachMark(
                id: "settings_surcharge",
                targetView: "surchargeMode",
                title: "할증 설정",
                description: "야간 할증, 지역 할증 등 다양한 할증 옵션을 설정할 수 있어요.",
                position: .bottom,
                order: 2
            ),
            CoachMark(
                id: "settings_sound",
                targetView: "soundSetting",
                title: "앱 설정",
                description: "효과음, 다크 모드 등 앱 환경을 설정할 수 있어요.",
                position: .bottom,
                order: 3
            ),
            CoachMark(
                id: "settings_guide",
                targetView: "resetGuide",
                title: "가이드 다시 보기",
                description: "이 가이드를 다시 보고 싶으면 여기를 눌러주세요!",
                position: .top,
                order: 4
            )
        ]
    )
}
