//
//  FareDisplayView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct FareDisplayView: View {
    let fare: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("요금")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(formattedFare)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }

    private var formattedFare: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let fareString = formatter.string(from: NSNumber(value: fare)) ?? "0"
        return "\(fareString)원"
    }
}

#Preview {
    FareDisplayView(fare: 12300)
}
