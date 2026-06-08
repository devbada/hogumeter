//
//  AppStoreScreenshots.swift
//  HoguMeter
//
//  App Store 스크린샷용 프리뷰
//  Xcode Preview에서 각 화면을 캡처하여 스크린샷으로 사용
//

import SwiftUI
import CoreLocation

// MARK: - Screenshot 더미용 편의 init
// RoutePoint의 정식 init이 `init(location: CLLocation)` 하나뿐이라 좌표만으로 생성하는 편의 init을
// 이 파일 한정으로 제공한다. (entity 본체는 그대로 유지)
private extension RoutePoint {
    init(latitude: Double, longitude: Double) {
        self.init(location: CLLocation(latitude: latitude, longitude: longitude))
    }
}

// MARK: - Mock Data for Screenshots

private enum ScreenshotMockData {

    static let sampleTrip = Trip(
        id: UUID(),
        startTime: Date().addingTimeInterval(-1800),
        endTime: Date(),
        totalFare: 18500,
        distance: 12.3,
        duration: 1800,
        startRegion: "서울",
        endRegion: "경기",
        regionChanges: 1,
        isNightTrip: false,
        fareBreakdown: FareBreakdown(
            baseFare: 4800,
            distanceFare: 10200,
            timeFare: 1500,
            regionSurcharge: 2000,
            nightSurcharge: 0
        ),
        routePoints: [
            RoutePoint(latitude: 37.5665, longitude: 126.9780),
            RoutePoint(latitude: 37.5700, longitude: 126.9850),
            RoutePoint(latitude: 37.5750, longitude: 126.9920),
            RoutePoint(latitude: 37.5800, longitude: 127.0000),
            RoutePoint(latitude: 37.5850, longitude: 127.0100)
        ],
        driverQuote: "오늘도 안전 운행!"
    )

    static let sampleTrips: [Trip] = [
        Trip(
            id: UUID(),
            startTime: Date().addingTimeInterval(-86400),
            endTime: Date().addingTimeInterval(-84600),
            totalFare: 15200,
            distance: 8.5,
            duration: 1200,
            startRegion: "강남",
            endRegion: "홍대",
            regionChanges: 0,
            isNightTrip: false,
            fareBreakdown: FareBreakdown(
                baseFare: 4800, distanceFare: 8400, timeFare: 2000,
                regionSurcharge: 0, nightSurcharge: 0
            )
        ),
        Trip(
            id: UUID(),
            startTime: Date().addingTimeInterval(-172800),
            endTime: Date().addingTimeInterval(-171600),
            totalFare: 22800,
            distance: 15.2,
            duration: 2400,
            startRegion: "서울역",
            endRegion: "잠실",
            regionChanges: 1,
            isNightTrip: true,
            fareBreakdown: FareBreakdown(
                baseFare: 4800, distanceFare: 12000, timeFare: 3000,
                regionSurcharge: 2000, nightSurcharge: 1000
            )
        ),
        Trip(
            id: UUID(),
            startTime: Date().addingTimeInterval(-259200),
            endTime: Date().addingTimeInterval(-258000),
            totalFare: 9500,
            distance: 5.2,
            duration: 900,
            startRegion: "신촌",
            endRegion: "이대",
            regionChanges: 0,
            isNightTrip: false,
            fareBreakdown: FareBreakdown(
                baseFare: 4800, distanceFare: 3200, timeFare: 1500,
                regionSurcharge: 0, nightSurcharge: 0
            )
        )
    ]
}

// MARK: - Screenshot 1: Main Meter (Idle State)

struct Screenshot_MainIdle: View {
    var body: some View {
        VStack(spacing: 0) {
            // 프로모션 텍스트
            Text("실시간 택시 요금 미터기")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 60)
                .padding(.bottom, 20)

            // 앱 화면
            ScreenshotMainMeterView(
                fare: 4800,
                distance: 0,
                duration: 0,
                speed: 0,
                region: "서울",
                state: .idle,
                horseSpeed: .idle
            )
            .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Screenshot 2: Main Meter (Running State)

struct Screenshot_MainRunning: View {
    var body: some View {
        VStack(spacing: 0) {
            // 프로모션 텍스트
            Text("정확한 거리 기반 요금 계산")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 60)
                .padding(.bottom, 20)

            // 앱 화면
            ScreenshotMainMeterView(
                fare: 12500,
                distance: 5.2,
                duration: 720,
                speed: 42,
                region: "서울",
                state: .running,
                horseSpeed: .gallop
            )
            .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Screenshot 3: Receipt

struct Screenshot_Receipt: View {
    var body: some View {
        VStack(spacing: 0) {
            // 프로모션 텍스트
            Text("상세한 영수증으로 요금 확인")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 60)
                .padding(.bottom, 20)

            // 영수증 미리보기
            ScreenshotReceiptView(trip: ScreenshotMockData.sampleTrip)
                .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Screenshot 4: Settings

struct Screenshot_Settings: View {
    var body: some View {
        VStack(spacing: 0) {
            // 프로모션 텍스트
            Text("전국 7대 도시 요금 지원")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 60)
                .padding(.bottom, 20)

            // 설정 화면
            ScreenshotSettingsView()
                .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Screenshot 5: Region Fare List

struct Screenshot_RegionFares: View {
    var body: some View {
        VStack(spacing: 0) {
            // 프로모션 텍스트
            VStack(spacing: 4) {
                Text("서울, 부산, 대구, 인천")
                    .font(.system(size: 24, weight: .bold))
                Text("광주, 대전, 경기")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.primary)
            .padding(.top, 60)
            .padding(.bottom, 20)

            // 지역별 요금 화면
            ScreenshotRegionFareListView()
                .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Screenshot 6: Trip History

struct Screenshot_History: View {
    var body: some View {
        VStack(spacing: 0) {
            // 프로모션 텍스트
            Text("모든 주행 기록을 한눈에")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 60)
                .padding(.bottom, 20)

            // 주행 기록 화면
            ScreenshotTripHistoryView(trips: ScreenshotMockData.sampleTrips)
                .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Simplified Views for Screenshots

private struct ScreenshotMainMeterView: View {
    let fare: Int
    let distance: Double
    let duration: TimeInterval
    let speed: Double
    let region: String
    let state: MeterState
    let horseSpeed: HorseSpeed

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 요금 표시
                FareDisplayView(fare: fare)

                // 말 애니메이션
                HorseAnimationView(speed: horseSpeed)
                    .frame(height: 200)

                Spacer()

                // 주행 정보
                TripInfoView(
                    distance: distance,
                    duration: duration,
                    speed: speed,
                    region: region
                )
                .padding(.horizontal)

                // 컨트롤 버튼
                ScreenshotControlButtons(state: state)
                    .padding(.bottom, 20)
            }
            .navigationTitle("🐴 호구미터")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ScreenshotControlButtons: View {
    let state: MeterState

    var body: some View {
        HStack(spacing: 20) {
            switch state {
            case .idle:
                Button(action: {}) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 30))
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.green))
                }
            case .running:
                Button(action: {}) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 30))
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.red))
                }
            case .stopped:
                Button(action: {}) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 30))
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.orange))
                }
            }
        }
    }
}

private struct ScreenshotReceiptView: View {
    let trip: Trip

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    VStack(spacing: 15) {
                        Text("🏇")
                            .font(.system(size: 50))
                        Text("호구미터")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("TAXI FARE RECEIPT")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    Divider()
                        .padding(.vertical, 15)

                    // 시간 정보
                    VStack(spacing: 10) {
                        HStack {
                            Text("출발").foregroundColor(.secondary)
                            Spacer()
                            Text(trip.startTime.formatted(date: .omitted, time: .shortened))
                                .fontWeight(.semibold)
                        }
                        HStack {
                            Text("도착").foregroundColor(.secondary)
                            Spacer()
                            Text(trip.endTime.formatted(date: .omitted, time: .shortened))
                                .fontWeight(.semibold)
                        }
                        HStack {
                            Text("날짜").foregroundColor(.secondary)
                            Spacer()
                            Text(trip.startTime.formatted(date: .abbreviated, time: .omitted))
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.body)
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 15)

                    // 요금 내역
                    VStack(spacing: 10) {
                        Text("요금 내역")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        fareRow("기본 요금", trip.fareBreakdown.baseFare)
                        fareRow("거리 요금", trip.fareBreakdown.distanceFare)
                        fareRow("시간 요금", trip.fareBreakdown.timeFare)
                        if trip.fareBreakdown.regionSurcharge > 0 {
                            fareRow("지역 할증", trip.fareBreakdown.regionSurcharge)
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 15)

                    // 총 요금
                    HStack {
                        Text("총 요금")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(trip.totalFare.formattedWithComma)원")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("영수증")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func fareRow(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text("\(value.formattedWithComma)원").fontWeight(.semibold)
        }
    }
}

private struct ScreenshotSettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("요금 설정") {
                    HStack {
                        Label("지역별 요금", systemImage: "map")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                Section("할증 설정") {
                    Toggle(isOn: .constant(true)) {
                        Label("야간 할증", systemImage: "moon")
                    }

                    Toggle(isOn: .constant(true)) {
                        Label("지역 할증", systemImage: "location")
                    }

                    HStack {
                        Text("지역 할증 금액")
                        Spacer()
                        Text("2,000원")
                            .foregroundColor(.secondary)
                    }
                }

                Section("앱 설정") {
                    Toggle(isOn: .constant(true)) {
                        Label("효과음", systemImage: "speaker.wave.2")
                    }

                    HStack {
                        Text("다크 모드")
                        Spacer()
                        Text("시스템 설정")
                            .foregroundColor(.secondary)
                    }
                }

                Section("정보") {
                    HStack {
                        Label("앱 정보", systemImage: "info.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}

private struct ScreenshotRegionFareListView: View {
    private let regions = [
        ("서울", 4800, 131, 100),
        ("경기", 4800, 132, 100),
        ("부산", 4200, 133, 100),
        ("대구", 4000, 131, 100),
        ("인천", 4000, 140, 100),
        ("광주", 4000, 133, 100),
        ("대전", 4000, 132, 100)
    ]

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("📍 현재 선택")
                            .font(.headline)
                        Spacer()
                        Text("서울")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }

                Section {
                    ForEach(regions, id: \.0) { region in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(region.0)
                                    .font(.headline)
                                Text("기본 \(region.1)원 • \(region.2)m당 \(region.3)원")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if region.0 == "서울" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("등록된 지역")
                }

                Section {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("새 지역 추가")
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("지역별 요금")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ScreenshotTripHistoryView: View {
    let trips: [Trip]

    var body: some View {
        NavigationView {
            List {
                ForEach(trips) { trip in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(formattedDate(trip.startTime))
                                .font(.headline)
                            Spacer()
                            Text("\(trip.totalFare.formatted())원")
                                .font(.headline)
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("\(String(format: "%.1f", trip.distance)) km")
                            Text("•")
                            Text("\(Int(trip.duration) / 60)분")
                            Text("•")
                            Text("\(trip.startRegion) → \(trip.endRegion)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("주행 기록")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("편집")
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Previews for iPhone 14 Pro Max (1284 × 2778)

#Preview("1. 메인 화면 (대기)") {
    Screenshot_MainIdle()
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
}

#Preview("2. 주행 중") {
    Screenshot_MainRunning()
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
}

#Preview("3. 영수증") {
    Screenshot_Receipt()
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
}

#Preview("4. 설정") {
    Screenshot_Settings()
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
}

#Preview("5. 지역별 요금") {
    Screenshot_RegionFares()
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
}

#Preview("6. 주행 기록") {
    Screenshot_History()
        .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro Max"))
}
