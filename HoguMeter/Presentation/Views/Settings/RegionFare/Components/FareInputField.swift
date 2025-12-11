//
//  FareInputField.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 요금 입력 필드
struct FareInputField: View {
    let title: String
    @Binding var value: Int
    let suffix: String
    let keyboardType: UIKeyboardType

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            TextField("0", value: $value, format: .number)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Text(suffix)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FareInputField(
            title: "기본요금",
            value: .constant(4800),
            suffix: "원",
            keyboardType: .numberPad
        )

        FareInputField(
            title: "기본거리",
            value: .constant(1600),
            suffix: "m",
            keyboardType: .numberPad
        )
    }
    .padding()
}
