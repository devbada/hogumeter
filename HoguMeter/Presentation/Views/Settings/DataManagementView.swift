//
//  DataManagementView.swift
//  HoguMeter
//
//  Created on 2026-01-19.
//

import SwiftUI

struct DataManagementView: View {
    @StateObject private var viewModel = DataManagementViewModel()
    @State private var showCleanupAlert = false
    @State private var showDeleteAllAlert = false

    var body: some View {
        Form {
            // Storage Status Section
            storageStatusSection

            // Storage Settings Section
            storageSettingsSection

            // Auto Cleanup Section
            autoCleanupSection

            // Manual Cleanup Section
            manualCleanupSection
        }
        .navigationTitle("데이터 관리")
        .onAppear {
            viewModel.loadStats()
        }
        .alert("경로 데이터 정리", isPresented: $showCleanupAlert) {
            Button("취소", role: .cancel) { }
            Button("정리") {
                viewModel.cleanupOldRoutes()
            }
        } message: {
            Text("3개월 이상 된 경로 데이터를 삭제합니다.\n요금, 거리 등 기본 정보는 유지됩니다.")
        }
        .alert("전체 기록 삭제", isPresented: $showDeleteAllAlert) {
            Button("취소", role: .cancel) { }
            Button("전체 삭제", role: .destructive) {
                viewModel.deleteAllData()
            }
        } message: {
            Text("모든 주행 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
        }
    }

    // MARK: - Sections

    private var storageStatusSection: some View {
        Section {
            LabeledContent("총 기록 수", value: "\(viewModel.stats.totalTripCount)개")
            LabeledContent("사용 중인 용량", value: viewModel.stats.formattedTotalSize)
            LabeledContent("경로 데이터", value: viewModel.stats.formattedRouteDataSize)
            LabeledContent("메타데이터", value: viewModel.stats.formattedMetadataSize)
        } header: {
            Label("저장 현황", systemImage: "chart.bar")
        }
    }

    private var storageSettingsSection: some View {
        Section {
            Toggle(isOn: $viewModel.settings.saveRouteData) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("경로 데이터 저장")
                    Text("지도에 경로 표시용")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("저장 설정", systemImage: "gearshape")
        }
    }

    private var autoCleanupSection: some View {
        Section {
            Toggle(isOn: $viewModel.settings.autoCleanupEnabled) {
                Text("자동 정리 사용")
            }

            if viewModel.settings.autoCleanupEnabled {
                Picker("정리 기준", selection: $viewModel.cleanupPolicyType) {
                    ForEach(CleanupPolicyType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                switch viewModel.cleanupPolicyType {
                case .ageBased:
                    Stepper(value: $viewModel.ageMonths, in: 1...12) {
                        Text("\(viewModel.ageMonths)개월 이후 삭제")
                    }
                case .countBased:
                    Stepper(value: $viewModel.maxCount, in: 50...500, step: 50) {
                        Text("\(viewModel.maxCount)개 초과 시 삭제")
                    }
                case .sizeBased:
                    Stepper(value: $viewModel.maxMB, in: 50...500, step: 50) {
                        Text("\(viewModel.maxMB)MB 초과 시 삭제")
                    }
                }

                Toggle(isOn: $viewModel.settings.deleteRouteOnly) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("경로만 삭제")
                        Text("메타데이터(요금, 거리 등)는 유지")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("자동 정리", systemImage: "arrow.3.trianglepath")
        } footer: {
            if viewModel.settings.autoCleanupEnabled {
                Text("앱 실행 시 자동으로 정리가 수행됩니다.")
            }
        }
    }

    private var manualCleanupSection: some View {
        Section {
            Button {
                showCleanupAlert = true
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("오래된 경로 데이터 정리")
                            .foregroundColor(.primary)
                        Text("3개월 이상 된 경로만 삭제")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button(role: .destructive) {
                showDeleteAllAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("전체 기록 삭제")
                        Text("모든 주행 기록 삭제 (복구 불가)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Label("수동 정리", systemImage: "trash")
        }
    }
}

#Preview {
    NavigationView {
        DataManagementView()
    }
}
