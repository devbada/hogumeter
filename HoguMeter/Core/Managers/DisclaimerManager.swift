//
//  DisclaimerManager.swift
//  HoguMeter
//
//  Created on 2025-12-11.
//

import Foundation

/// 면책 동의 상태 관리
final class DisclaimerManager {

    private let userDefaults = UserDefaults.standard
    private let disclaimerAcceptedKey = "disclaimer_accepted"
    private let disclaimerAcceptedDateKey = "disclaimer_accepted_date"

    /// 면책 동의 여부
    var isDisclaimerAccepted: Bool {
        get { userDefaults.bool(forKey: disclaimerAcceptedKey) }
        set {
            userDefaults.set(newValue, forKey: disclaimerAcceptedKey)
            if newValue {
                userDefaults.set(Date(), forKey: disclaimerAcceptedDateKey)
            }
        }
    }

    /// 면책 동의 일시
    var disclaimerAcceptedDate: Date? {
        userDefaults.object(forKey: disclaimerAcceptedDateKey) as? Date
    }

    /// 면책 동의 초기화 (다시 보기)
    func resetDisclaimer() {
        userDefaults.removeObject(forKey: disclaimerAcceptedKey)
        userDefaults.removeObject(forKey: disclaimerAcceptedDateKey)
    }
}
