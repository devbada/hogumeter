//
//  EasterEgg.swift
//  HoguMeter
//
//  Created on 2025-12-15.
//

import Foundation

/// 이스터에그 타입 정의
enum EasterEggType: String, CaseIterable {
    case backToTheFuture   // 88km/h 3초 유지
    case sequentialNumber  // 12,345원
    case cinderella        // 00:00 출발
    case marathon          // 42.195km
    case luckyNumber       // 4,444원
    case rocketSpeed       // 100km/h 이상
    case perfectTenK       // 10,000원 정확히
}

/// 이스터에그 데이터 모델
struct EasterEgg: Identifiable, Equatable {
    let id: EasterEggType
    let title: String
    let emoji: String
    let message: String

    /// 이스터에그 정의 목록
    static let all: [EasterEggType: EasterEgg] = [
        .backToTheFuture: EasterEgg(
            id: .backToTheFuture,
            title: "백 투 더 퓨처!",
            emoji: "⚡🚗",
            message: "88km/h 달성! 시간여행 준비 완료!"
        ),
        .sequentialNumber: EasterEgg(
            id: .sequentialNumber,
            title: "연속 숫자!",
            emoji: "🌈",
            message: "12,345원! 행운의 연속!"
        ),
        .cinderella: EasterEgg(
            id: .cinderella,
            title: "신데렐라 모드",
            emoji: "🎃🏰",
            message: "자정에 출발! 호박마차로 변신!"
        ),
        .marathon: EasterEgg(
            id: .marathon,
            title: "마라톤 완주!",
            emoji: "🏃‍♂️🏅",
            message: "42.195km 완주! 당신은 진정한 호구!"
        ),
        .luckyNumber: EasterEgg(
            id: .luckyNumber,
            title: "행운의 숫자!",
            emoji: "🍀",
            message: "4,444원! 행운이 가득!"
        ),
        .rocketSpeed: EasterEgg(
            id: .rocketSpeed,
            title: "광속 호구!",
            emoji: "🚀",
            message: "100km/h 돌파! 우주로 갑니다!"
        ),
        .perfectTenK: EasterEgg(
            id: .perfectTenK,
            title: "만원의 행복",
            emoji: "💰",
            message: "정확히 10,000원! 완벽한 금액!"
        )
    ]

    /// 타입으로 이스터에그 조회
    static func get(_ type: EasterEggType) -> EasterEgg? {
        all[type]
    }
}
