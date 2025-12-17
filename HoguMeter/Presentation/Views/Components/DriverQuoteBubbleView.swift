//
//  DriverQuoteBubbleView.swift
//  HoguMeter
//
//  Created on 2025-12-16.
//

import SwiftUI

/// 택시기사 한마디 말풍선 뷰
struct DriverQuoteBubbleView: View {
    let quote: String

    var body: some View {
        HStack(spacing: 12) {
            // 택시 이모지
            Text("🚕")
                .font(.system(size: 36))

            // 말풍선
            Text("\"\(quote)\"")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.yellow.opacity(0.9))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    // 말풍선 꼬리
                    Triangle()
                        .fill(Color.yellow.opacity(0.9))
                        .frame(width: 12, height: 10)
                        .rotationEffect(.degrees(-90))
                        .offset(x: -6),
                    alignment: .leading
                )
        }
        .padding(.horizontal)
    }
}

/// 말풍선 꼬리용 삼각형
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        DriverQuoteBubbleView(quote: "손님, 어디서 오셨어요?")
        DriverQuoteBubbleView(quote: "오늘 날씨 좋네요~")
        DriverQuoteBubbleView(quote: "이 길이 더 빨라요~ (할증)")
    }
    .padding()
}
