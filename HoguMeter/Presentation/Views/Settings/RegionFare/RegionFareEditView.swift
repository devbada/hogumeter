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

    init(viewModel: RegionFareViewModel, fare: RegionFare, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._editedFare = State(initialValue: fare)
        self._isPresented = isPresented
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

            // 주간 요금 (04:00 ~ 22:00)
            Section {
                FareInputField(
                    title: "기본요금",
                    value: $editedFare.dayBaseFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "기본거리",
                    value: $editedFare.dayBaseDistance,
                    suffix: "m",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "거리당 요금",
                    value: $editedFare.dayDistanceFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "거리 단위",
                    value: $editedFare.dayDistanceUnit,
                    suffix: "m",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "시간당 요금",
                    value: $editedFare.dayTimeFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "시간 단위",
                    value: $editedFare.dayTimeUnit,
                    suffix: "초",
                    keyboardType: .numberPad
                )
            } header: {
                HStack {
                    Text("주간 요금")
                    Text("☀️ 04:00 ~ 22:00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 심야1 요금 (22:00 ~ 23:00, 02:00 ~ 04:00) - 20% 할증
            Section {
                FareInputField(
                    title: "기본요금",
                    value: $editedFare.night1BaseFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "기본거리",
                    value: $editedFare.night1BaseDistance,
                    suffix: "m",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "거리당 요금",
                    value: $editedFare.night1DistanceFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "거리 단위",
                    value: $editedFare.night1DistanceUnit,
                    suffix: "m",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "시간당 요금",
                    value: $editedFare.night1TimeFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "시간 단위",
                    value: $editedFare.night1TimeUnit,
                    suffix: "초",
                    keyboardType: .numberPad
                )
            } header: {
                HStack {
                    Text("심야1 요금 (20% 할증)")
                    Text("🌙 22:00 ~ 23:00, 02:00 ~ 04:00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 심야2 요금 (23:00 ~ 02:00) - 40% 할증
            Section {
                FareInputField(
                    title: "기본요금",
                    value: $editedFare.night2BaseFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "기본거리",
                    value: $editedFare.night2BaseDistance,
                    suffix: "m",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "거리당 요금",
                    value: $editedFare.night2DistanceFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "거리 단위",
                    value: $editedFare.night2DistanceUnit,
                    suffix: "m",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "시간당 요금",
                    value: $editedFare.night2TimeFare,
                    suffix: "원",
                    keyboardType: .numberPad
                )

                FareInputField(
                    title: "시간 단위",
                    value: $editedFare.night2TimeUnit,
                    suffix: "초",
                    keyboardType: .numberPad
                )
            } header: {
                HStack {
                    Text("심야2 요금 (40% 할증)")
                    Text("🌑 23:00 ~ 02:00")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
            fare: RegionFare.seoul(),
            isPresented: .constant(true)
        )
    }
}
