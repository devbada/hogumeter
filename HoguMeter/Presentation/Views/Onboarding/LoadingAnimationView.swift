//
//  LoadingAnimationView.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import Lottie
import SwiftUI

/// 앱 시작 시 호구미터 브랜드 애니메이션을 표시합니다.
struct LoadingAnimationView: View {
    @State private var hasCompleted = false

    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            Color(red: 0.839, green: 0.353, blue: 0.196)

            HoguMeterSplashLottieView {
                completeOnce()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                completeOnce()
            }
        }
    }

    private func completeOnce() {
        guard !hasCompleted else { return }

        hasCompleted = true
        onComplete?()
    }
}

private struct HoguMeterSplashLottieView: UIViewRepresentable {
    let onComplete: () -> Void

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: "HoguMeterSplash")
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .playOnce
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.isUserInteractionEnabled = false
        animationView.play { finished in
            guard finished else { return }
            onComplete()
        }

        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}

    static func dismantleUIView(_ uiView: LottieAnimationView, coordinator: Void) {
        uiView.stop()
    }
}

#Preview {
    LoadingAnimationView()
}
