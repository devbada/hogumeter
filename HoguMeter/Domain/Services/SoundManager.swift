//
//  SoundManager.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import AVFoundation

enum SoundEffect: String {
    case meterStart = "meter_start"
    case meterStop = "meter_stop"
    case meterTick = "meter_tick"
    case horseNeigh = "horse_neigh"
    case horseExcited = "horse_excited"
    case regionChange = "region_change"
    case nightMode = "night_mode"
}

final class SoundManager {

    // MARK: - Properties
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var isSoundEnabled: Bool = true

    // MARK: - Init
    init() {
        setupAudioSession()
    }

    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Public Methods
    func play(_ sound: SoundEffect) {
        guard isSoundEnabled else { return }

        if let player = audioPlayers[sound] {
            player.currentTime = 0
            player.play()
        } else {
            loadAndPlay(sound)
        }
    }

    func setEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }

    // MARK: - Private Methods
    private func loadAndPlay(_ sound: SoundEffect) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            print("Sound file not found: \(sound.rawValue)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[sound] = player
            player.play()
        } catch {
            print("Failed to load sound: \(error)")
        }
    }
}
