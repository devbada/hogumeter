//
//  RegionFareListView.swift
//  HoguMeter
//
//  Created on 2025-12-10.
//

import SwiftUI

/// 지역별 요금 목록 화면
struct RegionFareListView: View {
    @State var viewModel: RegionFareViewModel
    @State private var showAddSheet = false
    @State private var editingFare: RegionFare?
    @State private var showDeleteAlert = false
    @State private var fareToDelete: RegionFare?

    var body: some View {
        List {
            // 현재 선택된 지역
            Section {
                HStack {
                    Text("📍 현재 선택")
                        .font(.headline)

                    Spacer()

                    if let selectedFare = viewModel.fares.first(where: { $0.code == viewModel.selectedFareCode }) {
                        Text(selectedFare.name)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
            }

            // 지역 목록
            Section {
                ForEach(viewModel.fares) { fare in
                    RegionFareRowView(
                        fare: fare,
                        isSelected: fare.code == viewModel.selectedFareCode
                    )
                    .onTapGesture {
                        viewModel.selectFare(fare)
                    }
                    .onLongPressGesture {
                        editingFare = fare
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if fare.canDelete {
                            Button(role: .destructive) {
                                fareToDelete = fare
                                showDeleteAlert = true
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("등록된 지역")
            }

            // 새 지역 추가 버튼
            Section {
                Button {
                    showAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("새 지역 추가")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("지역별 요금")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                RegionFareAddView(viewModel: viewModel, isPresented: $showAddSheet)
            }
        }
        .sheet(item: $editingFare) { fare in
            NavigationStack {
                RegionFareEditView(
                    viewModel: viewModel,
                    fare: fare,
                    isPresented: .init(
                        get: { editingFare != nil },
                        set: { if !$0 { editingFare = nil } }
                    )
                )
            }
        }
        .alert("지역 삭제", isPresented: $showDeleteAlert, presenting: fareToDelete) { fare in
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                viewModel.deleteFare(fare)
            }
        } message: { fare in
            Text("'\(fare.name)' 지역을 삭제하시겠습니까?")
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegionFareListView(
            viewModel: RegionFareViewModel(
                repository: RegionFareRepository()
            )
        )
    }
}
