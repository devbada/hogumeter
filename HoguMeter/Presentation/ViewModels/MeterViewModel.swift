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
import UIKit

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
    private(set) var completedTrip: Trip?           // 완료된 주행 정보

    // MARK: - Horse Animation State
    private(set) var horseSpeed: HorseSpeed = .idle

    // MARK: - Driver Quote State
    private(set) var currentDriverQuote: String = ""

    // MARK: - Dependencies
    private let _locationService: LocationServiceProtocol
    private let fareCalculator: FareCalculator
    private let settingsRepository: SettingsRepositoryProtocol
    private let _routeManager: RouteManager
    private let _easterEggManager: EasterEggManager

    // 지도 화면에서 사용하기 위한 접근자
    var locationService: LocationServiceProtocol { _locationService }
    var routeManager: RouteManager { _routeManager }
    var easterEggManager: EasterEggManager { _easterEggManager }

    private let regionDetector: RegionDetector
    private let soundManager: SoundManager
    private let tripRepository: TripRepository

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var tripStartTime: Date?
    private var timer: Timer?
    private var lastLocationUpdateTime: Date?
    private let speedTimeoutInterval: TimeInterval = 3.0  // 3초간 업데이트 없으면 속도 0

    // MARK: - Init
    init(
        locationService: LocationServiceProtocol,
        fareCalculator: FareCalculator,
        settingsRepository: SettingsRepositoryProtocol,
        regionDetector: RegionDetector,
        soundManager: SoundManager,
        tripRepository: TripRepository,
        routeManager: RouteManager = RouteManager(),
        easterEggManager: EasterEggManager = EasterEggManager()
    ) {
        self._locationService = locationService
        self.fareCalculator = fareCalculator
        self.settingsRepository = settingsRepository
        self._routeManager = routeManager
        self._easterEggManager = easterEggManager
        self.regionDetector = regionDetector
        self.soundManager = soundManager
        self.tripRepository = tripRepository

        setupBindings()

        // 초기 기본요금 설정
        currentFare = getBaseFare()
    }

    // MARK: - Base Fare Helper

    /// 현재 시간대에 맞는 기본요금 반환
    private func getBaseFare() -> Int {
        let fare = settingsRepository.currentRegionFare
        let timeZone = FareTimeZone.current()
        return fare.getFare(for: timeZone).baseFare
    }

    // MARK: - Actions
    func startMeter() {
        state = .running
        tripStartTime = Date()
        regionDetector.reset()
        _locationService.startTracking()
        startTimer()
        soundManager.play(.meterStart)

        // 화면 항상 켜짐 활성화
        setScreenAlwaysOn(true)

        // 택시기사 한마디: 시간대별 멘트 또는 랜덤 멘트
        currentDriverQuote = DriverQuotes.forTimeOfDay() ?? DriverQuotes.random()

        // 이스터에그: 주행 시작 (신데렐라 모드 체크 포함)
        _easterEggManager.onTripStart(at: tripStartTime ?? Date())
    }

    func stopMeter() {
        state = .stopped
        _locationService.stopTracking()
        stopTimer()
        calculateFinalFare()
        soundManager.play(.meterStop)

        // 화면 항상 켜짐 비활성화
        setScreenAlwaysOn(false)

        // 이스터에그: 주행 종료
        _easterEggManager.onTripEnd()

        // Trip 생성 및 저장
        saveTrip()
    }

    func resetMeter() {
        state = .idle
        currentFare = getBaseFare()  // 0이 아닌 기본요금으로 리셋
        distance = 0
        duration = 0
        currentSpeed = 0
        currentRegion = ""
        fareBreakdown = nil
        horseSpeed = .idle
        completedTrip = nil
        lastLocationUpdateTime = nil
        currentDriverQuote = ""
        _routeManager.clearRoute()

        // 화면 항상 켜짐 비활성화
        setScreenAlwaysOn(false)
    }

    func clearCompletedTrip() {
        completedTrip = nil
    }

    // MARK: - Private Methods
    private func setupBindings() {
        // Location updates
        _locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        // 앱이 활성화되었을 때 (포그라운드 진입) - 화면 항상 켜짐 재설정
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleAppBecameActive()
            }
            .store(in: &cancellables)
    }

    /// 앱이 포그라운드로 돌아왔을 때 화면 항상 켜짐 상태 복원
    private func handleAppBecameActive() {
        // 미터기가 실행 중이면 화면 항상 켜짐 다시 활성화
        if state == .running {
            setScreenAlwaysOn(true)
        }
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        // 미터기가 실행 중이 아니면 요금 계산 및 관련 로직 실행하지 않음
        // 위치 업데이트는 GPS 준비 상태 유지를 위해 계속 수신
        guard state == .running else { return }

        // Update distance
        distance = _locationService.totalDistance / 1000  // m to km

        // Update speed
        currentSpeed = max(0, location.speed * 3.6)  // m/s to km/h
        lastLocationUpdateTime = Date()

        // Update horse animation
        updateHorseAnimation()

        // Update route (경로 기록)
        if _routeManager.startLocation == nil {
            // 첫 위치 - 새 경로 시작
            _routeManager.startNewRoute(at: location)
        } else {
            // 경로에 포인트 추가
            _routeManager.addPoint(location)
        }

        // Calculate fare (병산제: 고속거리 + 저속시간)
        currentFare = fareCalculator.calculate(
            highSpeedDistance: locationService.highSpeedDistance,
            lowSpeedDuration: locationService.lowSpeedDuration,
            regionChanges: regionDetector.regionChangeCount,
            isNightTime: isNightTime
        )

        // 이스터에그 체크
        _easterEggManager.checkSpeed(currentSpeed)
        _easterEggManager.checkDistance(distance)
        _easterEggManager.checkFare(currentFare)

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
                self.checkSpeedTimeout()
            }
        }
    }

    /// 일정 시간 동안 위치 업데이트가 없으면 속도를 0으로 설정
    private func checkSpeedTimeout() {
        guard let lastUpdate = lastLocationUpdateTime else { return }

        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate > speedTimeoutInterval && currentSpeed > 0 {
            currentSpeed = 0
            updateHorseAnimation()
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
            highSpeedDistance: locationService.highSpeedDistance,
            lowSpeedDuration: locationService.lowSpeedDuration,
            regionChanges: regionDetector.regionChangeCount,
            isNightTime: isNightTime
        )
    }

    private func saveTrip() {
        guard let startTime = tripStartTime,
              let breakdown = fareBreakdown else { return }

        let trip = Trip(
            id: UUID(),
            startTime: startTime,
            endTime: Date(),
            totalFare: breakdown.totalFare,
            distance: distance,
            duration: duration,
            startRegion: regionDetector.startRegion ?? "알 수 없음",
            endRegion: currentRegion.isEmpty ? "알 수 없음" : currentRegion,
            regionChanges: regionDetector.regionChangeCount,
            isNightTrip: isNightTime,
            fareBreakdown: breakdown,
            routePoints: _routeManager.routePoints,
            driverQuote: currentDriverQuote.isEmpty ? nil : currentDriverQuote
        )

        tripRepository.save(trip)
        completedTrip = trip  // 영수증 표시용
    }

    // MARK: - Screen Always-On

    /// 화면 항상 켜짐 설정
    /// - Parameter enabled: true면 화면이 자동으로 꺼지지 않음
    private func setScreenAlwaysOn(_ enabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = enabled
        Logger.debug("[Screen] 화면 항상 켜짐: \(enabled ? "활성화" : "비활성화")", log: Logger.ui)
    }
}
