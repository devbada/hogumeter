//
//  PassengerCountView.swift
//  HoguMeter
//
//  Created on 2025-12-17.
//

import SwiftUI

/// N빵 계산을 위한 승객 수 선택 뷰
struct PassengerCountView: View {
    @Binding var count: Int
    let totalFare: Int
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 8) {
            // 승객 수 선택
            HStack(spacing: 12) {
                Text("👥")
                    .font(.title2)

                Text("N빵")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // 승객 수 버튼들
                HStack(spacing: 4) {
                    ForEach(1...6, id: \.self) { num in
                        Button {
                            count = num
                        } label: {
                            Text("\(num)")
                                .font(.system(size: 14, weight: count == num ? .bold : .regular))
                                .frame(width: 32, height: 32)
                                .background(count == num ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(count == num ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .disabled(!isEnabled)
                    }
                }
            }

            // 1인당 금액 표시 (2명 이상일 때만)
            if count > 1 {
                HStack {
                    Text("1인당")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(farePerPerson.formattedWithComma)원")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    /// 1인당 요금 계산 (올림)
    private var farePerPerson: Int {
        guard count > 1 else { return totalFare }
        return Int(ceil(Double(totalFare) / Double(count)))
    }
}

#Preview {
    VStack(spacing: 20) {
        PassengerCountView(
            count: .constant(1),
            totalFare: 12400,
            isEnabled: true
        )

        PassengerCountView(
            count: .constant(3),
            totalFare: 12400,
            isEnabled: true
        )

        PassengerCountView(
            count: .constant(4),
            totalFare: 15000,
            isEnabled: false
        )
    }
    .padding()
}
