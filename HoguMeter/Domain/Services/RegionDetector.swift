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

    /// 현재 주소 정보 (상세)
    private(set) var currentAddressInfo: AddressInfo?

    /// 현재 지역 (포맷팅된 문자열)
    private(set) var currentRegion: String?

    /// 시작 지역 (포맷팅된 문자열)
    private(set) var startRegion: String?

    /// 시작 주소 정보 (상세)
    private(set) var startAddressInfo: AddressInfo?

    /// 지역 변경 횟수
    private(set) var regionChangeCount: Int = 0

    private let geocoder = CLGeocoder()
    private var isGeocoding = false
    private var lastGeocodingTime: Date?
    private let geocodingInterval: TimeInterval = 10

    // MARK: - Public Methods

    /// 위치 기반 주소 감지
    /// - Parameters:
    ///   - location: CLLocation 객체
    ///   - completion: 새로운 주소 정보가 감지되면 호출 (변경 없으면 nil)
    func detect(location: CLLocation, completion: @escaping (AddressInfo?) -> Void) {
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

            // AddressInfo 생성
            let addressInfo = AddressInfo(placemark: placemark)

            // 포맷팅된 지역 문자열
            let formattedRegion = LocationFormatter.format(addressInfo)

            // 지역이 변경되었는지 확인
            if !formattedRegion.isEmpty && formattedRegion != self?.currentRegion {
                // 시작 지역 저장 (첫 번째 지역)
                if self?.startRegion == nil {
                    self?.startRegion = formattedRegion
                    self?.startAddressInfo = addressInfo
                }

                if self?.currentRegion != nil {
                    self?.regionChangeCount += 1
                }

                self?.currentRegion = formattedRegion
                self?.currentAddressInfo = addressInfo
                completion(addressInfo)
            } else {
                completion(nil)
            }
        }
    }

    /// 상태 초기화
    func reset() {
        currentRegion = nil
        currentAddressInfo = nil
        startRegion = nil
        startAddressInfo = nil
        regionChangeCount = 0
        lastGeocodingTime = nil
    }
}
