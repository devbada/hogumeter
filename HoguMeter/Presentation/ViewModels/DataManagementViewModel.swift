//
//  DataManagementViewModel.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import Foundation
import Combine

/// ViewModel for DataManagementView
@MainActor
final class DataManagementViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var settings: DataManagementSettings
    @Published var stats: StorageStats
    @Published var cleanupPolicyType: CleanupPolicyType
    @Published var ageMonths: Int
    @Published var maxCount: Int
    @Published var maxMB: Int
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    private let cleanupService: DataCleanupService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        settingsRepository: SettingsRepository = SettingsRepository(),
        cleanupService: DataCleanupService = .shared
    ) {
        self.settingsRepository = settingsRepository
        self.cleanupService = cleanupService

        // Load initial values
        let loadedSettings = settingsRepository.dataManagementSettings
        self.settings = loadedSettings
        self.stats = cleanupService.getStorageStats()

        // Initialize policy values based on loaded settings
        switch loadedSettings.cleanupPolicy {
        case .ageBased(let months):
            self.cleanupPolicyType = .ageBased
            self.ageMonths = months
            self.maxCount = 100
            self.maxMB = 100
        case .countBased(let count):
            self.cleanupPolicyType = .countBased
            self.ageMonths = 6
            self.maxCount = count
            self.maxMB = 100
        case .sizeBased(let mb):
            self.cleanupPolicyType = .sizeBased
            self.ageMonths = 6
            self.maxCount = 100
            self.maxMB = mb
        }

        setupBindings()
    }

    // MARK: - Public Methods

    /// Reload storage statistics
    func loadStats() {
        stats = cleanupService.getStorageStats()
    }

    /// Clean up old route data (3 months+)
    func cleanupOldRoutes() {
        isLoading = true
        let cleaned = cleanupService.cleanupOldRoutes(olderThanMonths: 3)
        loadStats()
        isLoading = false
        Logger.gps.debug("[DataManagementViewModel] Cleaned \(cleaned) old routes")
    }

    /// Delete all trip data
    func deleteAllData() {
        isLoading = true
        cleanupService.deleteAllData()
        loadStats()
        isLoading = false
    }

    /// Perform manual cleanup based on current settings
    func performManualCleanup() {
        isLoading = true
        cleanupService.performCleanupIfNeeded()
        loadStats()
        isLoading = false
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Save settings when they change
        $settings
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] newSettings in
                self?.settingsRepository.dataManagementSettings = newSettings
            }
            .store(in: &cancellables)

        // Update cleanup policy when type or values change
        Publishers.CombineLatest4($cleanupPolicyType, $ageMonths, $maxCount, $maxMB)
            .dropFirst()
            .sink { [weak self] (policyType, ageMonths, maxCount, maxMB) in
                self?.updateCleanupPolicy(
                    type: policyType,
                    ageMonths: ageMonths,
                    maxCount: maxCount,
                    maxMB: maxMB
                )
            }
            .store(in: &cancellables)
    }

    private func updateCleanupPolicy(type: CleanupPolicyType, ageMonths: Int, maxCount: Int, maxMB: Int) {
        switch type {
        case .ageBased:
            settings.cleanupPolicy = .ageBased(months: ageMonths)
        case .countBased:
            settings.cleanupPolicy = .countBased(maxCount: maxCount)
        case .sizeBased:
            settings.cleanupPolicy = .sizeBased(maxMB: maxMB)
        }
    }
}
