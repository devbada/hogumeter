//
//  CoachMarkTarget.swift
//  HoguMeter
//
//  Created for Onboarding Coach Mark System.
//

import SwiftUI

/// Preference key for collecting coach mark target frames
struct CoachMarkFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

/// View modifier that marks a view as a coach mark target
struct CoachMarkTargetModifier: ViewModifier {
    let id: String

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: CoachMarkFramePreferenceKey.self,
                            value: [id: geo.frame(in: .global)]
                        )
                }
            )
    }
}

extension View {
    /// Marks this view as a target for coach marks with the given identifier
    func coachMarkTarget(id: String) -> some View {
        modifier(CoachMarkTargetModifier(id: id))
    }
}
