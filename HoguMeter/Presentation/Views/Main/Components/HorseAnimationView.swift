//
//  HorseAnimationView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//  Updated: 5-stage horse animation system
//

import SwiftUI

/// 말 애니메이션 메인 뷰 (5단계 속도 시스템)
struct HorseAnimationView: View {
    let speed: HorseSpeed

    var body: some View {
        ZStack {
            // 배경 효과 (속도선, 파티클)
            HorseEffectsView(speed: speed)

            // 말 캐릭터
            VStack(spacing: 12) {
                HorseCharacterView(speed: speed)

                // 상태 텍스트
                Text(speed.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .transition(.opacity)
            }
        }
        .animation(AnimationConstants.smoothTransition, value: speed)
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("5단계 말 애니메이션 시스템")
            .font(.title2)
            .fontWeight(.bold)

        ScrollView {
            VStack(spacing: 30) {
                PreviewCard(speed: .walk, description: "0~5 km/h")
                PreviewCard(speed: .trot, description: "5~10 km/h")
                PreviewCard(speed: .run, description: "10~30 km/h")
                PreviewCard(speed: .gallop, description: "30~100 km/h - 특수 효과")
                PreviewCard(speed: .rocket, description: "100+ km/h - 로켓 모드!")
            }
            .padding()
        }
    }
}

// MARK: - Preview Helper

private struct PreviewCard: View {
    let speed: HorseSpeed
    let description: String

    var body: some View {
        VStack(spacing: 10) {
            Text(speed.displayName)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            HorseAnimationView(speed: speed)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
        }
    }
}
