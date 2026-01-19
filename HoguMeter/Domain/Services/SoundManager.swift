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

    // MARK: - Dependencies
    private let settingsRepository: SettingsRepositoryProtocol

    // MARK: - Init
    init(settingsRepository: SettingsRepositoryProtocol = SettingsRepository()) {
        self.settingsRepository = settingsRepository
    }

    // MARK: - Public Methods
    func play(_ sound: SoundEffect) {
        // 설정에서 직접 읽어서 확인 (항상 최신 상태 반영)
        guard settingsRepository.isSoundEnabled else { return }

        // iOS 시스템 사운드 재생
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }

    /// Legacy method for backwards compatibility (deprecated)
    /// 설정은 SettingsRepository에서 직접 읽으므로 이 메서드는 더 이상 필요 없음
    @available(*, deprecated, message: "Sound state is now read directly from SettingsRepository")
    func setEnabled(_ enabled: Bool) {
        // No-op: 설정은 SettingsRepository에서 관리
    }
}
