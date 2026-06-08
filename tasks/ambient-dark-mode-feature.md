# Ambient Dark Mode — 구현 지시서

> **연관 문서**: [`SPEC_AMBIENT_DARK_MODE.md`](../SPEC_AMBIENT_DARK_MODE.md)
> **유형**: 신규 기능
> **우선순위**: P2
> **추정**: 약 4.5시간

## 개요

휴대폰의 화면 밝기(`UIScreen.brightness`)를 ambient light의 프록시로 사용해 라이트/다크 모드를 자동 전환한다. 사용자에게는 `자동 / 라이트 / 다크` 3-way 선택을 제공한다. 자세한 동작은 SPEC 참고.

## 선행 작업 및 검토 사항

- [ ] iOS 17.0+, `UIApplicationSupportsMultipleScenes: true` 환경 확인됨 (project.yml 기준)
- [ ] 기존 SettingsRepository에 같은 이름 키가 없는지 확인 (`darkModeStrategy`)
- [ ] 기존 SettingsView에 다크모드 관련 토글이 이미 있는지 검색
- [ ] 영수증·면책 마키·말 애니메이션·코치마크에서 라이트 가정 색이 하드코딩된 곳 사전 파악

## Phase 1 — 데이터 모델 & 영속화

### 신규 파일
- `HoguMeter/Domain/Entities/DarkModeStrategy.swift`
  - `enum DarkModeStrategy: String, CaseIterable, Codable, Identifiable`
  - cases: `auto`, `light`, `dark`
  - `displayName: String` computed (한글 표기)

### 수정 파일
- `HoguMeter/Data/Repositories/SettingsRepository.swift`
  - `var darkModeStrategy: DarkModeStrategy { get set }` 추가
  - UserDefaults 키 `darkModeStrategy`로 rawValue 저장
  - 기본값 `.auto`
  - `SettingsRepositoryProtocol`이 있다면 프로토콜에도 추가

### 완료 조건
- SettingsRepositoryTests에서 `darkModeStrategy` set/get 순회 검증
- DEFAULT 값이 `.auto`로 시작하는 것 확인

## Phase 2 — 조도 관찰 서비스

### 신규 파일
- `HoguMeter/Domain/Services/AmbientLightObserver.swift`
  - `@MainActor @Observable final class`
  - 프로퍼티: `brightness: Double`, `inferredScheme: ColorScheme`
  - 상수: `lightToDarkThreshold = 0.30`, `darkToLightThreshold = 0.45`
  - 메서드: `startObserving()`, `stopObserving()`, `private func evaluate(brightness:)`
  - **`UIScreen.main.brightness` 직접 접근 금지** — multi-scene 환경이므로 `UIApplication.shared.connectedScenes`에서 `UIWindowScene.screen.brightness` 사용 (SPEC 참고)
  - notification 구독: `UIScreen.brightnessDidChangeNotification`
  - hysteresis 로직: light→dark는 `< 0.30`일 때, dark→light는 `> 0.45`일 때만 전환

### 신규 파일
- `HoguMeterTests/AmbientLightObserverTests.swift`
  - 임계값 통과/미통과 시나리오 6종 (SPEC Testing 섹션 참고)
  - 테스트 가능성 위해 임계값과 brightness 입력을 외부 주입 가능한 init 추가 권장

### 완료 조건
- 단위 테스트 6종 통과
- 메모리 누수 점검 (Instruments Leaks 또는 `deinit` 로그 — observerToken 해제 확인)

## Phase 3 — Effective ColorScheme 계산 뷰모델

### 신규 파일
- `HoguMeter/Presentation/ViewModels/AppearanceViewModel.swift`
  - `@MainActor @Observable final class`
  - 의존성 (init 주입): `SettingsRepositoryProtocol`, `AmbientLightObserver`
  - `var strategy: DarkModeStrategy` (set 시 SettingsRepository에 영속화)
  - `var effectiveColorScheme: ColorScheme` computed
    - `.auto` → `observer.inferredScheme`
    - `.light` → `.light`
    - `.dark` → `.dark`

### 신규 파일
- `HoguMeterTests/AppearanceViewModelTests.swift`
  - 시나리오 4종 (SPEC Testing 섹션 참고)
  - SettingsRepository 모킹: 기존 mock 패턴 따름

### 완료 조건
- 단위 테스트 4종 통과
- strategy 변경 시 SettingsRepository에 즉시 영속화 확인

## Phase 4 — 앱 전역 적용

### 수정 파일
- `HoguMeter/App/HoguMeterApp.swift`
  - `@State` 또는 `@Environment`로 `AppearanceViewModel` 주입
  - `WindowGroup`의 루트 뷰에 `.preferredColorScheme(appearance.effectiveColorScheme)` 적용
  - `.onChange(of: scenePhase) { ... }`로 `.active`/`.background` 진입 시 observer start/stop
  - `withAnimation(.easeInOut(duration: 0.35)) { ... }` 같은 부드러운 전환 적용 검토

### 완료 조건
- 시뮬레이터에서 strategy 변경 시 모든 화면이 동시에 전환됨 (스플래시·메인·설정·기록·지도)
- 실기기에서 자동 모드 시 어두운 곳/밝은 곳 이동에 반응

## Phase 5 — 설정 UI

### 수정 파일
- `HoguMeter/Presentation/Views/Settings/SettingsView.swift`
  - 새 섹션 `"표시"` 또는 기존 표시 섹션에 항목 추가
  - 항목명: "다크모드"
  - SwiftUI `Picker("다크모드", selection: $appearance.strategy)`
    - `.pickerStyle(.menu)` 또는 `.segmented` (디자인 통일)
    - 옵션은 `DarkModeStrategy.allCases`의 `displayName` 표시
  - `.auto` 선택 시 1회성 안내 토스트 (Open Question #1 결정 대기. 임시는 `Text` hint)
    - 안내 노출 여부 UserDefaults 키: `didShowAmbientDarkModeHint`

### 완료 조건
- 설정에서 strategy 토글 시 즉시 전체 화면 색 스킴 바뀜
- 앱 재실행 후 strategy 유지됨

## Phase 6 — 검증 & 회귀

### 자동
- Phase 2, 3에서 추가한 단위 테스트 전수 통과
- 기존 SettingsRepositoryTests 회귀 없음
- HoguMeterTests target 빌드 정상

### 수동 QA 시나리오
SPEC `Testing → Manual QA` 9개 시나리오를 모두 수행하고 결과 기록.

### 회귀 영향 확인 영역 (다크모드에서 시각적으로 깨지는 곳 점검)
- 영수증 캡쳐 (`ReceiptView`, `TemplateReceiptGenerator`)
- 면책 마키 (`MarqueeBackgroundView`)
- 말 애니메이션 (`HorseAnimationView`, `HorseCharacterView`, `HorseEffectsView`)
- 코치마크 오버레이 (`CoachMarkOverlay`, `SpotlightBackground`, `TooltipBubble`)
- 지도 (`MapViewRepresentable`) — Apple Maps는 자동 따라가지만 마커/폴리라인 색은 확인
- 운전기사 멘트 (`DriverQuoteBubbleView`) — 노란 배경 + 검은 글씨 가정

발견된 라이트 가정 하드코딩은 별도 follow-up task로 분리.

## 롤백 절차

기능을 일시적으로 끄려면:
1. `HoguMeterApp.swift`에서 `.preferredColorScheme(...)` 모디파이어 한 줄 주석 처리
2. `SettingsView.swift`에서 다크모드 섹션 숨기기

신규 파일들(`DarkModeStrategy.swift`, `AmbientLightObserver.swift`, `AppearanceViewModel.swift`)은 미사용 상태로 두어도 안전. UserDefaults 키도 잔존해도 OK.

기능 완전 제거 시:
1. 위 두 변경 + 신규 파일 삭제
2. `xcodegen generate` 재실행
3. SettingsRepository에서 `darkModeStrategy` 프로퍼티 제거

## 작업 추정

| Phase | 작업 | 추정 |
|-------|------|------|
| 1 | 데이터 모델 & 영속화 | 30분 |
| 2 | AmbientLightObserver + 테스트 | 1시간 |
| 3 | AppearanceViewModel + 테스트 | 30분 |
| 4 | 앱 전역 적용 | 30분 |
| 5 | 설정 UI | 1시간 |
| 6 | 회귀 QA | 1시간 |
| **합계** | | **약 4.5시간** |

## 작업 시 유의사항

- iOS 17.0+ + multi-scene 환경이므로 `UIScreen.main`이 아니라 `UIWindowScene.screen` 경로로 접근. SPEC `AmbientLightObserver` 코드 예시 참고.
- `@Observable` 매크로의 Observation 트래킹을 깨지 않도록, `AppearanceViewModel.effectiveColorScheme`는 computed 형태로 두고 내부에서 `observer.inferredScheme`을 직접 참조한다.
- xcodegen 사용 프로젝트이므로 신규 파일 추가 후 반드시 `xcodegen generate` 실행.
- 다크모드 변경 시 영수증 캡쳐 이미지는 라이트 톤이 자연스러우므로, `ReceiptView`에서는 `.preferredColorScheme(.light)`로 강제하는 것 검토. (SPEC Open Question #4)
