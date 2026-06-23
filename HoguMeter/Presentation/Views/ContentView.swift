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
    @State private var selectedTab: AppTab = .meter
    @State private var meterViewModel: MeterViewModel?
    /// 테마 전환 순간에 잠깐 끼었다가 사라지는 blur 강도 (0이면 선명)
    @State private var themeTransitionBlur: CGFloat = 0

    private let settingsRepository = SettingsRepository()

    var body: some View {
        Group {
            if let meterViewModel = meterViewModel {
                tabs(meterViewModel: meterViewModel)
            } else {
                ProgressView()
            }
        }
        // TODO-minam: 실제 유료 잠금 정책 확정 후 호구게이션 탭 진입 조건을 StoreKit entitlement와 연결해야 합니다.
        // 테마가 바뀌는 순간 잠깐 흐려졌다가 다시 선명해지며 morph 되는 느낌을 준다.
        .blur(radius: themeTransitionBlur)
        .preferredColorScheme(preferredColorScheme)
        // ColorScheme 변경 시 자식 view들의 색 변화를 부드럽게 보간
        .animation(.easeInOut(duration: 0.45), value: preferredColorScheme)
        // 라이트/다크가 실제로 바뀔 때마다 전환 blur 트리거 (자동·수동 모두 포함)
        .onChange(of: preferredColorScheme) { _, _ in
            triggerThemeTransitionBlur()
        }
        .onAppear {
            ensureMeterViewModel()
            loadColorSchemePreference()
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorSchemeChanged)) { _ in
            loadColorSchemePreference()
        }
    }

    private func tabs(meterViewModel: MeterViewModel) -> some View {
        TabView(selection: $selectedTab) {
            MainMeterView(viewModel: meterViewModel)
                .tabItem {
                    Label("미터기", systemImage: "gauge")
                }
                .tag(AppTab.meter)

            HoguNavigationView(
                fareCalculator: appState.fareCalculator,
                meterViewModel: meterViewModel
            )
                .tabItem {
                    Label("호구게이션", systemImage: "map")
                }
                .tag(AppTab.hoguNavigation)

            TripHistoryView()
                .tabItem {
                    Label("기록", systemImage: "clock")
                }
                .tag(AppTab.history)

            StatisticsView(repository: appState.tripRepository)
                .tabItem {
                    Label("통계", systemImage: "chart.bar.fill")
                }
                .tag(AppTab.statistics)

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
    }

    private func ensureMeterViewModel() {
        guard meterViewModel == nil else { return }
        meterViewModel = createMeterViewModel()
    }

    /// 테마 전환 시 blur를 빠르게 올렸다가(↑) 천천히 0으로 내려(↓) 부드러운 전환 연출.
    private func triggerThemeTransitionBlur() {
        // 1) 올라가는 구간: 색이 바뀌기 시작하는 순간 빠르게 흐려진다.
        withAnimation(.easeOut(duration: 0.18)) {
            themeTransitionBlur = 14
        }
        // 2) 내려가는 구간: 색 보간(0.45s)이 끝나갈 즈음 천천히 선명해진다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeInOut(duration: 0.40)) {
                themeTransitionBlur = 0
            }
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

private enum AppTab: Hashable {
    case meter
    case hoguNavigation
    case history
    case statistics
    case settings
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
