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
    @State private var isHoguNavigationActive = false

    // Coach Mark
    @StateObject private var coachMarkManager = CoachMarkManager.shared
    @State private var coachMarkFrames: [String: CGRect] = [:]

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let screenHeight = geometry.size.height
                let isCompactHeight = screenHeight < 600  // 작은 화면 감지
                let horseHeight = min(max(screenHeight * 0.25, 120), 200)  // 화면의 25%, 최소 120, 최대 200

                ZStack {
                    // 상단 요금 + 중앙 말 + 하단 정보/버튼
                    VStack(spacing: 0) {
                        // 요금 표시 (상단)
                        FareDisplayView(fare: viewModel.currentFare)
                            .coachMarkTarget(id: "fareDisplay")
                            .padding(.top, isCompactHeight ? 8 : 20)

                        Spacer()

                        // 말 애니메이션 (중앙, 마키 텍스트는 이 영역에만)
                        ZStack {
                            MarqueeBackgroundView(
                                texts: DisclaimerText.marqueeTexts,
                                isVisible: viewModel.state == .running
                            )

                            HorseAnimationView(speed: viewModel.horseSpeed)
                        }
                        .frame(height: horseHeight)
                        .clipped()
                        .coachMarkTarget(id: "horseAnimation")

                        Spacer()

                        // 주행 정보
                        TripInfoView(
                            distance: viewModel.distance,
                            duration: viewModel.duration,
                            speed: viewModel.currentSpeed,
                            region: viewModel.currentRegion
                        )
                        .coachMarkTarget(id: "statsGrid")
                        .padding(.horizontal)
                        .padding(.bottom, isCompactHeight ? 12 : 20)

                        // 컨트롤 버튼
                        ControlButtonsView(
                            state: viewModel.state,
                            isDisabled: isHoguNavigationActive,
                            onStart: { viewModel.startMeter() },
                            onStop: { viewModel.stopMeter() },
                            onReset: { viewModel.resetMeter() }
                        )
                        .coachMarkTarget(id: "startButton")
                        .padding(.bottom, isCompactHeight ? 12 : 20)

                        if isHoguNavigationActive {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                Text("네비게이션 사용 중에는 일반 미터기를 조작할 수 없습니다.")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.black.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                        }
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)

                // 이스터에그 오버레이
                EasterEggOverlayView(
                    easterEgg: viewModel.easterEggManager.triggeredEasterEgg,
                    onDismiss: { viewModel.easterEggManager.dismissEasterEgg() }
                )

                    // Coach Mark 오버레이
                    if coachMarkManager.isShowingCoachMark,
                       coachMarkManager.currentScreenId == "main",
                       let currentMark = coachMarkManager.currentCoachMark,
                       let frame = coachMarkFrames[currentMark.targetView] {
                        CoachMarkOverlay(
                            manager: coachMarkManager,
                            coachMark: currentMark,
                            targetFrame: frame
                        )
                    }

                    // 택시기사 한마디 (상단 알림 형태로 내려왔다가 올라감)
                    VStack {
                        if showDriverQuote, !viewModel.currentDriverQuote.isEmpty {
                            DriverQuoteBubbleView(quote: viewModel.currentDriverQuote)
                                .padding(.top, 60)  // 네비게이션 바 아래 위치
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showDriverQuote = false
                                    }
                                }
                        }
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.4), value: showDriverQuote)
                }
            }
            .navigationTitle("🐴 호구미터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 지도 버튼 (미터 실행 중일 때만 표시)
                if viewModel.state == .running && !isHoguNavigationActive {
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
                // 미터 시작 시 택시기사 한마디 표시 (메시지 길이에 따라 자동 사라짐)
                if newState == .running {
                    withAnimation {
                        showDriverQuote = true
                    }
                    // 메시지 길이에 따라 표시 시간 계산 (최소 5초, 글자당 0.15초 추가, 최대 10초)
                    let messageLength = viewModel.currentDriverQuote.count
                    let displayDuration = min(max(5.0, 5.0 + Double(messageLength) * 0.15), 10.0)

                    DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                        withAnimation {
                            showDriverQuote = false
                        }
                    }
                } else {
                    showDriverQuote = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .hoguNavigationDidStart)) { _ in
                isHoguNavigationActive = true
                if viewModel.state == .stopped {
                    viewModel.resetMeter()
                    viewModel.startMeter()
                } else if viewModel.state == .idle {
                    viewModel.startMeter()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .hoguNavigationDidStop)) { _ in
                isHoguNavigationActive = false
                if viewModel.state == .running {
                    viewModel.stopMeter()
                }
            }
            // 무이동 감지 알림
            .alert("이동이 감지되지 않습니다", isPresented: viewModel.showIdleAlertBinding) {
                Button("계속", role: .cancel) {
                    viewModel.continueFromIdleAlert()
                }
                Button("종료", role: .destructive) {
                    viewModel.stopFromIdleAlert()
                }
            } message: {
                Text("10분 동안 이동이 없습니다.\n미터기를 계속 실행하시겠습니까?")
            }
            .onCoachMarkFramesChange($coachMarkFrames)
            .onAppear {
                if coachMarkManager.shouldShowCoachMarks(for: "main") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        coachMarkManager.startCoachMarks(for: "main")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)  // iPad에서도 단일 컬럼으로 표시
    }
}

#Preview {
    let settingsRepo = SettingsRepository()
    return MainMeterView(
        viewModel: MeterViewModel(
            locationService: LocationService(settingsRepository: settingsRepo),
            fareCalculator: FareCalculator(settingsRepository: settingsRepo),
            settingsRepository: settingsRepo,
            regionDetector: RegionDetector(),
            soundManager: SoundManager(),
            tripRepository: TripRepository()
        )
    )
}
