//
//  ParticleSystem.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 파티클 타입
enum ParticleType {
    case dust       // 먼지
    case sweat      // 땀방울
    case fire       // 불꽃
    case smoke      // 연기
    case explosion  // 폭발

    var emoji: String {
        switch self {
        case .dust: return "💨"
        case .sweat: return "💦"
        case .fire: return "🔥"
        case .smoke: return "💨"
        case .explosion: return "💥"
        }
    }

    var color: Color {
        switch self {
        case .dust: return .gray.opacity(0.5)
        case .sweat: return .blue.opacity(0.6)
        case .fire: return .orange
        case .smoke: return .gray.opacity(0.4)
        case .explosion: return .red
        }
    }
}

/// 개별 파티클
struct Particle: Identifiable {
    let id = UUID()
    let type: ParticleType
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var opacity: Double
    var lifetime: Double
    var age: Double = 0

    var isExpired: Bool {
        age >= lifetime
    }
}

/// 파티클 시스템 뷰
struct ParticleSystemView: View {
    let type: ParticleType
    let isActive: Bool

    @State private var particles: [Particle] = []
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(particle: particle)
                        .position(particle.position)
                }
            }
            .onAppear {
                if isActive {
                    startEmitting(in: geometry.size)
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    startEmitting(in: geometry.size)
                } else {
                    stopEmitting()
                }
            }
            .onDisappear {
                stopEmitting()
            }
        }
    }

    private func startEmitting(in size: CGSize) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: AnimationConstants.particleSpawnInterval, repeats: true) { _ in
            if particles.count < AnimationConstants.maxParticles {
                spawnParticle(in: size)
            }
            updateParticles()
        }
    }

    private func stopEmitting() {
        timer?.invalidate()
        timer = nil
        particles.removeAll()
    }

    private func spawnParticle(in size: CGSize) {
        let randomSize = CGFloat.random(in: AnimationConstants.particleSizeRange)

        // 말 뒤쪽에서 생성 (중앙 우측)
        let startX = size.width * 0.6
        let startY = size.height * 0.5 + CGFloat.random(in: -20...20)

        let particle = Particle(
            type: type,
            position: CGPoint(x: startX, y: startY),
            velocity: CGVector(
                dx: CGFloat.random(in: -100...(-50)), // 왼쪽으로 날아감
                dy: CGFloat.random(in: -30...30)
            ),
            size: randomSize,
            opacity: 1.0,
            lifetime: AnimationConstants.particleLifetime
        )

        particles.append(particle)
    }

    private func updateParticles() {
        let deltaTime = AnimationConstants.particleSpawnInterval

        particles = particles.compactMap { particle in
            var updated = particle
            updated.age += deltaTime

            // 물리 업데이트
            updated.position.x += particle.velocity.dx * deltaTime
            updated.position.y += particle.velocity.dy * deltaTime

            // 투명도 감소
            updated.opacity = max(0, 1.0 - (updated.age / updated.lifetime))

            // 만료된 파티클 제거
            return updated.isExpired ? nil : updated
        }
    }
}

/// 개별 파티클 뷰
struct ParticleView: View {
    let particle: Particle

    var body: some View {
        Text(particle.type.emoji)
            .font(.system(size: particle.size))
            .opacity(particle.opacity)
    }
}

#Preview {
    VStack {
        ParticleSystemView(type: .fire, isActive: true)
            .frame(width: 300, height: 200)
            .background(Color.black.opacity(0.1))

        ParticleSystemView(type: .sweat, isActive: true)
            .frame(width: 300, height: 200)
            .background(Color.black.opacity(0.1))
    }
}
