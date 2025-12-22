//
//  HorseCharacterView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 말 캐릭터 뷰 (이모지 기반)
struct HorseCharacterView: View {
    let speed: HorseSpeed

    @State private var isAnimating = false
    @State private var rocketShakeOffset: CGFloat = 0
    @State private var shakeTimer: Timer?

    var body: some View {
        ZStack {
            // 말 이모지
            Text(speed.emoji)
                .font(.system(size: horseSize))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .offset(x: speed.isRocketMode ? rocketShakeOffset : 0)
                .animation(AnimationConstants.smoothTransition, value: speed)
                .animation(
                    speed.isRocketMode ? AnimationConstants.rocketAnimation : .default,
                    value: rocketShakeOffset
                )
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: speed) { oldValue, newValue in
            startAnimation()
        }
        .onDisappear {
            stopShakeTimer()
        }
    }

    private var horseSize: CGFloat {
        switch speed {
        case .idle: return 80
        case .walk: return 80
        case .trot: return 90
        case .run: return 100
        case .gallop: return 110
        case .rocket: return 120
        }
    }

    private func startAnimation() {
        // 기본 박동 애니메이션
        withAnimation(
            Animation.easeInOut(duration: 1.0 / speed.animationSpeed)
                .repeatForever(autoreverses: true)
        ) {
            isAnimating.toggle()
        }

        // 로켓 모드 흔들림
        if speed.isRocketMode {
            startRocketShake()
        } else {
            rocketShakeOffset = 0
        }
    }

    private func startRocketShake() {
        stopShakeTimer()
        shakeTimer = Timer.scheduledTimer(withTimeInterval: AnimationConstants.shakeDuration, repeats: true) { [self] timer in
            if speed.isRocketMode {
                withAnimation(.linear(duration: AnimationConstants.shakeDuration)) {
                    rocketShakeOffset = CGFloat.random(
                        in: -AnimationConstants.rocketShakeIntensity...AnimationConstants.rocketShakeIntensity
                    )
                }
            } else {
                stopShakeTimer()
            }
        }
    }

    private func stopShakeTimer() {
        shakeTimer?.invalidate()
        shakeTimer = nil
        rocketShakeOffset = 0
    }
}

#Preview {
    VStack(spacing: 30) {
        HorseCharacterView(speed: .idle)
        HorseCharacterView(speed: .walk)
        HorseCharacterView(speed: .trot)
        HorseCharacterView(speed: .run)
        HorseCharacterView(speed: .gallop)
        HorseCharacterView(speed: .rocket)
    }
    .padding()
    .background(Color.black.opacity(0.1))
}
