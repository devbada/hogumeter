//
//  LoadingAnimationView.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import SwiftUI

/// 앱 시작 시 표시되는 로딩 애니메이션 뷰
/// 말이 미터기를 들고 화면을 가로질러 달리는 재미있는 애니메이션
struct LoadingAnimationView: View {
    @State private var horsePosition: CGFloat = -150
    @State private var horseEmoji: String = "🐴"
    @State private var meterValue: Int = 0
    @State private var showMessage = false
    @State private var isCompleted = false

    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            // 그라데이션 배경
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.58, blue: 0.0),  // 오렌지
                    Color(red: 1.0, green: 0.23, blue: 0.19)  // 레드
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 말 + 미터기 애니메이션
                ZStack {
                    // 말 캐릭터
                    Text(horseEmoji)
                        .font(.system(size: 200))
                        .offset(x: horsePosition, y: -40)

                    // 미터기
                    VStack(spacing: 4) {
                        Text("🚖")
                            .font(.system(size: 40))

                        Text("\(meterValue)원")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.4))
                            )
                    }
                    .offset(x: horsePosition + 50, y: 20)
                }
                .frame(height: 200)

                Spacer()

                // 로딩 메시지
                VStack(spacing: 12) {
                    if showMessage {
                        Text("준비 완료! 🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        HStack(spacing: 8) {
                            Text("로딩중")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))

                            // 점 애니메이션
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 6, height: 6)
                                        .scaleEffect(animatingDot == index ? 1.2 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 0.5)
                                                .repeatForever()
                                                .delay(Double(index) * 0.20),
                                            value: animatingDot
                                        )
                                }
                            }
                        }
                    }
                }
                .frame(height: 60)

                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    @State private var animatingDot = 0

    // MARK: - Animation Logic

    private func startAnimation() {
        // 점 애니메이션 시작
        animatingDot = 0

        // 1. 말이 화면을 가로질러 달리기
        withAnimation(.easeInOut(duration: 2.5)) {
            horsePosition = UIScreen.main.bounds.width + 150
        }

        // 2. 말 이모지 변화 (속도 증가 표현)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            horseEmoji = "🐎"  // 빠른 걸음
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            horseEmoji = "🏇"  // 질주
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            horseEmoji = "💨"  // 초고속
        }

        // 3. 미터기 카운트업 애니메이션
        startMeterCountUp()

        // 4. 완료 메시지 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showMessage = true
                isCompleted = true
            }
        }

        // 5. 완료 콜백 호출
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete?()
        }
    }

    private func startMeterCountUp() {
        var counter = 0
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            if counter < 30 {
                // 랜덤하게 증가 (재미있는 효과)
                let increment = Int.random(in: 200...800)
                meterValue = min(meterValue + increment, 9999)
                counter += 1
            } else {
                timer.invalidate()
                // 최종값으로 설정
                withAnimation {
                    meterValue = 9999
                }
            }
        }
    }
}

#Preview {
    LoadingAnimationView()
}
