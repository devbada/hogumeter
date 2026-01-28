//
//  CoachMark.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import Foundation

/// Position for the tooltip relative to the target element
enum TooltipPosition {
    case top
    case bottom
    case left
    case right
    case auto  // Automatically determine based on screen position
}

/// Represents a single coach mark (tooltip) for user onboarding
struct CoachMark: Identifiable, Equatable {
    let id: String
    let targetView: String          // View identifier to highlight
    let title: String               // Short title
    let description: String         // Explanation text
    let position: TooltipPosition   // Where to show tooltip
    let order: Int                  // Display order within screen

    static func == (lhs: CoachMark, rhs: CoachMark) -> Bool {
        lhs.id == rhs.id
    }
}
