//
//  RegionFareRowView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 지역 요금 목록 행
struct RegionFareRowView: View {
    let fare: RegionFare
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            Text("🏙️")
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                // 지역명
                Text(fare.name)
                    .font(.headline)

                // 요금 정보
                Text("기본 \(fare.baseFare.formatted())원 | \(fare.distanceUnit)m당 \(fare.distanceFare)원")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 선택 표시
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        RegionFareRowView(
            fare: RegionFare(
                code: "seoul",
                name: "서울",
                isDefault: true,
                baseFare: 4800,
                baseDistance: 1600,
                distanceFare: 100,
                distanceUnit: 131,
                timeFare: 100,
                timeUnit: 30,
                nightSurchargeRate: 1.2,
                nightStartTime: "22:00",
                nightEndTime: "04:00"
            ),
            isSelected: true
        )

        RegionFareRowView(
            fare: RegionFare(
                code: "gyeonggi",
                name: "경기",
                isDefault: true,
                baseFare: 4800,
                baseDistance: 1600,
                distanceFare: 100,
                distanceUnit: 131,
                timeFare: 100,
                timeUnit: 30,
                nightSurchargeRate: 1.2,
                nightStartTime: "22:00",
                nightEndTime: "04:00"
            ),
            isSelected: false
        )
    }
    .padding()
}
