//
//  RegionFareSettingsView.swift
//  HoguMeter
//
//  Created on 2025-12-09.
//

import SwiftUI

struct RegionFareSettingsView: View {
    @State private var selectedRegionCode = "seoul"

    private let repository = SettingsRepository()
    private let fareRepository = RegionFareRepository()

    var body: some View {
        List {
            ForEach(fareRepository.allFares, id: \.code) { fare in
                Button {
                    selectedRegionCode = fare.code
                    repository.setCurrentRegion(code: fare.code)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fare.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("기본 \(fare.dayBaseFare)원 | 거리 \(fare.dayDistanceUnit)m당 \(fare.dayDistanceFare)원")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if selectedRegionCode == fare.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("지역별 요금")
        .onAppear {
            selectedRegionCode = repository.currentRegionFare.code
        }
    }
}

#Preview {
    NavigationView {
        RegionFareSettingsView()
    }
}
