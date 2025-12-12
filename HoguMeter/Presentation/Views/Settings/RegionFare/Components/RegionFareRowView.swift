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

                // 요금 정보 (주간 기준)
                Text("기본 \(fare.dayBaseFare.formatted())원 | \(fare.dayDistanceUnit)m당 \(fare.dayDistanceFare)원")
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
            fare: RegionFare.seoul(),
            isSelected: true
        )

        RegionFareRowView(
            fare: RegionFare(
                code: "custom",
                name: "내 지역",
                isDefault: false,
                isUserCreated: true,
                dayBaseFare: 5000,
                dayBaseDistance: 1600,
                dayDistanceFare: 100,
                dayDistanceUnit: 131,
                dayTimeFare: 100,
                dayTimeUnit: 30,
                night1BaseFare: 6000,
                night1BaseDistance: 1600,
                night1DistanceFare: 120,
                night1DistanceUnit: 131,
                night1TimeFare: 120,
                night1TimeUnit: 30,
                night2BaseFare: 7000,
                night2BaseDistance: 1600,
                night2DistanceFare: 140,
                night2DistanceUnit: 131,
                night2TimeFare: 140,
                night2TimeUnit: 30
            ),
            isSelected: false
        )
    }
    .padding()
}
