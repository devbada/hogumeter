//
//  HoguMeterApp.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

@main
struct HoguMeterApp: App {

    // MARK: - Dependencies
    @StateObject private var appState = AppState()
    @StateObject private var disclaimerViewModel = DisclaimerViewModel()
    @State private var showLoadingAnimation = true
    @State private var showDisclaimer = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLoadingAnimation {
                    // 로딩 애니메이션 (말 달리기)
                    LoadingAnimationView {
                        // 애니메이션 완료 후 호출
                        withAnimation(.easeOut(duration: 0.5)) {
                            showLoadingAnimation = false
                            showDisclaimer = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                } else {
                    // 메인 앱
                    ContentView()
                        .environmentObject(appState)

                    // 면책 다이얼로그 (매 실행 시)
                    if showDisclaimer {
                        DisclaimerDialogView(isPresented: $showDisclaimer)
                            .transition(.opacity)
                            .zIndex(1)
                    }
                }
            }
        }
    }
}

// MARK: - AppState
@MainActor
class AppState: ObservableObject {

    // MARK: - Services (Singletons)
    let locationService: LocationService
    let fareCalculator: FareCalculator
    let regionDetector: RegionDetector
    let soundManager: SoundManager

    // MARK: - Repositories
    let tripRepository: TripRepository
    let settingsRepository: SettingsRepository
    let regionFareRepository: RegionFareRepository

    // MARK: - ViewModels (Singleton)
    lazy var meterViewModel: MeterViewModel = {
        MeterViewModel(
            locationService: locationService,
            fareCalculator: fareCalculator,
            regionDetector: regionDetector,
            soundManager: soundManager,
            tripRepository: tripRepository
        )
    }()

    init() {
        // Initialize repositories
        self.settingsRepository = SettingsRepository()
        self.regionFareRepository = RegionFareRepository()
        self.tripRepository = TripRepository()

        // Initialize services
        self.locationService = LocationService(settingsRepository: settingsRepository)
        self.regionDetector = RegionDetector()
        self.soundManager = SoundManager()
        self.fareCalculator = FareCalculator(settingsRepository: settingsRepository)
    }
}
