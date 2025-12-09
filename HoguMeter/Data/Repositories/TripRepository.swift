//
//  TripRepository.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class TripRepository {

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let tripsKey = "saved_trips"
    private let maxTripsCount = 100

    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods
    func save(_ trip: Trip) {
        var trips = getAll()
        trips.insert(trip, at: 0)

        // 최대 개수 초과 시 오래된 것 삭제
        if trips.count > maxTripsCount {
            trips = Array(trips.prefix(maxTripsCount))
        }

        saveToDisk(trips)
    }

    func getAll() -> [Trip] {
        guard let data = userDefaults.data(forKey: tripsKey) else {
            return []
        }

        do {
            let trips = try JSONDecoder().decode([Trip].self, from: data)
            return trips
        } catch {
            print("Failed to decode trips: \(error)")
            return []
        }
    }

    func delete(_ trip: Trip) {
        var trips = getAll()
        trips.removeAll { $0.id == trip.id }
        saveToDisk(trips)
    }

    func deleteAll() {
        userDefaults.removeObject(forKey: tripsKey)
    }

    // MARK: - Private Methods
    private func saveToDisk(_ trips: [Trip]) {
        do {
            let data = try JSONEncoder().encode(trips)
            userDefaults.set(data, forKey: tripsKey)
        } catch {
            print("Failed to encode trips: \(error)")
        }
    }
}
