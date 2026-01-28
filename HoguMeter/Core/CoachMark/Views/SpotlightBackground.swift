//
//  SpotlightBackground.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import SwiftUI

/// Semi-transparent background with a spotlight hole for the target element
struct SpotlightBackground: View {
    let targetFrame: CGRect
    let cornerRadius: CGFloat
    let padding: CGFloat

    init(targetFrame: CGRect, cornerRadius: CGFloat = 12, padding: CGFloat = 8) {
        self.targetFrame = targetFrame
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        GeometryReader { geometry in
            Color.black.opacity(0.75)
                .mask(
                    Canvas { context, size in
                        // Fill the entire canvas
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(.white)
                        )

                        // Cut out the spotlight hole
                        let spotlightRect = CGRect(
                            x: targetFrame.minX - padding,
                            y: targetFrame.minY - padding,
                            width: targetFrame.width + padding * 2,
                            height: targetFrame.height + padding * 2
                        )

                        let spotlightPath = Path(roundedRect: spotlightRect, cornerRadius: cornerRadius)
                        context.blendMode = .destinationOut
                        context.fill(spotlightPath, with: .color(.white))
                    }
                )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.blue

        SpotlightBackground(
            targetFrame: CGRect(x: 100, y: 300, width: 200, height: 100)
        )
    }
}
