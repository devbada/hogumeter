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
    @State private var showDisclaimer = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 메인 앱
                ContentView()
                    .environmentObject(appState)

                // 면책 다이얼로그 (매 실행 시)
                if showDisclaimer {
                    DisclaimerDialogView(isPresented: $showDisclaimer)
                        .transition(.opacity)
                }
            }
            .onAppear {
                showDisclaimer = true  // 앱 실행할 때마다 표시
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

    init() {
        // Initialize repositories
        self.settingsRepository = SettingsRepository()
        self.regionFareRepository = RegionFareRepository()
        self.tripRepository = TripRepository()

        // Initialize services
        self.locationService = LocationService()
        self.regionDetector = RegionDetector()
        self.soundManager = SoundManager()
        self.fareCalculator = FareCalculator(settingsRepository: settingsRepository)
    }
}
