//
//  HorseAnimationView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct HorseAnimationView: View {
    let speed: HorseSpeed

    @State private var animationPhase: CGFloat = 0
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // 배경
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary.opacity(0.1))

            // 말 애니메이션 레이어
            VStack(spacing: 10) {
                ZStack {
                    Text(horseEmoji)
                        .font(.system(size: 100))
                        .scaleEffect(animationScale)
                        .rotationEffect(.degrees(rotationAngle))
                        .offset(y: verticalOffset)
                        .animation(.easeInOut(duration: 0.3), value: speed)
                        .onAppear {
                            startAnimation()
                        }
                        .onChange(of: speed) { _, _ in
                            startAnimation()
                        }
                }

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
        let baseScale: CGFloat
        switch speed {
        case .idle:
            baseScale = 1.0
        case .walk:
            baseScale = 1.05
        case .trot:
            baseScale = 1.1
        case .run:
            baseScale = 1.15
        case .gallop:
            baseScale = 1.2
        case .sprint:
            baseScale = 1.3
        }

        // 바운싱 효과 추가
        let bounceEffect = speed == .idle ? 0 : sin(animationPhase) * 0.03
        return baseScale + bounceEffect
    }

    private var verticalOffset: CGFloat {
        guard speed != .idle else { return 0 }

        // 속도에 따른 바운싱 강도
        let bounceStrength: CGFloat
        switch speed {
        case .idle:
            bounceStrength = 0
        case .walk:
            bounceStrength = 2
        case .trot:
            bounceStrength = 4
        case .run:
            bounceStrength = 6
        case .gallop:
            bounceStrength = 8
        case .sprint:
            bounceStrength = 10
        }

        return sin(animationPhase) * bounceStrength
    }

    private func startAnimation() {
        guard speed != .idle else {
            animationPhase = 0
            rotationAngle = 0
            return
        }

        // 속도에 따른 애니메이션 주기
        let duration: Double
        switch speed {
        case .idle:
            duration = 0
        case .walk:
            duration = 1.0
        case .trot:
            duration = 0.8
        case .run:
            duration = 0.6
        case .gallop:
            duration = 0.4
        case .sprint:
            duration = 0.2
        }

        guard duration > 0 else { return }

        // 바운싱 애니메이션
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }

        // 미세한 흔들림 효과
        withAnimation(.easeInOut(duration: duration * 2).repeatForever(autoreverses: true)) {
            rotationAngle = speed == .sprint ? 5 : 2
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
