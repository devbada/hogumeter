//
//  TripRepository.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation

final class TripRepository {

    // MARK: - Properties
    private var trips: [Trip] = []
    private let maxTripsCount = 100

    // MARK: - Public Methods
    func save(_ trip: Trip) {
        trips.insert(trip, at: 0)

        // 최대 개수 초과 시 오래된 것 삭제
        if trips.count > maxTripsCount {
            trips = Array(trips.prefix(maxTripsCount))
        }

        // TODO: Core Data에 저장
    }

    func getAll() -> [Trip] {
        trips
    }

    func delete(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }

        // TODO: Core Data에서 삭제
    }

    func deleteAll() {
        trips.removeAll()

        // TODO: Core Data에서 모두 삭제
    }
}
