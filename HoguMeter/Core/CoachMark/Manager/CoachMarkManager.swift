//
//  CoachMarkManager.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import SwiftUI

/// Manages the state and flow of coach marks across all screens
@MainActor
final class CoachMarkManager: ObservableObject {
    static let shared = CoachMarkManager()

    // MARK: - Published Properties

    @Published var isShowingCoachMark: Bool = false
    @Published var currentScreenId: String?
    @Published var currentMarkIndex: Int = 0

    // MARK: - Persisted Completion Flags (per screen)

    @AppStorage("hasCompletedOnboarding_main") var completedMain = false
    @AppStorage("hasCompletedOnboarding_map") var completedMap = false
    @AppStorage("hasCompletedOnboarding_history") var completedHistory = false
    @AppStorage("hasCompletedOnboarding_settings") var completedSettings = false
    @AppStorage("onboardingVersion") var onboardingVersion = 1

    // MARK: - Private Properties

    private var coachMarkScreens: [String: CoachMarkScreen] = [:]

    // MARK: - Init

    private init() {
        registerAllScreens()
    }

    // MARK: - Public Methods

    /// Check if coach marks should be shown for a specific screen
    func shouldShowCoachMarks(for screenId: String) -> Bool {
        switch screenId {
        case "main":
            return !completedMain
        case "map":
            return !completedMap
        case "history":
            return !completedHistory
        case "settings":
            return !completedSettings
        default:
            return false
        }
    }

    /// Start coach marks for a specific screen
    func startCoachMarks(for screenId: String) {
        guard let screen = coachMarkScreens[screenId],
              !screen.coachMarks.isEmpty else { return }

        currentScreenId = screenId
        currentMarkIndex = 0
        isShowingCoachMark = true
    }

    /// Advance to the next coach mark
    func nextCoachMark() {
        guard let screenId = currentScreenId,
              let screen = coachMarkScreens[screenId] else { return }

        let sortedMarks = screen.sortedCoachMarks

        if currentMarkIndex < sortedMarks.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMarkIndex += 1
            }
        } else {
            completeCurrentScreen()
        }
    }

    /// Skip all remaining coach marks for the current screen
    func skipCoachMarks() {
        completeCurrentScreen()
    }

    /// Complete the current screen's coach marks
    func completeCurrentScreen() {
        guard let screenId = currentScreenId else { return }

        markScreenCompleted(screenId)

        withAnimation(.easeOut(duration: 0.2)) {
            isShowingCoachMark = false
        }

        currentScreenId = nil
        currentMarkIndex = 0
    }

    /// Reset all coach marks (for "가이드 다시 보기" in Settings)
    func resetAllCoachMarks() {
        completedMain = false
        completedMap = false
        completedHistory = false
        completedSettings = false
    }

    /// Get the current coach mark based on screen and index
    var currentCoachMark: CoachMark? {
        guard let screenId = currentScreenId,
              let screen = coachMarkScreens[screenId] else { return nil }

        let sortedMarks = screen.sortedCoachMarks
        guard currentMarkIndex < sortedMarks.count else { return nil }

        return sortedMarks[currentMarkIndex]
    }

    /// Get the total number of coach marks for the current screen
    var currentScreenCoachMarkCount: Int {
        guard let screenId = currentScreenId,
              let screen = coachMarkScreens[screenId] else { return 0 }
        return screen.coachMarks.count
    }

    /// Register a coach mark screen
    func registerScreen(_ screen: CoachMarkScreen) {
        coachMarkScreens[screen.id] = screen
    }

    // MARK: - Private Methods

    private func markScreenCompleted(_ screenId: String) {
        switch screenId {
        case "main":
            completedMain = true
        case "map":
            completedMap = true
        case "history":
            completedHistory = true
        case "settings":
            completedSettings = true
        default:
            break
        }
    }

    private func registerAllScreens() {
        registerScreen(CoachMarkData.mainScreen)
        registerScreen(CoachMarkData.mapScreen)
        registerScreen(CoachMarkData.historyScreen)
        registerScreen(CoachMarkData.settingsScreen)
    }
}
