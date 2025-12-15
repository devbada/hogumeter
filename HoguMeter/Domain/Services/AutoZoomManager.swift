//
//  AutoZoomManager.swift
//  HoguMeter
//
//  Created on 2025-12-15.
//

import Foundation
import MapKit
import Combine

@MainActor
class AutoZoomManager: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var currentZoomLevel: AutoZoomLevel = .stationary
    @Published private(set) var targetSpan: MKCoordinateSpan = AutoZoomLevel.stationary.span
    @Published var isAutoZoomEnabled: Bool = true

    // MARK: - Private Properties
    private var lastManualInteractionTime: Date?
    private let manualOverrideDuration: TimeInterval = 5.0  // 수동 조작 후 5초간 자동 줌 비활성화

    // 급격한 변화 방지를 위한 히스테리시스 (km/h)
    private let hysteresis: Double = 3.0

    // MARK: - Public Methods

    /// 속도에 따른 줌 레벨 업데이트
    func updateZoom(for speed: Double) {
        guard isAutoZoomEnabled else { return }
        guard !isManualOverrideActive else { return }

        let newLevel = calculateZoomLevel(for: speed)

        if newLevel != currentZoomLevel {
            currentZoomLevel = newLevel
            targetSpan = newLevel.span
        }
    }

    /// 사용자 수동 조작 감지
    func userDidInteract() {
        lastManualInteractionTime = Date()
    }

    /// 수동 조작 오버라이드가 활성화되어 있는지
    var isManualOverrideActive: Bool {
        guard let lastInteraction = lastManualInteractionTime else { return false }
        return Date().timeIntervalSince(lastInteraction) < manualOverrideDuration
    }

    /// 자동 줌 토글
    func toggleAutoZoom() {
        isAutoZoomEnabled.toggle()
    }

    // MARK: - Private Methods

    /// 히스테리시스를 적용한 줌 레벨 계산
    private func calculateZoomLevel(for speed: Double) -> AutoZoomLevel {
        let newLevel = AutoZoomLevel.from(speed: speed)

        // 히스테리시스: 경계 근처에서 잦은 변경 방지
        if newLevel != currentZoomLevel {
            let currentRange = currentZoomLevel.speedRange
            let threshold = hysteresis

            // 현재 레벨의 범위 안에서 threshold 이내면 유지
            if speed >= currentRange.lowerBound - threshold &&
               speed <= currentRange.upperBound + threshold {
                return currentZoomLevel
            }
        }

        return newLevel
    }
}
