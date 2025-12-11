//
//  RegionFareAddView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 새 지역 추가 화면
struct RegionFareAddView: View {
    @State var viewModel: RegionFareViewModel
    @Binding var isPresented: Bool

    @State private var regionName: String = ""
    @State private var selectedBaseCode: String? = nil
    @State private var showBaseFarePicker = false

    var body: some View {
        Form {
            // 지역 정보
            Section {
                TextField("지역명", text: $regionName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Text("예: 대전, 광주, 대구 등")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("지역 정보")
            }

            // 안내 메시지
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("기준 요금 선택")
                            .fontWeight(.semibold)
                    }

                    if let baseCode = selectedBaseCode {
                        Text("\(viewModel.getDefaultRegionName(code: baseCode)) 요금을 기준으로 생성됩니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("현재 선택된 지역의 요금을 기준으로 생성됩니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("추가 후 편집할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            // 기존 지역 복사
            Section {
                Button {
                    showBaseFarePicker = true
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("기존 지역 복사하기")

                        Spacer()

                        if let baseCode = selectedBaseCode {
                            Text(viewModel.getDefaultRegionName(code: baseCode))
                                .foregroundColor(.secondary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("새 지역 추가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    isPresented = false
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("추가") {
                    addNewRegion()
                }
                .fontWeight(.semibold)
                .disabled(regionName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showBaseFarePicker) {
            NavigationStack {
                List(viewModel.getDefaultRegionCodes(), id: \.self) { code in
                    Button {
                        selectedBaseCode = code
                        showBaseFarePicker = false
                    } label: {
                        HStack {
                            Text(viewModel.getDefaultRegionName(code: code))
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedBaseCode == code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .navigationTitle("기준 지역 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            showBaseFarePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func addNewRegion() {
        viewModel.addFare(name: regionName, basedOn: selectedBaseCode)

        if viewModel.errorMessage == nil {
            isPresented = false
        }
    }
}

#Preview {
    NavigationStack {
        RegionFareAddView(
            viewModel: RegionFareViewModel(repository: RegionFareRepository()),
            isPresented: .constant(true)
        )
    }
}
