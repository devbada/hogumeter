//
//  CoachMarkScreen.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import Foundation

/// Represents a screen with its associated coach marks
struct CoachMarkScreen: Identifiable {
    let id: String                  // Screen identifier
    let screenName: String          // Display name
    let coachMarks: [CoachMark]     // Coach marks for this screen

    /// Returns coach marks sorted by their order
    var sortedCoachMarks: [CoachMark] {
        coachMarks.sorted { $0.order < $1.order }
    }
}
