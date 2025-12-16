//
//  DriverQuotes.swift
//  HoguMeter
//
//  Created on 2025-12-16.
//

import Foundation

/// 택시기사 한마디 - 랜덤하게 표시되는 재미있는 멘트
enum DriverQuotes {

    /// 기본 멘트 목록
    static let quotes: [String] = [
        // 일상 대화
        "손님, 어디서 오셨어요?",
        "요즘 기름값이 많이 올랐어요...",
        "이 길이 더 빨라요~ (할증)",
        "손님 덕분에 오늘 매출 좋네요!",
        "에어컨 켜드릴까요?",
        "음악 바꿔드릴까요?",
        "손님, 혹시 급하세요?",
        "오늘 날씨 좋네요~",
        "이 시간에 여기 막히죠...",
        "손님, 카드 되세요?",

        // 호구미터 특유의 멘트
        "손님, 혹시 호구세요?",
        "이 요금이면 제가 호구죠...",
        "친구분이 내시는 거 맞죠?",
        "손님 인상이 좋으시네요~",
        "다음에 또 태워주세요!",
        "손님, 팁은 마음이에요~",
        "오늘 제 첫 손님이세요!",
        "저도 점심값 벌어야죠...",
        "손님, 안전벨트 매셨어요?",
        "거의 다 왔어요~",

        // 상황별 멘트
        "아, 여기 맛집 많아요!",
        "손님, 여기 자주 오세요?",
        "옛날엔 이 동네가...",
        "요즘 택시 타기 힘들죠?",
        "손님, 오늘 좋은 일 있으세요?",
        "저희 아들도 이 나이때...",
        "손님, 혹시 드라이버 해보셨어요?",
        "이 차 새로 뽑았어요!",
        "손님, 창문 열어도 될까요?",
        "곧 휴게소 나와요~"
    ]

    /// 랜덤 멘트 반환
    static func random() -> String {
        quotes.randomElement() ?? "안녕하세요~"
    }

    /// 속도별 특수 멘트
    static func forSpeed(_ speed: Double) -> String? {
        if speed >= 100 {
            return "손님, 너무 빨라요! 제가 무서워요!"
        } else if speed >= 80 {
            return "좀 천천히 갈까요?"
        } else if speed < 5 && speed > 0 {
            return "왜 이렇게 막히죠..."
        }
        return nil
    }

    /// 요금별 특수 멘트
    static func forFare(_ fare: Int) -> String? {
        if fare >= 50000 {
            return "손님, 오늘 큰 손이시네요!"
        } else if fare >= 30000 {
            return "멀리 가시네요~"
        } else if fare == 4800 {
            return "기본요금이에요~"
        }
        return nil
    }

    /// 시간대별 특수 멘트
    static func forTimeOfDay() -> String? {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<5:
            return "이 시간에 어디 가세요?"
        case 5..<7:
            return "아침 일찍 나오셨네요~"
        case 7..<9:
            return "출근길 화이팅!"
        case 11..<13:
            return "점심 맛있게 드세요~"
        case 17..<19:
            return "퇴근하세요? 고생하셨어요!"
        case 22..<24:
            return "늦은 시간까지 고생하세요~"
        default:
            return nil
        }
    }
}
