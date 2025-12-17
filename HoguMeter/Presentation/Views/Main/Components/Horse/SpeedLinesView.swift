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
    @State private var viewSize: CGSize = .zero

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
                viewSize = geometry.size
                if isActive {
                    startAnimating()
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    viewSize = geometry.size
                    startAnimating()
                } else {
                    stopAnimating()
                }
            }
            .onDisappear {
                stopAnimating()
            }
        }
    }

    private func startAnimating() {
        stopAnimating()
        guard viewSize.width > 0 else { return }

        // 초기 라인 생성
        lines = (0..<numberOfLines).map { _ in
            SpeedLine(
                startX: viewSize.width,
                y: CGFloat.random(in: 0...viewSize.height),
                length: AnimationConstants.speedLineLength * intensity,
                opacity: Double.random(in: 0.3...0.7) * intensity
            )
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [self] _ in
            updateLines()
        }
    }

    private func stopAnimating() {
        timer?.invalidate()
        timer = nil
        lines.removeAll()
    }

    private func updateLines() {
        guard viewSize.width > 0 else { return }
        let speed: CGFloat = 300 * intensity  // 속도에 비례한 이동 속도

        lines = lines.map { line in
            var updated = line
            updated.startX -= speed * 0.05  // 왼쪽으로 이동

            // 화면 밖으로 나가면 다시 생성
            if updated.startX < -updated.length {
                updated.startX = viewSize.width
                updated.y = CGFloat.random(in: 0...viewSize.height)
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
