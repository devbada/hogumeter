//
//  RegionalSurchargeModeView.swift
//  HoguMeter
//
//  Created on 2025-01-14.
//

import SwiftUI

/// 지역 할증 모드 선택 화면
struct RegionalSurchargeModeView: View {
    @AppStorage("regionalSurchargeMode") private var selectedModeRaw: String = RegionalSurchargeMode.realistic.rawValue

    private var selectedMode: RegionalSurchargeMode {
        get { RegionalSurchargeMode(rawValue: selectedModeRaw) ?? .realistic }
        nonmutating set { selectedModeRaw = newValue.rawValue }
    }

    var body: some View {
        List {
            // 모드 선택 섹션
            Section {
                ForEach(RegionalSurchargeMode.allCases, id: \.self) { mode in
                    Button(action: { selectedModeRaw = mode.rawValue }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.displayName)
                                    .foregroundColor(.primary)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } footer: {
                Text("리얼 모드는 실제 택시의 시계외 할증 기준을 따릅니다. 사업구역(시/도)을 벗어날 때만 할증이 적용됩니다.")
            }

            // 리얼 모드 도시별 할증률 안내
            if selectedMode == .realistic {
                Section("도시별 할증률") {
                    SurchargeRateRow(city: "서울", rate: "20%")
                    SurchargeRateRow(city: "부산", rate: "30%")
                    SurchargeRateRow(city: "인천", rate: "30%")
                    SurchargeRateRow(city: "대전", rate: "30%")
                    SurchargeRateRow(city: "대구 / 광주 / 울산", rate: "20%")
                    SurchargeRateRow(city: "경기도 및 기타", rate: "20%")
                }

                Section("서울 특수 구역") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("아래 구역은 서울에서 출발해도 할증이 적용되지 않습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("광명시 (통합사업구역)")
                                    .font(.subheadline)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("위례신도시 (공동사업구역)")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // 재미 모드 안내
            if selectedMode == .fun {
                Section("재미 모드 안내") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("동네(동/읍/면)가 바뀔 때마다 고정 금액이 추가됩니다.")
                            .font(.subheadline)
                        Text("실제 택시 요금과 다를 수 있습니다. 재미로 즐기세요!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("지역 할증 모드")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 할증률 행
private struct SurchargeRateRow: View {
    let city: String
    let rate: String

    var body: some View {
        HStack {
            Text(city)
            Spacer()
            Text(rate)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        RegionalSurchargeModeView()
    }
}
