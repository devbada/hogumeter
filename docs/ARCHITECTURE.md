# 🏗️ 호구미터 (HoguMeter) - Architecture Document

> **BMAD Method v6 | Architecture Document**
> 
> 문서 버전: 1.0.0  
> 작성일: 2025-01-15  
> 상태: Draft  
> 관련 문서: PROJECT_BRIEF.md, PRD.md

---

## 1. 아키텍처 개요 (Architecture Overview)

### 1.1 시스템 컨텍스트
```
┌─────────────────────────────────────────────────────────────┐
│                        사용자 (Driver)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    호구미터 iOS App                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  UI Layer   │  │   Domain    │  │    Data     │         │
│  │  (SwiftUI)  │◀─│   Layer     │◀─│   Layer     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
          │                │                │
          ▼                ▼                ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │  UIKit   │    │   Core   │    │   Core   │
    │  Share   │    │ Location │    │   Data   │
    └──────────┘    └──────────┘    └──────────┘
                          │
                          ▼
                   ┌──────────┐
                   │   GPS    │
                   │ Hardware │
                   └──────────┘
```

### 1.2 아키텍처 패턴
**MVVM (Model-View-ViewModel)** + **Clean Architecture** 원칙 적용

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │      Views       │◀──▶│   ViewModels     │              │
│  │    (SwiftUI)     │    │  (@Observable)   │              │
│  └──────────────────┘    └──────────────────┘              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Domain Layer                          │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │     Use Cases    │    │     Entities     │              │
│  │   (Services)     │    │    (Models)      │              │
│  └──────────────────┘    └──────────────────┘              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         Data Layer                           │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │   Repositories   │    │   Data Sources   │              │
│  │                  │    │  (Local/Remote)  │              │
│  └──────────────────┘    └──────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 기술 스택 (Tech Stack)

### 2.1 핵심 기술
| 카테고리 | 기술 | 버전 | 용도 |
|---------|-----|------|-----|
| Language | Swift | 5.9+ | 메인 개발 언어 |
| UI Framework | SwiftUI | iOS 15+ | 선언적 UI |
| IDE | Xcode | 15+ | 개발 환경 |
| 위치 서비스 | Core Location | - | GPS 추적 |
| 지도 서비스 | MapKit | - | Reverse Geocoding |
| 로컬 저장소 | Core Data | - | 주행 기록 저장 |
| 오디오 | AVFoundation | - | 효과음 재생 |

### 2.2 개발 도구
| 도구 | 용도 |
|-----|------|
| Xcode Instruments | 성능 프로파일링 |
| SwiftLint | 코드 스타일 검사 |
| Git | 버전 관리 |
| TestFlight | 베타 테스트 배포 |

### 2.3 외부 라이브러리 (선택)
| 라이브러리 | 용도 | 필수 여부 |
|-----------|-----|----------|
| Lottie | 복잡한 애니메이션 | 선택 |
| SwiftUI-Introspect | UIKit 브릿징 | 선택 |

---

## 3. 프로젝트 구조 (Project Structure)

```
HoguMeter/
├── App/
│   ├── HoguMeterApp.swift          # 앱 진입점
│   └── AppDelegate.swift           # 앱 델리게이트 (필요시)
│
├── Presentation/                    # UI Layer
│   ├── Views/
│   │   ├── Main/
│   │   │   ├── MainMeterView.swift     # 메인 미터기 화면
│   │   │   └── Components/
│   │   │       ├── FareDisplayView.swift    # 요금 표시
│   │   │       ├── HorseAnimationView.swift # 말 애니메이션
│   │   │       ├── TripInfoView.swift       # 주행 정보
│   │   │       └── ControlButtonsView.swift # 버튼들
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift          # 설정 메인
│   │   │   ├── RegionFareSettingView.swift # 지역 요금 설정
│   │   │   └── NightSurchargeView.swift    # 야간 할증 설정
│   │   │
│   │   ├── Receipt/
│   │   │   └── ReceiptView.swift           # 영수증 화면
│   │   │
│   │   └── History/
│   │       ├── TripHistoryView.swift       # 주행 기록 목록
│   │       └── TripDetailView.swift        # 기록 상세
│   │
│   └── ViewModels/
│       ├── MeterViewModel.swift            # 메인 미터기 VM
│       ├── SettingsViewModel.swift         # 설정 VM
│       └── HistoryViewModel.swift          # 기록 VM
│
├── Domain/                          # Business Logic Layer
│   ├── Entities/
│   │   ├── Trip.swift                      # 주행 엔티티
│   │   ├── RegionFare.swift                # 지역 요금 엔티티
│   │   ├── FareBreakdown.swift             # 요금 내역 엔티티
│   │   └── MeterState.swift                # 미터기 상태
│   │
│   ├── UseCases/
│   │   ├── FareCalculationUseCase.swift    # 요금 계산
│   │   ├── LocationTrackingUseCase.swift   # 위치 추적
│   │   └── TripManagementUseCase.swift     # 주행 관리
│   │
│   └── Services/
│       ├── FareCalculator.swift            # 요금 계산 서비스
│       ├── LocationService.swift           # 위치 서비스
│       ├── RegionDetector.swift            # 지역 감지 서비스
│       └── SoundManager.swift              # 효과음 서비스
│
├── Data/                            # Data Layer
│   ├── Repositories/
│   │   ├── TripRepository.swift            # 주행 기록 저장소
│   │   ├── SettingsRepository.swift        # 설정 저장소
│   │   └── RegionFareRepository.swift      # 지역 요금 저장소
│   │
│   ├── DataSources/
│   │   ├── Local/
│   │   │   ├── CoreDataManager.swift       # Core Data 관리
│   │   │   ├── UserDefaultsManager.swift   # UserDefaults 관리
│   │   │   └── TripEntity+CoreData.swift   # Core Data 엔티티
│   │   │
│   │   └── Static/
│   │       └── DefaultFares.json           # 기본 요금 데이터
│   │
│   └── DTOs/
│       └── RegionFareDTO.swift             # 데이터 전송 객체
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── Colors/
│   │   ├── Images/
│   │   │   ├── horse_idle.imageset/
│   │   │   ├── horse_walk.imageset/
│   │   │   ├── horse_run.imageset/
│   │   │   └── horse_sprint.imageset/
│   │   └── Backgrounds/
│   │
│   ├── Sounds/
│   │   ├── meter_start.mp3
│   │   ├── meter_tick.mp3
│   │   ├── horse_neigh.mp3
│   │   ├── region_change.mp3
│   │   └── night_mode.mp3
│   │
│   ├── Animations/                  # Lottie 파일 (사용 시)
│   │   └── horse_running.json
│   │
│   └── Localizable/
│       └── Localizable.strings
│
├── Core/                            # Shared Utilities
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Double+Extensions.swift
│   │   ├── CLLocation+Extensions.swift
│   │   └── View+Extensions.swift
│   │
│   ├── Utils/
│   │   ├── Constants.swift
│   │   ├── Logger.swift
│   │   └── HapticManager.swift
│   │
│   └── Protocols/
│       ├── LocationServiceProtocol.swift
│       └── RepositoryProtocol.swift
│
├── HoguMeter.xcdatamodeld/          # Core Data Model
│
└── Tests/
    ├── UnitTests/
    │   ├── FareCalculatorTests.swift
    │   ├── LocationServiceTests.swift
    │   └── MeterViewModelTests.swift
    │
    └── UITests/
        └── MeterFlowUITests.swift
```

---

## 4. 핵심 컴포넌트 설계 (Core Components)

### 4.1 MeterViewModel
```swift
// Presentation/ViewModels/MeterViewModel.swift

import Foundation
import Combine
import CoreLocation

@MainActor
@Observable
final class MeterViewModel {
    
    // MARK: - State
    enum MeterState {
        case idle       // 대기 중
        case running    // 주행 중
        case stopped    // 정지됨
    }
    
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
    private(set) var horseAnimationSpeed: HorseSpeed = .idle
    
    enum HorseSpeed {
        case idle           // 0 km/h
        case walk           // 1-20 km/h
        case trot           // 21-40 km/h
        case run            // 41-60 km/h
        case gallop         // 61-80 km/h
        case sprint         // 80+ km/h
    }
    
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
        fareBreakdown = nil
        horseAnimationSpeed = .idle
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
        let speed = currentSpeed
        
        horseAnimationSpeed = switch speed {
        case 0:
            .idle
        case 1..<21:
            .walk
        case 21..<41:
            .trot
        case 41..<61:
            .run
        case 61..<81:
            .gallop
        default:
            .sprint
        }
        
        // 80km/h 이상 특수 효과음
        if speed >= 80 && horseAnimationSpeed != .sprint {
            soundManager.play(.horseExcited)
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
```

### 4.2 FareCalculator
```swift
// Domain/Services/FareCalculator.swift

import Foundation

final class FareCalculator {
    
    // MARK: - Dependencies
    private let settingsRepository: SettingsRepository
    
    // MARK: - Init
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    // MARK: - Public Methods
    
    /// 실시간 요금 계산
    func calculate(
        distance: Double,           // meters
        lowSpeedDuration: TimeInterval,  // seconds
        regionChanges: Int,
        isNightTime: Bool
    ) -> Int {
        let settings = settingsRepository.currentRegionFare
        
        // 기본요금
        var fare = settings.baseFare
        
        // 거리요금 (기본거리 초과분)
        let extraDistance = max(0, distance - Double(settings.baseDistance))
        let distanceUnits = Int(extraDistance / Double(settings.distanceUnit))
        var distanceFare = distanceUnits * settings.distanceFare
        
        // 시간요금 (저속 시간)
        let timeUnits = Int(lowSpeedDuration / Double(settings.timeUnit))
        var timeFare = timeUnits * settings.timeFare
        
        // 야간 할증
        if isNightTime && settingsRepository.isNightSurchargeEnabled {
            let rate = settings.nightSurchargeRate
            distanceFare = Int(Double(distanceFare) * rate)
            timeFare = Int(Double(timeFare) * rate)
        }
        
        fare += distanceFare + timeFare
        
        // 지역 할증
        if settingsRepository.isRegionSurchargeEnabled {
            fare += regionChanges * settingsRepository.regionSurchargeAmount
        }
        
        return fare
    }
    
    /// 요금 상세 내역 계산
    func breakdown(
        distance: Double,
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        isNightTime: Bool
    ) -> FareBreakdown {
        let settings = settingsRepository.currentRegionFare
        
        let baseFare = settings.baseFare
        
        let extraDistance = max(0, distance - Double(settings.baseDistance))
        let distanceUnits = Int(extraDistance / Double(settings.distanceUnit))
        var distanceFare = distanceUnits * settings.distanceFare
        
        let timeUnits = Int(lowSpeedDuration / Double(settings.timeUnit))
        var timeFare = timeUnits * settings.timeFare
        
        var nightSurcharge = 0
        if isNightTime && settingsRepository.isNightSurchargeEnabled {
            let rate = settings.nightSurchargeRate - 1.0
            nightSurcharge = Int(Double(distanceFare + timeFare) * rate)
            distanceFare = Int(Double(distanceFare) * settings.nightSurchargeRate)
            timeFare = Int(Double(timeFare) * settings.nightSurchargeRate)
        }
        
        var regionSurcharge = 0
        if settingsRepository.isRegionSurchargeEnabled {
            regionSurcharge = regionChanges * settingsRepository.regionSurchargeAmount
        }
        
        return FareBreakdown(
            baseFare: baseFare,
            distanceFare: distanceFare,
            timeFare: timeFare,
            regionSurcharge: regionSurcharge,
            nightSurcharge: nightSurcharge
        )
    }
    
    /// 야간 시간대 확인
    func isNightTime() -> Bool {
        let settings = settingsRepository.currentRegionFare
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startTime = formatter.date(from: settings.nightStartTime),
              let endTime = formatter.date(from: settings.nightEndTime) else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)
        
        // 야간이 자정을 넘는 경우 (예: 22:00 ~ 04:00)
        if startHour > endHour {
            return currentHour >= startHour || currentHour < endHour
        } else {
            return currentHour >= startHour && currentHour < endHour
        }
    }
}
```

### 4.3 LocationService
```swift
// Domain/Services/LocationService.swift

import Foundation
import CoreLocation
import Combine

protocol LocationServiceProtocol {
    var locationPublisher: AnyPublisher<CLLocation, Never> { get }
    var totalDistance: Double { get }
    var lowSpeedDuration: TimeInterval { get }
    
    func startTracking()
    func stopTracking()
}

final class LocationService: NSObject, LocationServiceProtocol {
    
    // MARK: - Publishers
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    var locationPublisher: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Properties
    private(set) var totalDistance: Double = 0              // meters
    private(set) var lowSpeedDuration: TimeInterval = 0     // seconds
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastUpdateTime: Date?
    
    private let lowSpeedThreshold: Double = 15.0 / 3.6      // 15 km/h in m/s
    
    // MARK: - Init
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Public Methods
    func startTracking() {
        totalDistance = 0
        lowSpeedDuration = 0
        lastLocation = nil
        lastUpdateTime = nil
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 정확도 필터링
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else {
            return
        }
        
        // 거리 계산
        if let lastLocation = lastLocation {
            let delta = location.distance(from: lastLocation)
            
            // 비정상적인 점프 필터링
            if delta < 100 {
                totalDistance += delta
            }
        }
        
        // 저속 시간 계산
        if let lastTime = lastUpdateTime {
            let timeDelta = location.timestamp.timeIntervalSince(lastTime)
            
            if location.speed >= 0 && location.speed < lowSpeedThreshold {
                lowSpeedDuration += timeDelta
            }
        }
        
        lastLocation = location
        lastUpdateTime = location.timestamp
        
        locationSubject.send(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
```

### 4.4 RegionDetector
```swift
// Domain/Services/RegionDetector.swift

import Foundation
import CoreLocation
import MapKit

final class RegionDetector {
    
    // MARK: - Properties
    private(set) var currentRegion: String?
    private(set) var regionChangeCount: Int = 0
    
    private let geocoder = CLGeocoder()
    private var isGeocoding = false
    private var lastGeocodingTime: Date?
    private let geocodingInterval: TimeInterval = 10
    
    // MARK: - Public Methods
    func detect(location: CLLocation, completion: @escaping (String?) -> Void) {
        if let lastTime = lastGeocodingTime,
           Date().timeIntervalSince(lastTime) < geocodingInterval {
            completion(nil)
            return
        }
        
        guard !isGeocoding else {
            completion(nil)
            return
        }
        
        isGeocoding = true
        lastGeocodingTime = Date()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            defer { self?.isGeocoding = false }
            
            guard let placemark = placemarks?.first, error == nil else {
                completion(nil)
                return
            }
            
            let region = [
                placemark.administrativeArea,
                placemark.locality ?? placemark.subAdministrativeArea
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            
            if !region.isEmpty && region != self?.currentRegion {
                if self?.currentRegion != nil {
                    self?.regionChangeCount += 1
                }
                self?.currentRegion = region
                completion(region)
            } else {
                completion(nil)
            }
        }
    }
    
    func reset() {
        currentRegion = nil
        regionChangeCount = 0
        lastGeocodingTime = nil
    }
}
```

---

## 5. 데이터 모델 상세 (Data Models)

### 5.1 Core Entities
```swift
// Domain/Entities/Trip.swift
struct Trip: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let totalFare: Int
    let distance: Double
    let duration: TimeInterval
    let startRegion: String
    let endRegion: String
    let regionChanges: Int
    let isNightTrip: Bool
    let fareBreakdown: FareBreakdown
}

// Domain/Entities/RegionFare.swift
struct RegionFare: Identifiable, Codable {
    let id: UUID
    var code: String
    var name: String
    var baseFare: Int
    var baseDistance: Int
    var distanceFare: Int
    var distanceUnit: Int
    var timeFare: Int
    var timeUnit: Int
    var nightSurchargeRate: Double
    var nightStartTime: String
    var nightEndTime: String
}

// Domain/Entities/FareBreakdown.swift
struct FareBreakdown: Codable {
    let baseFare: Int
    let distanceFare: Int
    let timeFare: Int
    let regionSurcharge: Int
    let nightSurcharge: Int
    
    var totalFare: Int {
        baseFare + distanceFare + timeFare + regionSurcharge + nightSurcharge
    }
}
```

---

## 6. 데이터 흐름 (Data Flow)

```
┌─────────────────────────────────────────────────────────────────┐
│                        User taps "Start"                        │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  MeterViewModel.startMeter()                                    │
│    ├── state = .running                                         │
│    ├── locationService.startTracking()                          │
│    └── soundManager.play(.meterStart)                           │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  LocationService → locationPublisher.send()                     │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  MeterViewModel.handleLocationUpdate()                          │
│    ├── Update distance, speed                                   │
│    ├── updateHorseAnimation()                                   │
│    ├── fareCalculator.calculate()                               │
│    └── regionDetector.detect()                                  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  SwiftUI View Updates (@Observable)                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 보안 및 성능 (Security & Performance)

### 7.1 보안
- 위치 데이터 로컬 저장만 (서버 전송 없음)
- 권한 요청 문구 명시 (Info.plist)

### 7.2 성능 최적화
- GPS: `distanceFilter: 10m`
- Geocoding: 10초 쓰로틀링
- 애니메이션: 60fps
- 메모리: 150MB 이하

---

## 8. 테스트 전략 (Testing Strategy)

| 레벨 | 대상 | 도구 |
|-----|------|-----|
| Unit | FareCalculator, LocationService | XCTest |
| Integration | 전체 플로우 | XCTest |
| UI | 화면 전환, 버튼 동작 | XCUITest |

---

## 문서 변경 이력

| 버전 | 날짜 | 작성자 | 변경 내용 |
|-----|------|-------|----------|
| 1.0.0 | 2025-01-15 | Architect Agent | 초안 작성 |

---

> **다음 단계**: Epic별 User Story 작성 및 개발 시작
