//
//  View+Extensions.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

extension View {

    /// 조건부 modifier 적용
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Haptic 피드백과 함께 버튼 액션 실행
    func withHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, action: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
                action()
            }
        )
    }
}
