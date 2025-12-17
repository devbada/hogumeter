//
//  ContentView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var colorSchemePreference: SettingsRepository.ColorSchemePreference = .system

    private let settingsRepository = SettingsRepository()

    var body: some View {
        // AppState의 meterViewModel 직접 사용
        let viewModel = appState.meterViewModel
        let isRunning = viewModel.state == .running

        TabView {
            MainMeterView(viewModel: viewModel)
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
        .toolbar(isRunning ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.3), value: isRunning)
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
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
