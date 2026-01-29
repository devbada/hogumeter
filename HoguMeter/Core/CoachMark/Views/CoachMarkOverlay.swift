//
//  CoachMarkOverlay.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import SwiftUI

/// Full-screen overlay that combines spotlight and tooltip for coach marks
struct CoachMarkOverlay: View {
    @ObservedObject var manager: CoachMarkManager
    let coachMark: CoachMark
    let targetFrame: CGRect

    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Spotlight background with cutout
            SpotlightBackground(targetFrame: targetFrame)
                .opacity(isVisible ? 1 : 0)
                .onTapGesture {
                    // Tapping the dark area advances to next
                    manager.nextCoachMark()
                }

            // Tooltip bubble
            TooltipBubble(
                title: coachMark.title,
                description: coachMark.description,
                position: coachMark.position,
                targetFrame: targetFrame,
                onNext: { manager.nextCoachMark() },
                onSkip: { manager.skipCoachMarks() },
                currentIndex: manager.currentMarkIndex,
                totalCount: manager.currentScreenCoachMarkCount
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: manager.currentMarkIndex)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                isVisible = true
            }
        }
        .onChange(of: manager.isShowingCoachMark) { _, newValue in
            if !newValue {
                withAnimation(.easeIn(duration: 0.2)) {
                    isVisible = false
                }
            }
        }
    }
}

#Preview {
    let manager = CoachMarkManager.shared

    return ZStack {
        Color.blue.ignoresSafeArea()

        VStack {
            Text("Target Element")
                .padding()
                .background(Color.white)
        }

        CoachMarkOverlay(
            manager: manager,
            coachMark: CoachMark(
                id: "test",
                targetView: "test",
                title: "테스트 제목",
                description: "이것은 테스트 설명입니다.",
                position: .bottom,
                order: 1
            ),
            targetFrame: CGRect(x: 100, y: 300, width: 200, height: 50)
        )
    }
}
