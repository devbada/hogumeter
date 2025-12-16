//
//  EasterEggOverlayView.swift
//  HoguMeter
//
//  Created on 2025-12-15.
//

import SwiftUI

/// 이스터에그 발동 시 표시되는 오버레이 뷰
struct EasterEggOverlayView: View {
    let easterEgg: EasterEgg?
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var emojiScale: CGFloat = 0.1
    @State private var textOpacity: Double = 0

    private let displayDuration: TimeInterval = 3.0

    var body: some View {
        if let egg = easterEgg {
            ZStack {
                // 반투명 배경
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                // 이스터에그 내용
                VStack(spacing: 20) {
                    // 이모지 (큰 애니메이션)
                    Text(egg.emoji)
                        .font(.system(size: 80))
                        .scaleEffect(emojiScale)

                    // 타이틀
                    Text(egg.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(textOpacity)

                    // 메시지
                    Text(egg.message)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(textOpacity)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 20)
                )
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(isVisible ? 1.0 : 0)
            }
            .onAppear {
                showAnimation()
                scheduleAutoDismiss()
            }
        }
    }

    private func showAnimation() {
        // 카드 등장
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isVisible = true
        }

        // 이모지 바운스
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) {
            emojiScale = 1.2
        }

        // 이모지 안정화
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.3)) {
            emojiScale = 1.0
        }

        // 텍스트 페이드인
        withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
            textOpacity = 1.0
        }
    }

    private func scheduleAutoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
            emojiScale = 0.5
            textOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color.gray

        EasterEggOverlayView(
            easterEgg: EasterEgg.get(.backToTheFuture),
            onDismiss: {}
        )
    }
}
