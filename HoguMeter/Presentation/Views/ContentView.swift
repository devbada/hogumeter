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
    }

    private func createMeterViewModel() -> MeterViewModel {
        MeterViewModel(
            locationService: appState.locationService,
            fareCalculator: appState.fareCalculator,
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
