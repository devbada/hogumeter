//
//  MainMeterView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct MainMeterView: View {
    @State var viewModel: MeterViewModel
    @State private var showReceipt = false  // 영수증 표시 상태

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 요금 표시
                FareDisplayView(fare: viewModel.currentFare)
                    .padding(.top, 10)

                // 말 애니메이션
                HorseAnimationView(speed: viewModel.horseSpeed)
                    .frame(height: 200)

                Spacer()

                // 주행 정보
                TripInfoView(
                    distance: viewModel.distance,
                    duration: viewModel.duration,
                    speed: viewModel.currentSpeed,
                    region: viewModel.currentRegion
                )
                .padding(.horizontal)

                // 컨트롤 버튼
                ControlButtonsView(
                    state: viewModel.state,
                    onStart: { viewModel.startMeter() },
                    onStop: { viewModel.stopMeter() },
                    onReset: { viewModel.resetMeter() }
                )
                .padding(.bottom, 20)
            }
            .navigationTitle("🐴 호구미터")
            // 영수증 Sheet 추가
            .sheet(isPresented: $showReceipt) {
                if let trip = viewModel.completedTrip {
                    ReceiptView(trip: trip)
                        .onDisappear {
                            viewModel.clearCompletedTrip()
                        }
                }
            }
            .onChange(of: viewModel.completedTrip) { _, newTrip in
                showReceipt = (newTrip != nil)
            }
        }
    }
}

#Preview {
    MainMeterView(
        viewModel: MeterViewModel(
            locationService: LocationService(),
            fareCalculator: FareCalculator(settingsRepository: SettingsRepository()),
            regionDetector: RegionDetector(),
            soundManager: SoundManager(),
            tripRepository: TripRepository()
        )
    )
}
