//
//  TooltipBubble.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import SwiftUI

/// Tooltip bubble that shows title, description, and navigation buttons
struct TooltipBubble: View {
    let title: String
    let description: String
    let position: TooltipPosition
    let targetFrame: CGRect
    let onNext: () -> Void
    let onSkip: () -> Void
    let currentIndex: Int
    let totalCount: Int

    @State private var tooltipSize: CGSize = .zero

    private let maxWidth: CGFloat = 300
    private let arrowSize: CGFloat = 10
    private let tooltipPadding: CGFloat = 16
    private let screenPadding: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            let calculatedPosition = calculateTooltipPosition(in: geometry)

            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Description
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                // Footer with progress and buttons
                HStack {
                    // Progress indicator
                    HStack(spacing: 4) {
                        ForEach(0..<totalCount, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.yellow : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                    }

                    Spacer()

                    // Skip button
                    Button(action: onSkip) {
                        Text("건너뛰기")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Next/Done button
                    Button(action: onNext) {
                        Text(currentIndex == totalCount - 1 ? "완료" : "다음")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.yellow)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.15))
            )
            .frame(maxWidth: maxWidth)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: TooltipSizePreferenceKey.self, value: geo.size)
                }
            )
            .onPreferenceChange(TooltipSizePreferenceKey.self) { size in
                tooltipSize = size
            }
            .position(x: calculatedPosition.x, y: calculatedPosition.y)
        }
    }

    private func calculateTooltipPosition(in geometry: GeometryProxy) -> CGPoint {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height

        // Default tooltip size estimate if not yet measured
        let estimatedWidth = min(maxWidth, screenWidth - screenPadding * 2)
        let tooltipWidth = tooltipSize.width > 0 ? tooltipSize.width : estimatedWidth
        let tooltipHeight = tooltipSize.height > 0 ? tooltipSize.height : 150

        var x: CGFloat
        var y: CGFloat

        // Determine actual position (auto-calculate if needed)
        let actualPosition = resolvePosition(in: geometry, tooltipHeight: tooltipHeight)

        switch actualPosition {
        case .top:
            x = targetFrame.midX
            y = targetFrame.minY - tooltipHeight / 2 - tooltipPadding - arrowSize

        case .bottom:
            x = targetFrame.midX
            y = targetFrame.maxY + tooltipHeight / 2 + tooltipPadding + arrowSize

        case .left:
            x = targetFrame.minX - tooltipWidth / 2 - tooltipPadding - arrowSize
            y = targetFrame.midY

        case .right:
            x = targetFrame.maxX + tooltipWidth / 2 + tooltipPadding + arrowSize
            y = targetFrame.midY

        case .auto:
            // Fallback (should not reach here after resolvePosition)
            x = screenWidth / 2
            y = targetFrame.maxY + tooltipHeight / 2 + tooltipPadding + arrowSize
        }

        // Clamp to screen bounds
        let halfWidth = tooltipWidth / 2
        x = max(halfWidth + screenPadding, min(screenWidth - halfWidth - screenPadding, x))

        let halfHeight = tooltipHeight / 2
        y = max(halfHeight + screenPadding, min(screenHeight - halfHeight - screenPadding, y))

        return CGPoint(x: x, y: y)
    }

    private func resolvePosition(in geometry: GeometryProxy, tooltipHeight: CGFloat) -> TooltipPosition {
        if position != .auto {
            return position
        }

        let screenHeight = geometry.size.height

        // Prefer bottom if there's enough space
        let spaceBelow = screenHeight - targetFrame.maxY
        let spaceAbove = targetFrame.minY

        if spaceBelow >= tooltipHeight + tooltipPadding * 2 + arrowSize {
            return .bottom
        } else if spaceAbove >= tooltipHeight + tooltipPadding * 2 + arrowSize {
            return .top
        } else {
            return .bottom // Default fallback
        }
    }
}

private struct TooltipSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()

        TooltipBubble(
            title: "요금 표시",
            description: "실시간으로 계산되는 택시 요금이 여기에 표시됩니다.",
            position: .bottom,
            targetFrame: CGRect(x: 100, y: 200, width: 200, height: 50),
            onNext: {},
            onSkip: {},
            currentIndex: 0,
            totalCount: 4
        )
    }
}
