//
//  RegionFareEditView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 지역 요금 편집 화면
struct RegionFareEditView: View {
    @State var viewModel: RegionFareViewModel
    @State private var editedFare: RegionFare
    @Binding var isPresented: Bool

    @State private var nightSurchargeText: String

    init(viewModel: RegionFareViewModel, fare: RegionFare, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._editedFare = State(initialValue: fare)
        self._isPresented = isPresented
        self._nightSurchargeText = State(initialValue: String(format: "%.1f", fare.nightSurchargeRate))
    }

    var body: some View {
        Form {
            // 지역 정보
            Section("지역 정보") {
                HStack {
                    Text("지역명")
                    Spacer()
                    TextField("지역명", text: $editedFare.name)
                        .multilineTextAlignment(.trailing)
                        .disabled(editedFare.isDefault)
                }
            }

            // 기본 요금
            Section("기본 요금") {
                FareInputField(
                    title: "기본요금",
                    value: $editedFare.baseFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "기본거리",
                    value: $editedFare.baseDistance,
                    suffix: "m",
                    keyboardType: .numberPad
                )
            }

            // 거리 요금
            Section("거리 요금") {
                FareInputField(
                    title: "거리당 요금",
                    value: $editedFare.distanceFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "거리 단위",
                    value: $editedFare.distanceUnit,
                    suffix: "m",
                    keyboardType: .numberPad
                )
            }

            // 시간 요금
            Section("시간 요금") {
                FareInputField(
                    title: "시간당 요금",
                    value: $editedFare.timeFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "시간 단위",
                    value: $editedFare.timeUnit,
                    suffix: "초",
                    keyboardType: .numberPad
                )
            }

            // 야간 할증
            Section("야간 할증") {
                HStack {
                    Text("할증 배율")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    TextField("1.0", text: $nightSurchargeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: nightSurchargeText) { _, newValue in
                            if let value = Double(newValue) {
                                editedFare.nightSurchargeRate = value
                            }
                        }

                    Text("배")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .leading)
                }

                TimePickerField(
                    title: "야간 시작",
                    time: $editedFare.nightStartTime
                )

                TimePickerField(
                    title: "야간 종료",
                    time: $editedFare.nightEndTime
                )
            }

            // 기본값으로 초기화 (기본 제공 지역만)
            if editedFare.isDefault {
                Section {
                    Button {
                        viewModel.resetToDefault(editedFare)
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("기본값으로 초기화")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }

            // 삭제 버튼 (사용자 생성 지역만)
            if editedFare.canDelete {
                Section {
                    Button(role: .destructive) {
                        viewModel.deleteFare(editedFare)
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("이 지역 삭제")
                        }
                    }
                }
            }
        }
        .navigationTitle("\(editedFare.name) 요금 편집")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    isPresented = false
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    viewModel.updateFare(editedFare)
                    if viewModel.errorMessage == nil {
                        isPresented = false
                    }
                }
                .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegionFareEditView(
            viewModel: RegionFareViewModel(repository: RegionFareRepository()),
            fare: RegionFare(
                code: "seoul",
                name: "서울",
                isDefault: true,
                baseFare: 4800,
                baseDistance: 1600,
                distanceFare: 100,
                distanceUnit: 131,
                timeFare: 100,
                timeUnit: 30,
                nightSurchargeRate: 1.2,
                nightStartTime: "22:00",
                nightEndTime: "04:00"
            ),
            isPresented: .constant(true)
        )
    }
}
