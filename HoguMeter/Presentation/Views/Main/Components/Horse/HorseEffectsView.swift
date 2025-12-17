//
//  HorseEffectsView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 말 애니메이션의 특수 효과 오버레이
struct HorseEffectsView: View {
    let speed: HorseSpeed

    var body: some View {
        ZStack {
            // 속도선 (질주본능, 로켓포)
            if speed.needsSpecialEffects {
                SpeedLinesView(
                    isActive: true,
                    intensity: speedLineIntensity
                )
            }

            // 파티클 효과
            if speed == .gallop {
                // 질주본능: 땀, 불꽃, 연기
                ZStack {
                    ParticleSystemView(type: .sweat, isActive: true)
                    ParticleSystemView(type: .fire, isActive: true)
                    ParticleSystemView(type: .smoke, isActive: true)
                }
            } else if speed == .rocket {
                // 로켓포: 불꽃, 폭발
                ZStack {
                    ParticleSystemView(type: .fire, isActive: true)
                    ParticleSystemView(type: .explosion, isActive: true)
                }
            }
        }
    }

    /// 속도선 강도 (0.0 ~ 1.0)
    private var speedLineIntensity: Double {
        switch speed {
        case .idle, .walk, .trot, .run:
            return 0.0
        case .gallop:
            return 0.6
        case .rocket:
            return 1.0
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack(spacing: 50) {
            VStack {
                Text("질주본능 (Gallop)")
                    .foregroundColor(.white)
                    .font(.headline)

                ZStack {
                    HorseEffectsView(speed: .gallop)
                    HorseCharacterView(speed: .gallop)
                }
                .frame(height: 200)
            }

            VStack {
                Text("로켓포 발사 (Rocket)")
                    .foregroundColor(.white)
                    .font(.headline)

                ZStack {
                    HorseEffectsView(speed: .rocket)
                    HorseCharacterView(speed: .rocket)
                }
                .frame(height: 200)
            }
        }
        .padding()
    }
}
