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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
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
