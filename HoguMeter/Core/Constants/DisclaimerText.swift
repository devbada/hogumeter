//
//  DisclaimerText.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import Foundation

/// 면책 문구 상수
enum DisclaimerText {

    static let title = "⚠️ 잠깐! 읽어주세요"

    static let intro = """
    이 앱은 친구들과 함께하는 드라이브를 더 재미있게 만들기 위한 🎉 엔터테인먼트 목적의 앱입니다.
    """

    static let warnings = [
        "실제 택시 요금과 다를 수 있습니다",
        "GPS 환경에 따라 거리 측정이 부정확할 수 있습니다",
        "법적 효력이 없는 장난용 앱입니다",
        "요금 분쟁에 사용할 수 없습니다"
    ]

    static let funNote = """
    🐴 "내 차 탔으면 내놔"는 농담입니다. 진지하게 받아들이지 마세요! 😄
    """

    static let checkboxLabel = "위 내용을 이해했으며, 재미로만 사용할 것에 동의합니다."

    static let buttonTitle = "🐴 호구 시작!"

    // MARK: - 앱 정보용
    static let appDescription = """
    호구미터는 친구들과 함께하는 드라이브를 더 재미있게 만들어주는 장난스러운 택시미터기 앱입니다.

    차에 태워주고 "야, 택시비 내놔!" 할 때 사용하세요. 물론 농담으로요! 🐴
    """

    static let disclaimer = """
    • 이 앱은 엔터테인먼트 목적으로만 제작되었습니다.

    • 실제 택시 요금과 차이가 있을 수 있으며, 법적 효력이 없습니다.

    • GPS 환경에 따라 거리 측정이 부정확할 수 있습니다.

    • 요금 분쟁에 이 앱의 결과를 사용할 수 없습니다.
    """
}
