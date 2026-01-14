//
//  MarqueeTextView.swift
//  HoguMeter
//
//  Created on 2025-12-15.
//

import SwiftUI

/// 오른쪽에서 왼쪽으로 흐르는 마키(Marquee) 텍스트 뷰
struct MarqueeTextView: View {
    let text: String
    let font: Font
    let textColor: Color
    let speed: Double  // 초당 이동 거리 (pt/s)

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isAnimating = false

    init(
        text: String,
        font: Font = .system(size: 14),
        textColor: Color = .gray.opacity(0.35),
        speed: Double = 50
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.speed = speed
    }

    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(font)
                .foregroundColor(textColor)
                .lineLimit(1)
                .fixedSize()
                .background(
                    GeometryReader { textGeometry in
                        Color.clear
                            .onAppear {
                                textWidth = textGeometry.size.width
                            }
                    }
                )
                .offset(x: offset)
                .onAppear {
                    containerWidth = geometry.size.width
                    startAnimation()
                }
                .onChange(of: geometry.size.width) { _, newWidth in
                    containerWidth = newWidth
                    restartAnimation()
                }
        }
        .clipped()
    }

    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        // 오른쪽 밖에서 시작
        offset = containerWidth

        // 애니메이션 지속 시간 계산
        let totalDistance = containerWidth + textWidth
        let duration = totalDistance / speed

        // 무한 반복 애니메이션
        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
        ) {
            offset = -textWidth
        }
    }

    private func restartAnimation() {
        isAnimating = false
        offset = containerWidth
        startAnimation()
    }
}

/// 여러 줄의 마키 텍스트를 표시하는 컨테이너 뷰
struct MarqueeBackgroundView: View {
    let texts: [String]
    let isVisible: Bool

    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                VStack(spacing: geometry.size.height * 0.15) {
                    ForEach(Array(texts.enumerated()), id: \.offset) { index, text in
                        MarqueeTextView(
                            text: text,
                            font: .system(size: 13, weight: .medium),
                            textColor: .primary.opacity(0.12),
                            speed: speeds[index % speeds.count]
                        )
                        .frame(height: 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .allowsHitTesting(false)
    }

    // 각 라인별 다른 속도로 자연스러운 효과
    private let speeds: [Double] = [45, 55, 40]
}

#Preview {
    ZStack {
        Color.white
            .ignoresSafeArea()

        MarqueeBackgroundView(
            texts: [
                "이 앱의 미터기 정보는 엔터테인먼트용입니다",
                "실제 택시요금이 아닙니다 - 참고용으로만 사용하세요",
                "Entertainment purposes only - Not an official taxi meter"
            ],
            isVisible: true
        )
    }
}
