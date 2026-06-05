//
//  AmbientLightObserver.swift
//  HoguMeter
//
//  Created on 2026-05-28.
//
//  UIScreen.brightness 값을 ambient light의 프록시 신호로 사용해 라이트/다크 모드를 추정한다.
//  hysteresis(0.30 / 0.45) 임계값으로 깜빡임을 방지한다.
//
//  공식 ambient light sensor API가 없는 iOS 환경에서 자동 밝기 기능에 의존한다는 한계가 있다.
//  자세한 명세는 SPEC_AMBIENT_DARK_MODE.md 참고.
//

import SwiftUI
import UIKit
import Observation

@MainActor
@Observable
final class AmbientLightObserver {

    // MARK: - Public State

    /// 가장 최근에 읽은 화면 밝기 (0.0 ~ 1.0)
    private(set) var brightness: Double

    /// 현재 brightness와 hysteresis를 반영한 추정 ColorScheme
    private(set) var inferredScheme: ColorScheme

    // MARK: - Hysteresis Thresholds

    /// light → dark 로 전환되는 임계값
    private let lightToDarkThreshold: Double

    /// dark → light 로 전환되는 임계값
    private let darkToLightThreshold: Double

    // MARK: - Internal

    private var observerToken: NSObjectProtocol?
    private let notificationCenter: NotificationCenter

    // MARK: - Init

    /// - Parameters:
    ///   - initialBrightness: 초기 측정값 주입. nil이면 현재 윈도우 씬에서 조회.
    ///   - lightToDarkThreshold: light → dark 전환 임계값 (기본 0.30)
    ///   - darkToLightThreshold: dark → light 전환 임계값 (기본 0.45)
    ///   - notificationCenter: 테스트 주입용
    init(
        initialBrightness: Double? = nil,
        lightToDarkThreshold: Double = 0.30,
        darkToLightThreshold: Double = 0.45,
        notificationCenter: NotificationCenter = .default
    ) {
        let initial = initialBrightness ?? AmbientLightObserver.currentSceneBrightness()
        self.brightness = initial
        self.lightToDarkThreshold = lightToDarkThreshold
        self.darkToLightThreshold = darkToLightThreshold
        self.notificationCenter = notificationCenter
        // 초기 평가는 hysteresis 없이 단순 임계값 기반
        self.inferredScheme = initial < lightToDarkThreshold ? .dark : .light
    }

    // deinit은 @MainActor 격리 프로퍼티 접근 이슈를 피하기 위해 두지 않는다.
    // AppState가 앱 라이프타임 동안 살아있고, 라이프사이클은 startObserving/stopObserving이
    // HoguMeterApp의 scenePhase 핸들러를 통해 명시적으로 관리한다.

    // MARK: - Lifecycle

    /// 화면 밝기 변화 알림 구독을 시작한다. scene이 active일 때 호출.
    func startObserving() {
        // 이미 구독 중이면 무시
        guard observerToken == nil else { return }

        // 즉시 한 번 재평가 (background에 있는 동안 밝기가 바뀌었을 수 있음)
        updateBrightness(Self.currentSceneBrightness())

        observerToken = notificationCenter.addObserver(
            forName: UIScreen.brightnessDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // notification queue가 .main이지만 명시적으로 MainActor에서 처리
            Task { @MainActor in
                self?.updateBrightness(Self.currentSceneBrightness())
            }
        }
    }

    /// 알림 구독을 해제한다. scene이 background로 진입할 때 호출.
    func stopObserving() {
        guard let token = observerToken else { return }
        notificationCenter.removeObserver(token)
        observerToken = nil
    }

    // MARK: - Testability Hooks

    /// 외부에서 brightness 입력을 주입해 hysteresis 로직만 검증할 수 있게 한다.
    /// 프로덕션 코드에서는 호출하지 않는다.
    func injectBrightness(_ value: Double) {
        updateBrightness(value)
    }

    // MARK: - Core Logic

    /// ColorScheme 전환 시 화면을 부드럽게 페이드 in/out 시키기 위한 애니메이션
    private static let schemeTransition: Animation = .easeInOut(duration: 0.45)

    private func updateBrightness(_ value: Double) {
        brightness = value
        let next = evaluateScheme(for: value, current: inferredScheme)
        if next != inferredScheme {
            // @Observable + withAnimation 조합: 이 프로퍼티에 의존하는 모든 view body가
            // 동일 트랜잭션 안에서 갱신되어 색 변화가 동시·부드럽게 전이된다.
            withAnimation(Self.schemeTransition) {
                inferredScheme = next
            }
        }
    }

    /// hysteresis 로직: 임계값 통과한 경우에만 모드 전환
    private func evaluateScheme(for brightness: Double, current: ColorScheme) -> ColorScheme {
        switch current {
        case .light:
            return brightness < lightToDarkThreshold ? .dark : .light
        case .dark:
            return brightness > darkToLightThreshold ? .light : .dark
        @unknown default:
            return current
        }
    }

    // MARK: - Multi-Scene Brightness Lookup

    /// iOS 17+ multi-scene 환경에서 안전하게 brightness 값을 조회한다.
    /// UIScreen.main은 multi-scene 환경에서 비권장이므로 connectedScenes에서 윈도우 씬을 찾는다.
    /// class가 @MainActor라 호출도 @MainActor에서만 일어남 → static도 @MainActor로 통일.
    @MainActor
    static func currentSceneBrightness() -> Double {
        guard let scene = activeWindowScene() else { return 0.5 }
        return Double(scene.screen.brightness)
    }

    @MainActor
    private static func activeWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first
    }
}
