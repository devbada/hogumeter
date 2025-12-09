//
//  HorseAnimationView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct HorseAnimationView: View {
    let speed: HorseSpeed

    var body: some View {
        ZStack {
            // 배경
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.1))

            // 말 이모지 (실제로는 애니메이션으로 대체 예정)
            VStack(spacing: 10) {
                Text(horseEmoji)
                    .font(.system(size: 100))
                    .scaleEffect(animationScale)
                    .animation(.easeInOut(duration: 0.3), value: speed)

                Text(speedText)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var horseEmoji: String {
        switch speed {
        case .idle:
            return "🐴"
        case .walk:
            return "🐎"
        case .trot, .run:
            return "🏇"
        case .gallop:
            return "🏇💨"
        case .sprint:
            return "🏇💨🔥"
        }
    }

    private var speedText: String {
        switch speed {
        case .idle:
            return "대기 중"
        case .walk:
            return "걷기"
        case .trot:
            return "빠른 걸음"
        case .run:
            return "달리기"
        case .gallop:
            return "질주"
        case .sprint:
            return "폭주!"
        }
    }

    private var animationScale: CGFloat {
        switch speed {
        case .idle:
            return 1.0
        case .walk:
            return 1.05
        case .trot:
            return 1.1
        case .run:
            return 1.15
        case .gallop:
            return 1.2
        case .sprint:
            return 1.3
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HorseAnimationView(speed: .idle)
        HorseAnimationView(speed: .walk)
        HorseAnimationView(speed: .sprint)
    }
    .frame(height: 200)
}
