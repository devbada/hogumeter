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
        VStack(spacing: 10) {
            Text(horseEmoji)
                .font(.system(size: 100))

            Text(speedText)
                .font(.headline)
                .foregroundColor(.secondary)
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
}

#Preview {
    VStack(spacing: 20) {
        HorseAnimationView(speed: .idle)
        HorseAnimationView(speed: .walk)
        HorseAnimationView(speed: .sprint)
    }
    .frame(height: 200)
}
