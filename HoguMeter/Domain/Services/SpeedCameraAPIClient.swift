//
//  SpeedCameraAPIClient.swift
//  HoguMeter
//
//  Created on 2026-06-23.
//

import CoreLocation
import Foundation

struct SpeedCameraRegionFilter: Hashable {
    let sido: String
    let sigungu: String?

    var cacheKey: String {
        "\(sido)|\(sigungu ?? "")"
    }
}

struct SpeedCameraRegionRetryPolicy {
    static func cooldown(forFailureCount failureCount: Int) -> TimeInterval {
        min(10 * pow(2, Double(min(max(failureCount - 1, 0), 5))), 5 * 60)
    }
}

actor SpeedCameraAPIClient {
    typealias RegionFetchOverride = @Sendable (SpeedCameraRegionFilter) async -> Result<[SpeedCamera], Error>
    private enum Config {
        static let endpoint = "https://api.data.go.kr/openapi/tn_pubr_public_unmanned_traffic_camera_api"
        static let infoKey = "PublicSpeedCameraServiceKey"
        static let pageSize = 1_000
        static let maxPages = 50
    }

    private let session: URLSession
    private let nowProvider: @Sendable () -> Date
    private let regionFetchOverride: RegionFetchOverride?
    private var cachedCameras: [SpeedCamera]?
    private var regionCachedCameras: [String: RegionCacheEntry] = [:]
    private var regionFailures: [String: RegionFailureState] = [:]
    private var inFlightRegionTasks: [String: InFlightRegionRequest] = [:]
    private var nextRegionRequestID = 0

    private struct RegionCacheEntry {
        let cameras: [SpeedCamera]
        let expiresAt: Date
    }

    private struct RegionFailureState {
        let consecutiveFailures: Int
        let retryAfter: Date
    }

    private struct InFlightRegionRequest {
        let requestID: Int
        let task: Task<Result<[SpeedCamera], Error>, Never>
    }

    private enum CachePolicy {
        static let successTTL: TimeInterval = 10 * 60
        static let emptySuccessTTL: TimeInterval = 60
    }

    init(
        session: URLSession = .shared,
        nowProvider: @escaping @Sendable () -> Date = { Date() },
        regionFetchOverride: RegionFetchOverride? = nil
    ) {
        self.session = session
        self.nowProvider = nowProvider
        self.regionFetchOverride = regionFetchOverride
    }

    func fetchCameras() async -> [SpeedCamera] {
        if let cachedCameras = cachedCameras {
            return cachedCameras
        }

        let serviceKey = Bundle.main.object(forInfoDictionaryKey: Config.infoKey) as? String ?? ""
        guard regionFetchOverride != nil || (!serviceKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !serviceKey.hasPrefix("$(")) else {
            Logger.gps.warning("[SpeedCamera] PublicSpeedCameraServiceKey 미설정")
            return []
        }

        var allCameras: [SpeedCamera] = []
        var totalCount = 0
        var completedSuccessfully = true

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
                completedSuccessfully = false
                break
            }
        }

        if completedSuccessfully {
            cachedCameras = allCameras
        }
        return allCameras
    }

    func fetchCameras(regions: [SpeedCameraRegionFilter]) async -> [SpeedCamera] {
        let uniqueRegions = Array(Set(regions)).sorted { $0.cacheKey < $1.cacheKey }
        guard !uniqueRegions.isEmpty else {
            return await fetchCameras()
        }

        let serviceKey = Bundle.main.object(forInfoDictionaryKey: Config.infoKey) as? String ?? ""
        guard regionFetchOverride != nil || (!serviceKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !serviceKey.hasPrefix("$(")) else {
            Logger.gps.warning("[SpeedCamera] PublicSpeedCameraServiceKey 미설정")
            return []
        }

        var allCameras: [SpeedCamera] = []

        for region in uniqueRegions {
            let result = await fetchRegionCameras(serviceKey: serviceKey, region: region, now: nowProvider())
            if case let .success(cameras) = result {
                allCameras.append(contentsOf: cameras)
            }
        }

        return deduplicated(allCameras)
    }

    func hasPendingRetry(regions: [SpeedCameraRegionFilter]) -> Bool {
        regions.contains { regionFailures[$0.cacheKey] != nil }
    }

    private func fetchRegionCameras(
        serviceKey: String,
        region: SpeedCameraRegionFilter,
        now: Date
    ) async -> Result<[SpeedCamera], Error> {
        let key = region.cacheKey
        if let cached = regionCachedCameras[key], cached.expiresAt > now {
            return .success(cached.cameras)
        }
        if let failure = regionFailures[key], failure.retryAfter > now {
            return .failure(SpeedCameraRegionRequestError.cooldown)
        }
        let task: Task<Result<[SpeedCamera], Error>, Never>
        if let existing = inFlightRegionTasks[key] {
            task = existing.task
        } else {
            nextRegionRequestID += 1
            let requestID = nextRegionRequestID
            let created = Task<Result<[SpeedCamera], Error>, Never> { [weak self] in
                guard let self else { return .failure(SpeedCameraRegionRequestError.cancelled) }
                let result: Result<[SpeedCamera], Error>
                if let regionFetchOverride = await self.regionFetchOverride {
                    result = await regionFetchOverride(region)
                } else {
                    result = await self.fetchRegionFromNetwork(serviceKey: serviceKey, region: region)
                }
                await self.completeRegionRequest(key: key, requestID: requestID, result: result, completedAt: self.nowProvider())
                return result
            }
            inFlightRegionTasks[key] = InFlightRegionRequest(requestID: requestID, task: created)
            task = created
        }
        return await task.value
    }

    private func completeRegionRequest(
        key: String,
        requestID: Int,
        result: Result<[SpeedCamera], Error>,
        completedAt: Date
    ) {
        guard inFlightRegionTasks[key]?.requestID == requestID else { return }
        inFlightRegionTasks[key] = nil
        switch result {
        case let .success(cameras):
            let ttl = cameras.isEmpty ? CachePolicy.emptySuccessTTL : CachePolicy.successTTL
            regionCachedCameras[key] = RegionCacheEntry(cameras: cameras, expiresAt: completedAt.addingTimeInterval(ttl))
            regionFailures[key] = nil
        case .failure:
            let failures = (regionFailures[key]?.consecutiveFailures ?? 0) + 1
            let cooldown = SpeedCameraRegionRetryPolicy.cooldown(forFailureCount: failures)
            regionFailures[key] = RegionFailureState(consecutiveFailures: failures, retryAfter: completedAt.addingTimeInterval(cooldown))
        }
    }

    private func fetchRegionFromNetwork(serviceKey: String, region: SpeedCameraRegionFilter) async -> Result<[SpeedCamera], Error> {
        var cameras: [SpeedCamera] = []
        var totalCount = 0

        for pageNo in 1...Config.maxPages {
            do {
                let page = try await fetchPage(serviceKey: serviceKey, pageNo: pageNo, region: region)
                if pageNo == 1 {
                    totalCount = page.totalCount
                }
                cameras.append(contentsOf: page.cameras)

                if pageNo * Config.pageSize >= totalCount || page.cameras.isEmpty {
                    break
                }
            } catch {
                Logger.gps.error("[SpeedCamera] 지역 API 조회 실패: \(error.localizedDescription)")
                return .failure(error)
            }
        }
        return .success(cameras)
    }

    private func fetchPage(
        serviceKey: String,
        pageNo: Int,
        region: SpeedCameraRegionFilter? = nil
    ) async throws -> SpeedCameraPage {
        guard var components = URLComponents(string: Config.endpoint) else {
            throw URLError(.badURL)
        }

        var queryParts = [
            "serviceKey=\(Self.percentEncodedQueryValue(serviceKey))",
            "pageNo=\(pageNo)",
            "numOfRows=\(Config.pageSize)",
            "type=json"
        ]

        if let region {
            queryParts.append("ctprvnNm=\(Self.percentEncodedQueryValue(region.sido))")
            if let sigungu = region.sigungu, !sigungu.isEmpty {
                queryParts.append("signguNm=\(Self.percentEncodedQueryValue(sigungu))")
            }
        }

        components.percentEncodedQuery = queryParts.joined(separator: "&")

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

        return try parsePage(data)
    }

    private func deduplicated(_ cameras: [SpeedCamera]) -> [SpeedCamera] {
        var seen = Set<String>()
        return cameras.filter { camera in
            guard !seen.contains(camera.id) else { return false }
            seen.insert(camera.id)
            return true
        }
    }

    private static func percentEncodedQueryValue(_ value: String) -> String {
        if value.contains("%") {
            return value
        }

        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: ":#[]@!$&'()*+,;=")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }

    private func parsePage(_ data: Data) throws -> SpeedCameraPage {
        let responseText = String(decoding: data, as: UTF8.self)
        let trimmedResponse = responseText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedResponse.hasPrefix("<") {
            return try parseXMLPage(data)
        }

        do {
            let apiResponse = try JSONDecoder().decode(SpeedCameraAPIResponse.self, from: data)
            if let header = apiResponse.response.header, header.resultCode != "00" {
                if header.resultCode == "03" {
                    return SpeedCameraPage(totalCount: 0, cameras: [])
                }
                throw SpeedCameraAPIError.apiError(code: header.resultCode, message: header.resultMsg)
            }

            guard let body = apiResponse.response.body else {
                return SpeedCameraPage(totalCount: 0, cameras: [])
            }

            return SpeedCameraPage(
                totalCount: body.totalCount,
                cameras: body.normalizedItems.compactMap { $0.speedCamera }
            )
        } catch let error as SpeedCameraAPIError {
            throw error
        } catch {
            let summary = trimmedResponse.prefix(160)
            throw SpeedCameraAPIError.invalidFormat(summary: String(summary))
        }
    }

    private func parseXMLPage(_ data: Data) throws -> SpeedCameraPage {
        let parserDelegate = SpeedCameraXMLParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = parserDelegate

        guard parser.parse() else {
            throw SpeedCameraAPIError.xmlParseFailed
        }

        if let resultCode = parserDelegate.resultCode, resultCode != "00" {
            if resultCode == "03" {
                return SpeedCameraPage(totalCount: 0, cameras: [])
            }
            throw SpeedCameraAPIError.apiError(
                code: resultCode,
                message: parserDelegate.resultMessage ?? "알 수 없는 오류"
            )
        }

        return SpeedCameraPage(
            totalCount: parserDelegate.totalCount,
            cameras: parserDelegate.items.compactMap { SpeedCameraItem(dictionary: $0).speedCamera }
        )
    }
}

private enum SpeedCameraAPIError: LocalizedError {
    case apiError(code: String, message: String)
    case invalidFormat(summary: String)
    case xmlParseFailed

    var errorDescription: String? {
        switch self {
        case .apiError(let code, let message):
            return "공공데이터 API 오류 \(code): \(message)"
        case .invalidFormat(let summary):
            return "공공데이터 응답 포맷을 해석하지 못했습니다: \(summary)"
        case .xmlParseFailed:
            return "공공데이터 XML 응답을 해석하지 못했습니다."
        }
    }
}

private enum SpeedCameraRegionRequestError: Error {
    case cooldown
    case cancelled
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
    let body: SpeedCameraBody?
}

private struct SpeedCameraHeader: Decodable {
    let resultCode: String
    let resultMsg: String
}

private struct SpeedCameraBody: Decodable {
    let totalCount: Int
    let items: SpeedCameraItems?

    var normalizedItems: [SpeedCameraItem] {
        items?.values ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case totalCount
        case items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalCount = try container.decodeFlexibleInt(forKey: .totalCount) ?? 0
        items = try container.decodeIfPresent(SpeedCameraItems.self, forKey: .items)
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

        if let wrapper = try? container.decode(SpeedCameraItemWrapper.self) {
            self = .wrapper(wrapper)
            return
        }

        if (try? container.decode(String.self)) != nil {
            self = .list([])
            return
        }

        self = .list([])
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

    private enum CodingKeys: String, CodingKey {
        case mnlssRegltCameraManageNo
        case itlpc
        case regltSe
        case lmttVe
        case ctprvnNm
        case signguNm
        case latitude
        case longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mnlssRegltCameraManageNo = try container.decodeFlexibleString(forKey: .mnlssRegltCameraManageNo)
        itlpc = try container.decodeFlexibleString(forKey: .itlpc)
        regltSe = try container.decodeFlexibleString(forKey: .regltSe)
        lmttVe = try container.decodeFlexibleString(forKey: .lmttVe)
        ctprvnNm = try container.decodeFlexibleString(forKey: .ctprvnNm)
        signguNm = try container.decodeFlexibleString(forKey: .signguNm)
        latitude = try container.decodeFlexibleString(forKey: .latitude)
        longitude = try container.decodeFlexibleString(forKey: .longitude)
    }

    init(dictionary: [String: String]) {
        mnlssRegltCameraManageNo = dictionary["mnlssRegltCameraManageNo"]
        itlpc = dictionary["itlpc"]
        regltSe = dictionary["regltSe"]
        lmttVe = dictionary["lmttVe"]
        ctprvnNm = dictionary["ctprvnNm"]
        signguNm = dictionary["signguNm"]
        latitude = dictionary["latitude"]
        longitude = dictionary["longitude"]
    }

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

private final class SpeedCameraXMLParserDelegate: NSObject, XMLParserDelegate {
    private(set) var resultCode: String?
    private(set) var resultMessage: String?
    private(set) var totalCount: Int = 0
    private(set) var items: [[String: String]] = []

    private var currentItem: [String: String]?
    private var currentText = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentText = ""

        if elementName == "item" {
            currentItem = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if elementName == "item" {
            if let currentItem = currentItem {
                items.append(currentItem)
            }
            currentItem = nil
            currentText = ""
            return
        }

        if currentItem != nil, !value.isEmpty {
            currentItem?[elementName] = value
        } else if !value.isEmpty {
            switch elementName {
            case "resultCode":
                resultCode = value
            case "resultMsg", "resultMessage", "returnAuthMsg", "errMsg":
                resultMessage = value
            case "totalCount":
                totalCount = Int(value) ?? 0
            default:
                break
            }
        }

        currentText = ""
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}
