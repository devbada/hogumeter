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
        HStack(spacing: 8) {
            // 택시 이모지
            Text("🚕")
                .font(.title2)

            // 말풍선
            Text("\"\(quote)\"")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    // 말풍선 꼬리
                    Triangle()
                        .fill(Color(.systemGray6))
                        .frame(width: 10, height: 8)
                        .rotationEffect(.degrees(-90))
                        .offset(x: -5),
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
