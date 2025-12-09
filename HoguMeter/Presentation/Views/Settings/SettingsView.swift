//
//  SettingsView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct SettingsView: View {
    @State private var isSoundEnabled = true
    @State private var isNightSurchargeEnabled = true
    @State private var isRegionSurchargeEnabled = true

    var body: some View {
        NavigationView {
            Form {
                Section("요금 설정") {
                    NavigationLink {
                        Text("지역별 요금 설정")
                    } label: {
                        Label("지역별 요금", systemImage: "map")
                    }
                }

                Section("할증 설정") {
                    Toggle(isOn: $isNightSurchargeEnabled) {
                        Label("야간 할증", systemImage: "moon")
                    }

                    Toggle(isOn: $isRegionSurchargeEnabled) {
                        Label("지역 할증", systemImage: "location")
                    }
                }

                Section("앱 설정") {
                    Toggle(isOn: $isSoundEnabled) {
                        Label("효과음", systemImage: "speaker.wave.2")
                    }
                }

                Section("정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}

#Preview {
    SettingsView()
}
