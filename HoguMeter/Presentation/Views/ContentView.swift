//
//  ContentView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var colorSchemePreference: SettingsRepository.ColorSchemePreference = .system

    private let settingsRepository = SettingsRepository()

    var body: some View {
        TabView {
            MainMeterView(viewModel: createMeterViewModel())
                .tabItem {
                    Label("미터기", systemImage: "gauge")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }

            TripHistoryView()
                .tabItem {
                    Label("기록", systemImage: "clock")
                }
        }
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            loadColorSchemePreference()
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorSchemeChanged)) { _ in
            loadColorSchemePreference()
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private func loadColorSchemePreference() {
        colorSchemePreference = settingsRepository.colorSchemePreference
    }

    private func createMeterViewModel() -> MeterViewModel {
        MeterViewModel(
            locationService: appState.locationService,
            fareCalculator: appState.fareCalculator,
            settingsRepository: appState.settingsRepository,
            regionDetector: appState.regionDetector,
            soundManager: appState.soundManager,
            tripRepository: appState.tripRepository
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
