//
//  SpeedLinesView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 속도선 개별 라인
struct SpeedLine: Identifiable {
    let id = UUID()
    var startX: CGFloat
    var y: CGFloat
    var length: CGFloat
    var opacity: Double
}

/// 속도선 효과 뷰
struct SpeedLinesView: View {
    let isActive: Bool
    let intensity: Double  // 0.0 ~ 1.0

    @State private var lines: [SpeedLine] = []
    @State private var timer: Timer?

    private let numberOfLines = 8
    private let lineColor = Color.white

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for line in lines {
                    var path = Path()
                    path.move(to: CGPoint(x: line.startX, y: line.y))
                    path.addLine(to: CGPoint(x: line.startX - line.length, y: line.y))

                    context.stroke(
                        path,
                        with: .color(lineColor.opacity(line.opacity)),
                        lineWidth: AnimationConstants.speedLineThickness
                    )
                }
            }
            .onAppear {
                if isActive {
                    startAnimating(in: geometry.size)
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    startAnimating(in: geometry.size)
                } else {
                    stopAnimating()
                }
            }
            .onDisappear {
                stopAnimating()
            }
        }
    }

    private func startAnimating(in size: CGSize) {
        // 초기 라인 생성
        lines = (0..<numberOfLines).map { index in
            SpeedLine(
                startX: size.width,
                y: CGFloat.random(in: 0...size.height),
                length: AnimationConstants.speedLineLength * intensity,
                opacity: Double.random(in: 0.3...0.7) * intensity
            )
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateLines(in: size)
        }
    }

    private func stopAnimating() {
        timer?.invalidate()
        timer = nil
        lines.removeAll()
    }

    private func updateLines(in size: CGSize) {
        let speed: CGFloat = 300 * intensity  // 속도에 비례한 이동 속도

        lines = lines.map { line in
            var updated = line
            updated.startX -= speed * 0.05  // 왼쪽으로 이동

            // 화면 밖으로 나가면 다시 생성
            if updated.startX < -updated.length {
                updated.startX = size.width
                updated.y = CGFloat.random(in: 0...size.height)
                updated.length = AnimationConstants.speedLineLength * intensity
                updated.opacity = Double.random(in: 0.3...0.7) * intensity
            }

            return updated
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack(spacing: 30) {
            Text("저속 (30%)")
                .foregroundColor(.white)
            SpeedLinesView(isActive: true, intensity: 0.3)
                .frame(height: 100)

            Text("중속 (60%)")
                .foregroundColor(.white)
            SpeedLinesView(isActive: true, intensity: 0.6)
                .frame(height: 100)

            Text("고속 (100%)")
                .foregroundColor(.white)
            SpeedLinesView(isActive: true, intensity: 1.0)
                .frame(height: 100)
        }
        .padding()
    }
}
