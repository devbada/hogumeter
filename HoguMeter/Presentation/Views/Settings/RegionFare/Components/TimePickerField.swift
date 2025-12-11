//
//  TimePickerField.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 시간 선택 필드
struct TimePickerField: View {
    let title: String
    @Binding var time: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            TextField("HH:mm", text: $time)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .keyboardType(.numbersAndPunctuation)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        TimePickerField(
            title: "야간 시작",
            time: .constant("22:00")
        )

        TimePickerField(
            title: "야간 종료",
            time: .constant("04:00")
        )
    }
    .padding()
}
