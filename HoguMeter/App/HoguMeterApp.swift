//
//  HoguMeterApp.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI
import UserNotifications

@main
struct HoguMeterApp: App {

    // MARK: - Dependencies
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var disclaimerViewModel = DisclaimerViewModel()
    @State private var showLoadingAnimation = true
    @State private var showDisclaimer = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // 앱 시작 시 알림 카테고리 설정
        IdleDetectionService.setupNotificationCategories()

        // 앱 시작 시 화면 항상 켜짐 비활성화
        UIApplication.shared.isIdleTimerDisabled = false
    }

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
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            NotificationCenter.default.post(name: .appBecameActive, object: nil)
        case .background:
            NotificationCenter.default.post(name: .appEnteredBackground, object: nil)
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - AppDelegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // 앱이 포그라운드에 있을 때 알림 수신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 포그라운드에서는 배너와 소리로 알림 표시
        completionHandler([.banner, .sound])
    }

    // 알림 액션 응답 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case IdleDetectionConfig.continueActionIdentifier:
            // "계속" 버튼 탭
            NotificationCenter.default.post(name: .idleDetectionContinue, object: nil)

        case IdleDetectionConfig.stopActionIdentifier:
            // "종료" 버튼 탭
            NotificationCenter.default.post(name: .idleDetectionStop, object: nil)

        case UNNotificationDefaultActionIdentifier:
            // 알림 본문 탭 (앱 열기) - 인앱 알림으로 처리
            NotificationCenter.default.post(name: .idleDetectionContinue, object: nil)

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let idleDetectionContinue = Notification.Name("idleDetectionContinue")
    static let idleDetectionStop = Notification.Name("idleDetectionStop")
    static let appBecameActive = Notification.Name("appBecameActive")
    static let appEnteredBackground = Notification.Name("appEnteredBackground")
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
        self.locationService = LocationService(settingsRepository: settingsRepository)
        self.regionDetector = RegionDetector()
        self.soundManager = SoundManager()
        self.fareCalculator = FareCalculator(settingsRepository: settingsRepository)
    }
}
