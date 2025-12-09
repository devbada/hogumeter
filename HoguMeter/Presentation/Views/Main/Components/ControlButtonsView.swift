//
//  ControlButtonsView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct ControlButtonsView: View {
    let state: MeterState
    let onStart: () -> Void
    let onStop: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            if state == .idle || state == .stopped {
                Button(action: onStart) {
                    Label("시작", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }

            if state == .running {
                Button(action: onStop) {
                    Label("정지", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }

            if state == .stopped {
                Button(action: onReset) {
                    Label("리셋", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        ControlButtonsView(state: .idle, onStart: {}, onStop: {}, onReset: {})
        ControlButtonsView(state: .running, onStart: {}, onStop: {}, onReset: {})
        ControlButtonsView(state: .stopped, onStart: {}, onStop: {}, onReset: {})
    }
}
