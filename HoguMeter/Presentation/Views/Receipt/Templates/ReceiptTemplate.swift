//
//  ReceiptTemplate.swift
//  HoguMeter
//
//  Receipt template definitions for various visual styles.
//

import SwiftUI

/// 영수증 템플릿 종류
enum ReceiptTemplate: String, CaseIterable, Codable {
    case classic    // 기본 클래식 스타일
    case modern     // 모던 미니멀 스타일
    case fun        // 재미있는 이모지 스타일
    case minimal    // 최소 정보만 표시
    case premium    // 프리미엄 골드 스타일

    /// 템플릿 표시 이름
    var displayName: String {
        switch self {
        case .classic: return "클래식"
        case .modern: return "모던"
        case .fun: return "재미"
        case .minimal: return "심플"
        case .premium: return "프리미엄"
        }
    }

    /// 템플릿 설명
    var description: String {
        switch self {
        case .classic: return "기본 영수증 스타일"
        case .modern: return "깔끔한 모던 디자인"
        case .fun: return "이모지가 가득한 재미있는 스타일"
        case .minimal: return "핵심 정보만 담은 심플한 스타일"
        case .premium: return "고급스러운 골드 테마"
        }
    }

    /// 템플릿 아이콘 (SF Symbol)
    var iconName: String {
        switch self {
        case .classic: return "doc.text"
        case .modern: return "rectangle.portrait"
        case .fun: return "face.smiling"
        case .minimal: return "square"
        case .premium: return "star.fill"
        }
    }

    /// 템플릿 미리보기 색상
    var previewColor: Color {
        switch self {
        case .classic: return .blue
        case .modern: return .gray
        case .fun: return .orange
        case .minimal: return .black
        case .premium: return .yellow
        }
    }
}

// MARK: - Template Color Scheme

/// 템플릿별 색상 스킴
struct ReceiptColorScheme {
    let backgroundColor: UIColor
    let primaryTextColor: UIColor
    let secondaryTextColor: UIColor
    let accentColor: UIColor
    let dividerColor: UIColor
    let highlightBackgroundColor: UIColor

    static func scheme(for template: ReceiptTemplate) -> ReceiptColorScheme {
        switch template {
        case .classic:
            return ReceiptColorScheme(
                backgroundColor: .white,
                primaryTextColor: .black,
                secondaryTextColor: .gray,
                accentColor: .systemBlue,
                dividerColor: .lightGray,
                highlightBackgroundColor: UIColor.systemBlue.withAlphaComponent(0.1)
            )
        case .modern:
            return ReceiptColorScheme(
                backgroundColor: UIColor(white: 0.98, alpha: 1),
                primaryTextColor: UIColor(white: 0.15, alpha: 1),
                secondaryTextColor: UIColor(white: 0.5, alpha: 1),
                accentColor: UIColor(white: 0.2, alpha: 1),
                dividerColor: UIColor(white: 0.85, alpha: 1),
                highlightBackgroundColor: UIColor(white: 0.95, alpha: 1)
            )
        case .fun:
            return ReceiptColorScheme(
                backgroundColor: UIColor(red: 1, green: 0.98, blue: 0.9, alpha: 1),
                primaryTextColor: UIColor(red: 0.2, green: 0.1, blue: 0, alpha: 1),
                secondaryTextColor: UIColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1),
                accentColor: .systemOrange,
                dividerColor: UIColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1),
                highlightBackgroundColor: UIColor.systemOrange.withAlphaComponent(0.15)
            )
        case .minimal:
            return ReceiptColorScheme(
                backgroundColor: .white,
                primaryTextColor: .black,
                secondaryTextColor: UIColor(white: 0.4, alpha: 1),
                accentColor: .black,
                dividerColor: UIColor(white: 0.9, alpha: 1),
                highlightBackgroundColor: UIColor(white: 0.95, alpha: 1)
            )
        case .premium:
            return ReceiptColorScheme(
                backgroundColor: UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1),
                primaryTextColor: UIColor(red: 0.95, green: 0.85, blue: 0.55, alpha: 1),
                secondaryTextColor: UIColor(red: 0.7, green: 0.65, blue: 0.5, alpha: 1),
                accentColor: UIColor(red: 1, green: 0.84, blue: 0, alpha: 1),
                dividerColor: UIColor(red: 0.3, green: 0.28, blue: 0.2, alpha: 1),
                highlightBackgroundColor: UIColor(red: 0.15, green: 0.14, blue: 0.1, alpha: 1)
            )
        }
    }
}
