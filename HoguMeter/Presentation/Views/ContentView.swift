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
        // ColorScheme 변경 시 자식 view들의 색 변화를 부드럽게 보간
        .animation(.easeInOut(duration: 0.45), value: preferredColorScheme)
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
        case .auto:
            // 조도 기반: AmbientLightObserver.inferredScheme를 그대로 반영
            // @Observable이라 inferredScheme 변경 시 body가 자동 재평가됨
            return appState.ambientLightObserver.inferredScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private func loadColorSchemePreference() {
        // 사용자가 설정에서 직접 변경한 경우에도 부드러운 전환 적용
        withAnimation(.easeInOut(duration: 0.45)) {
            colorSchemePreference = settingsRepository.colorSchemePreference
        }
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
