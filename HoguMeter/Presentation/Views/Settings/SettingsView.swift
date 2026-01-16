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
    @State private var regionalSurchargeMode: RegionalSurchargeMode = .realistic
    @State private var regionSurchargeAmount = 2000
    @State private var colorSchemePreference: SettingsRepository.ColorSchemePreference = .system

    private let repository = SettingsRepository()
    @State private var regionFareViewModel = RegionFareViewModel(repository: RegionFareRepository())

    var body: some View {
        NavigationView {
            Form {
                Section("요금 설정") {
                    NavigationLink {
                        RegionFareListView(viewModel: regionFareViewModel)
                    } label: {
                        Label("지역별 요금", systemImage: "map")
                    }
                }

                Section("할증 설정") {
                    Toggle(isOn: $isNightSurchargeEnabled) {
                        Label("야간 할증", systemImage: "moon")
                    }
                    .onChange(of: isNightSurchargeEnabled) { _, newValue in
                        repository.isNightSurchargeEnabled = newValue
                    }

                    NavigationLink {
                        RegionalSurchargeModeView()
                    } label: {
                        HStack {
                            Label("지역 할증", systemImage: "location")
                            Spacer()
                            Text(regionalSurchargeMode.displayName)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 재미 모드일 때만 할증 금액 설정 표시
                    if regionalSurchargeMode == .fun {
                        Stepper(value: $regionSurchargeAmount, in: 1000...5000, step: 500) {
                            HStack {
                                Text("동 변경 시 할증 금액")
                                Spacer()
                                Text("\(regionSurchargeAmount)원")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: regionSurchargeAmount) { _, newValue in
                            repository.regionSurchargeAmount = newValue
                        }
                    }
                }

                Section("앱 설정") {
                    Toggle(isOn: $isSoundEnabled) {
                        Label("효과음", systemImage: "speaker.wave.2")
                    }
                    .onChange(of: isSoundEnabled) { _, newValue in
                        repository.isSoundEnabled = newValue
                    }

                    Picker("다크 모드", selection: $colorSchemePreference) {
                        Text("시스템 설정").tag(SettingsRepository.ColorSchemePreference.system)
                        Text("라이트").tag(SettingsRepository.ColorSchemePreference.light)
                        Text("다크").tag(SettingsRepository.ColorSchemePreference.dark)
                    }
                    .onChange(of: colorSchemePreference) { _, newValue in
                        repository.colorSchemePreference = newValue
                        NotificationCenter.default.post(name: .colorSchemeChanged, object: nil)
                    }
                }

                Section("정보") {
                    NavigationLink {
                        AppInfoView()
                    } label: {
                        Label("앱 정보", systemImage: "info.circle")
                    }

                    HStack {
                        Text("버전")
                        Spacer()
                        Text("\(Constants.App.version) (\(Constants.App.build))")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://devbada.github.io/hogumeter/privacy.html")!) {
                        HStack {
                            Text("개인정보처리방침")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("설정")
            .onAppear {
                loadSettings()
            }
        }
    }

    private func loadSettings() {
        isSoundEnabled = repository.isSoundEnabled
        isNightSurchargeEnabled = repository.isNightSurchargeEnabled
        regionalSurchargeMode = repository.regionalSurchargeMode
        regionSurchargeAmount = repository.regionSurchargeAmount
        colorSchemePreference = repository.colorSchemePreference
    }
}

#Preview {
    SettingsView()
}
