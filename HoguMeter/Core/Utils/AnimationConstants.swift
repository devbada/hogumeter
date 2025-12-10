//
//  AnimationConstants.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 애니메이션 관련 상수 정의
enum AnimationConstants {

    // MARK: - Timing
    /// 속도 전환 애니메이션 시간 (0.3초)
    static let speedTransitionDuration: Double = 0.3

    /// 파티클 생성 주기
    static let particleSpawnInterval: Double = 0.1

    /// 속도선 애니메이션 시간
    static let speedLinesDuration: Double = 0.5

    // MARK: - Particle Settings
    /// 최대 파티클 수
    static let maxParticles: Int = 20

    /// 파티클 생명 시간
    static let particleLifetime: Double = 1.5

    /// 파티클 크기 범위
    static let particleSizeRange: ClosedRange<CGFloat> = 4...12

    // MARK: - Effects
    /// 로켓 모드 화면 흔들림 강도
    static let rocketShakeIntensity: CGFloat = 8.0

    /// 화면 흔들림 주기
    static let shakeDuration: Double = 0.1

    /// 속도선 길이
    static let speedLineLength: CGFloat = 100

    /// 속도선 두께
    static let speedLineThickness: CGFloat = 3

    // MARK: - Animation Curves
    /// 부드러운 전환 애니메이션
    static let smoothTransition: Animation = .easeInOut(duration: speedTransitionDuration)

    /// 스프링 애니메이션
    static let springTransition: Animation = .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)

    /// 반복 애니메이션 (로켓 모드)
    static let rocketAnimation: Animation = .linear(duration: 0.05).repeatForever(autoreverses: true)
}
