//
//  HoguMeterTests.swift
//  HoguMeterTests
//
//  Created by 조미남 on 12/12/25.
//

import Testing
@testable import HoguMeter

struct HoguMeterTests {

    @Test func meterTimerGenerationGate_start세대만실행을허용한다() async throws {
        var gate = MeterTimerGenerationGate()
        let generation = gate.start()

        #expect(gate.accepts(capturedGeneration: generation, isRunning: true, hasTripStartTime: true))
        #expect(!gate.accepts(capturedGeneration: generation, isRunning: false, hasTripStartTime: true))
        #expect(!gate.accepts(capturedGeneration: generation, isRunning: true, hasTripStartTime: false))
    }

    @Test func meterTimerGenerationGate_stop과재시작은구callback을차단한다() async throws {
        var gate = MeterTimerGenerationGate()
        let staleGeneration = gate.start()
        gate.stop()
        let activeGeneration = gate.start()

        #expect(!gate.accepts(capturedGeneration: staleGeneration, isRunning: true, hasTripStartTime: true))
        #expect(gate.accepts(capturedGeneration: activeGeneration, isRunning: true, hasTripStartTime: true))
    }
}
