//
//  TripInfoView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct TripInfoView: View {
    let distance: Double
    let duration: TimeInterval
    let speed: Double
    let region: String

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                InfoCard(title: "거리", value: formattedDistance, icon: "road.lanes")
                InfoCard(title: "시간", value: formattedDuration, icon: "clock")
            }

            HStack(spacing: 20) {
                InfoCard(title: "속도", value: formattedSpeed, icon: "speedometer")
                InfoCard(title: "지역", value: region.isEmpty ? "-" : region, icon: "location")
            }
        }
    }

    private var formattedDistance: String {
        String(format: "%.1f km", distance)
    }

    private var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var formattedSpeed: String {
        String(format: "%.0f km/h", speed)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    TripInfoView(
        distance: 12.5,
        duration: 1830,
        speed: 45.0,
        region: "서울 강남구"
    )
    .padding()
}
