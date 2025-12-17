//
//  MainMeterView.swift
//  HoguMeter
//
//  Created on 2025-01-15.
//

import SwiftUI

struct MainMeterView: View {
    @State var viewModel: MeterViewModel
    @State private var receiptTrip: Trip?   // 영수증에 표시할 Trip
    @State private var showMap = false      // 지도 표시 상태
    @State private var showDriverQuote = false  // 택시기사 한마디 표시 상태

    var body: some View {
        NavigationView {
            ZStack {
                // 배경 마키 텍스트 (미터기 작동 중에만 표시)
                MarqueeBackgroundView(
                    texts: DisclaimerText.marqueeTexts,
                    isVisible: viewModel.state == .running
                )

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

                // 이스터에그 오버레이
                EasterEggOverlayView(
                    easterEgg: viewModel.easterEggManager.triggeredEasterEgg,
                    onDismiss: { viewModel.easterEggManager.dismissEasterEgg() }
                )

                // 택시기사 한마디 (오버레이, 30초 후 자동 사라짐)
                if showDriverQuote, !viewModel.currentDriverQuote.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 200)
                        DriverQuoteBubbleView(quote: viewModel.currentDriverQuote)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.5), value: showDriverQuote)
                    .onTapGesture {
                        withAnimation {
                            showDriverQuote = false
                        }
                    }
                }
            }
            .navigationTitle("🐴 호구미터")
            .toolbar {
                // 지도 버튼 (미터 실행 중일 때만 표시)
                if viewModel.state == .running {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showMap = true }) {
                            Image(systemName: "map")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            // 지도 화면
            .fullScreenCover(isPresented: $showMap, onDismiss: {
                // 지도 화면 닫힌 후 영수증 표시
                if let trip = viewModel.completedTrip {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        receiptTrip = trip
                    }
                }
            }) {
                MapContainerView(
                    meterViewModel: viewModel,
                    locationService: viewModel.locationService,
                    routeManager: viewModel.routeManager,
                    isPresented: $showMap
                )
            }
            // 영수증 Sheet (item 기반)
            .sheet(item: $receiptTrip) { trip in
                ReceiptView(trip: trip)
                    .onDisappear {
                        viewModel.clearCompletedTrip()
                    }
            }
            .onChange(of: viewModel.completedTrip) { _, newTrip in
                // 지도 화면이 열려있지 않을 때만 영수증 표시
                if !showMap, let trip = newTrip {
                    receiptTrip = trip
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                // 미터 시작 시 택시기사 한마디 표시 (30초 후 자동 사라짐)
                if newState == .running {
                    withAnimation {
                        showDriverQuote = true
                    }
                    // 30초 후 자동으로 사라짐
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                        withAnimation {
                            showDriverQuote = false
                        }
                    }
                } else {
                    showDriverQuote = false
                }
            }
        }
    }
}

#Preview {
    let settingsRepo = SettingsRepository()
    return MainMeterView(
        viewModel: MeterViewModel(
            locationService: LocationService(settingsRepository: settingsRepo),
            fareCalculator: FareCalculator(settingsRepository: settingsRepo),
            regionDetector: RegionDetector(),
            soundManager: SoundManager(),
            tripRepository: TripRepository()
        )
    )
}
