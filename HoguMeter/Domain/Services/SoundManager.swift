//
//  SoundManager.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import AudioToolbox

enum SoundEffect {
    case meterStart
    case meterStop
    case meterTick
    case horseNeigh
    case horseExcited
    case regionChange
    case nightMode

    // iOS 시스템 사운드 ID 매핑
    var systemSoundID: SystemSoundID {
        switch self {
        case .meterStart:
            return 1057 // Tock.caf - 시작음
        case .meterStop:
            return 1114 // 3rdParty_DirectionUp.caf - 정지음
        case .meterTick:
            return 1103 // Timer.caf - 틱 소리
        case .horseNeigh:
            return 1104 // Tink.caf - 말 울음소리 대용
        case .horseExcited:
            return 1309 // begin_record.caf - 흥분한 소리
        case .regionChange:
            return 1315 // connect_power.caf - 지역 변경
        case .nightMode:
            return 1256 // middle_9_Haptic.caf - 야간 모드
        }
    }
}

final class SoundManager {

    // MARK: - Properties
    private var isSoundEnabled: Bool = true

    // MARK: - Public Methods
    func play(_ sound: SoundEffect) {
        guard isSoundEnabled else { return }

        // iOS 시스템 사운드 재생
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }

    func setEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
}
