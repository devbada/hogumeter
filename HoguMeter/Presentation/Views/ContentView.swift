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
        ContentViewInner(appState: appState, colorSchemePreference: $colorSchemePreference)
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

/// 내부 뷰 - MeterViewModel을 @State로 안전하게 관리
private struct ContentViewInner: View {
    let appState: AppState
    @Binding var colorSchemePreference: SettingsRepository.ColorSchemePreference
    @State private var meterViewModel: MeterViewModel?

    /// 미터기 실행 중 여부 (탭바 숨김용)
    private var isMeterRunning: Bool {
        meterViewModel?.state == .running
    }

    var body: some View {
        Group {
            if let viewModel = meterViewModel {
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
                .toolbar(isMeterRunning ? .hidden : .visible, for: .tabBar)
                .animation(.easeInOut(duration: 0.3), value: isMeterRunning)
            } else {
                ProgressView("로딩 중...")
            }
        }
        .onAppear {
            if meterViewModel == nil {
                meterViewModel = MeterViewModel(
                    locationService: appState.locationService,
                    fareCalculator: appState.fareCalculator,
                    regionDetector: appState.regionDetector,
                    soundManager: appState.soundManager,
                    tripRepository: appState.tripRepository
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
