//
//  DisclaimerViewModel.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import Foundation
import Combine

@MainActor
final class DisclaimerViewModel: ObservableObject {

    @Published var isAgreed: Bool = false

    private let disclaimerManager = DisclaimerManager()

    var isDisclaimerAccepted: Bool {
        disclaimerManager.isDisclaimerAccepted
    }

    func acceptDisclaimer() {
        disclaimerManager.isDisclaimerAccepted = true
    }

    func resetDisclaimer() {
        disclaimerManager.resetDisclaimer()
    }
}
