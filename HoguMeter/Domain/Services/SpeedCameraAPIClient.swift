//
//  SpeedCameraAPIClient.swift
//  HoguMeter
//
//  Created on 2026-06-23.
//

import CoreLocation
import Foundation

final class SpeedCameraAPIClient {
    private enum Config {
        static let endpoint = "https://api.data.go.kr/openapi/tn_pubr_public_unmanned_traffic_camera_api"
        static let infoKey = "PublicSpeedCameraServiceKey"
        static let pageSize = 1_000
        static let maxPages = 50
    }

    private let session: URLSession
    private var cachedCameras: [SpeedCamera]?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCameras() async -> [SpeedCamera] {
        if let cachedCameras = cachedCameras {
            return cachedCameras
        }

        guard let serviceKey = Bundle.main.object(forInfoDictionaryKey: Config.infoKey) as? String,
              !serviceKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !serviceKey.hasPrefix("$(") else {
            Logger.gps.warning("[SpeedCamera] PublicSpeedCameraServiceKey 미설정")
            return []
        }

        var allCameras: [SpeedCamera] = []
        var totalCount = 0

        for pageNo in 1...Config.maxPages {
            do {
                let page = try await fetchPage(serviceKey: serviceKey, pageNo: pageNo)
                if pageNo == 1 {
                    totalCount = page.totalCount
                }
                allCameras.append(contentsOf: page.cameras)

                if pageNo * Config.pageSize >= totalCount || page.cameras.isEmpty {
                    break
                }
            } catch {
                Logger.gps.error("[SpeedCamera] API 조회 실패: \(error.localizedDescription)")
                break
            }
        }

        cachedCameras = allCameras
        return allCameras
    }

    private func fetchPage(serviceKey: String, pageNo: Int) async throws -> SpeedCameraPage {
        guard var components = URLComponents(string: Config.endpoint) else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "serviceKey", value: serviceKey),
            URLQueryItem(name: "pageNo", value: String(pageNo)),
            URLQueryItem(name: "numOfRows", value: String(Config.pageSize)),
            URLQueryItem(name: "type", value: "json")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 HoguMeter/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let apiResponse = try JSONDecoder().decode(SpeedCameraAPIResponse.self, from: data)
        if let header = apiResponse.response.header, header.resultCode != "00" {
            throw SpeedCameraAPIError.apiError(code: header.resultCode, message: header.resultMsg)
        }

        return SpeedCameraPage(
            totalCount: apiResponse.response.body.totalCount,
            cameras: apiResponse.response.body.normalizedItems.compactMap { $0.speedCamera }
        )
    }
}

private enum SpeedCameraAPIError: LocalizedError {
    case apiError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .apiError(let code, let message):
            return "공공데이터 API 오류 \(code): \(message)"
        }
    }
}

private struct SpeedCameraPage {
    let totalCount: Int
    let cameras: [SpeedCamera]
}

private struct SpeedCameraAPIResponse: Decodable {
    let response: SpeedCameraResponse
}

private struct SpeedCameraResponse: Decodable {
    let header: SpeedCameraHeader?
    let body: SpeedCameraBody
}

private struct SpeedCameraHeader: Decodable {
    let resultCode: String
    let resultMsg: String
}

private struct SpeedCameraBody: Decodable {
    let totalCount: Int
    let items: SpeedCameraItems

    var normalizedItems: [SpeedCameraItem] {
        items.values
    }
}

private enum SpeedCameraItems: Decodable {
    case list([SpeedCameraItem])
    case wrapper(SpeedCameraItemWrapper)

    var values: [SpeedCameraItem] {
        switch self {
        case .list(let items):
            return items
        case .wrapper(let wrapper):
            return wrapper.item
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let values = try? container.decode([SpeedCameraItem].self) {
            self = .list(values)
            return
        }

        self = .wrapper(try container.decode(SpeedCameraItemWrapper.self))
    }
}

private struct SpeedCameraItemWrapper: Decodable {
    let item: [SpeedCameraItem]
}

private struct SpeedCameraItem: Decodable {
    let mnlssRegltCameraManageNo: String?
    let itlpc: String?
    let regltSe: String?
    let lmttVe: String?
    let ctprvnNm: String?
    let signguNm: String?
    let latitude: String?
    let longitude: String?

    var speedCamera: SpeedCamera? {
        guard let id = trimmed(mnlssRegltCameraManageNo),
              let latitude = Double(trimmed(latitude) ?? ""),
              let longitude = Double(trimmed(longitude) ?? ""),
              latitude >= 32, latitude <= 40,
              longitude >= 123, longitude <= 133 else {
            return nil
        }

        return SpeedCamera(
            id: id,
            name: trimmed(itlpc) ?? "무인교통단속카메라",
            cameraType: trimmed(regltSe) ?? "단속",
            limitKmh: Int(trimmed(lmttVe) ?? ""),
            sido: trimmed(ctprvnNm),
            sigungu: trimmed(signguNm),
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }
}
