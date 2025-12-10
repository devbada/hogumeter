//
//  MeterViewModel.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import Combine
import CoreLocation
import Observation

@MainActor
@Observable
final class MeterViewModel {

    // MARK: - Published Properties
    private(set) var state: MeterState = .idle
    private(set) var currentFare: Int = 0
    private(set) var distance: Double = 0           // km
    private(set) var duration: TimeInterval = 0     // seconds
    private(set) var currentSpeed: Double = 0       // km/h
    private(set) var currentRegion: String = ""
    private(set) var isNightTime: Bool = false
    private(set) var fareBreakdown: FareBreakdown?

    // MARK: - Horse Animation State
    private(set) var horseSpeed: HorseSpeed = .walk

    // MARK: - Dependencies
    private let locationService: LocationServiceProtocol
    private let fareCalculator: FareCalculator
    private let regionDetector: RegionDetector
    private let soundManager: SoundManager
    private let tripRepository: TripRepository

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var tripStartTime: Date?
    private var timer: Timer?

    // MARK: - Init
    init(
        locationService: LocationServiceProtocol,
        fareCalculator: FareCalculator,
        regionDetector: RegionDetector,
        soundManager: SoundManager,
        tripRepository: TripRepository
    ) {
        self.locationService = locationService
        self.fareCalculator = fareCalculator
        self.regionDetector = regionDetector
        self.soundManager = soundManager
        self.tripRepository = tripRepository

        setupBindings()
    }

    // MARK: - Actions
    func startMeter() {
        state = .running
        tripStartTime = Date()
        regionDetector.reset()
        locationService.startTracking()
        startTimer()
        soundManager.play(.meterStart)
    }

    func stopMeter() {
        state = .stopped
        locationService.stopTracking()
        stopTimer()
        calculateFinalFare()
        soundManager.play(.meterStop)
    }

    func resetMeter() {
        state = .idle
        currentFare = 0
        distance = 0
        duration = 0
        currentSpeed = 0
        currentRegion = ""
        fareBreakdown = nil
        horseSpeed = .walk
    }

    // MARK: - Private Methods
    private func setupBindings() {
        // Location updates
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        // Update distance
        distance = locationService.totalDistance / 1000  // m to km

        // Update speed
        currentSpeed = max(0, location.speed * 3.6)  // m/s to km/h

        // Update horse animation
        updateHorseAnimation()

        // Calculate fare
        currentFare = fareCalculator.calculate(
            distance: locationService.totalDistance,
            lowSpeedDuration: locationService.lowSpeedDuration,
            regionChanges: regionDetector.regionChangeCount,
            isNightTime: isNightTime
        )

        // Check region change
        regionDetector.detect(location: location) { [weak self] newRegion in
            if let newRegion = newRegion, newRegion != self?.currentRegion {
                self?.handleRegionChange(to: newRegion)
            }
        }
    }

    private func updateHorseAnimation() {
        let newSpeed = HorseSpeed.from(speed: currentSpeed)

        // 변화가 있을 때만 업데이트
        if newSpeed != horseSpeed {
            horseSpeed = newSpeed

            // 100km/h 이상 로켓포 발사 특수 효과음
            if newSpeed == .rocket {
                soundManager.play(.horseExcited)
            }
        }
    }

    private func handleRegionChange(to newRegion: String) {
        currentRegion = newRegion
        soundManager.play(.regionChange)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.tripStartTime else { return }
            Task { @MainActor in
                self.duration = Date().timeIntervalSince(startTime)
                self.checkNightTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func checkNightTime() {
        let wasNightTime = isNightTime
        isNightTime = fareCalculator.isNightTime()

        if isNightTime && !wasNightTime {
            soundManager.play(.nightMode)
        }
    }

    private func calculateFinalFare() {
        fareBreakdown = fareCalculator.breakdown(
            distance: locationService.totalDistance,
            lowSpeedDuration: locationService.lowSpeedDuration,
            regionChanges: regionDetector.regionChangeCount,
            isNightTime: isNightTime
        )
    }
}
