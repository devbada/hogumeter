//
//  Trip.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

struct Trip: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let totalFare: Int
    let distance: Double        // km
    let duration: TimeInterval  // seconds
    let startRegion: String
    let endRegion: String
    let regionChanges: Int
    let isNightTrip: Bool
    let fareBreakdown: FareBreakdown
}
