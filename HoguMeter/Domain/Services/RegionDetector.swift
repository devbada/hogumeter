//
//  RegionDetector.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import Foundation
import CoreLocation
import MapKit

final class RegionDetector {

    // MARK: - Properties
    private(set) var currentRegion: String?
    private(set) var regionChangeCount: Int = 0

    private let geocoder = CLGeocoder()
    private var isGeocoding = false
    private var lastGeocodingTime: Date?
    private let geocodingInterval: TimeInterval = 10

    // MARK: - Public Methods
    func detect(location: CLLocation, completion: @escaping (String?) -> Void) {
        if let lastTime = lastGeocodingTime,
           Date().timeIntervalSince(lastTime) < geocodingInterval {
            completion(nil)
            return
        }

        guard !isGeocoding else {
            completion(nil)
            return
        }

        isGeocoding = true
        lastGeocodingTime = Date()

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            defer { self?.isGeocoding = false }

            guard let placemark = placemarks?.first, error == nil else {
                completion(nil)
                return
            }

            // 상세 주소 구성: "서울특별시 영등포구" 형식
            let adminArea = placemark.administrativeArea ?? ""
            let subLocality = placemark.subLocality ?? ""
            let locality = placemark.locality ?? ""

            var components: [String] = []

            // 시/도 추가
            if !adminArea.isEmpty {
                components.append(adminArea)
            }

            // 구/군 단위 추가 (subLocality 우선, 없으면 locality)
            if !subLocality.isEmpty {
                components.append(subLocality)
            } else if !locality.isEmpty && locality != adminArea {
                components.append(locality)
            }

            let region = components.joined(separator: " ")

            if !region.isEmpty && region != self?.currentRegion {
                if self?.currentRegion != nil {
                    self?.regionChangeCount += 1
                }
                self?.currentRegion = region
                completion(region)
            } else {
                completion(nil)
            }
        }
    }

    func reset() {
        currentRegion = nil
        regionChangeCount = 0
        lastGeocodingTime = nil
    }
}
