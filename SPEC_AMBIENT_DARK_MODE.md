# Ambient Dark Mode Specification

> 휴대폰의 화면 밝기를 신호로 활용해 라이트/다크 모드를 자동 전환하는 기능 명세.
> 사용자 명시적 제어권(자동 / 라이트 / 다크)도 함께 제공한다.

## Overview

호구미터는 운행 중 사용되는 앱이라 차창 밖 환경 조도가 자주 바뀐다. 매번 시스템 설정에서 다크/라이트를 토글하는 것은 비현실적이다. iOS에는 ambient light sensor에 접근하는 공식 API가 없으므로, **시스템이 자동 밝기 기능으로 화면 밝기를 자동 조절한다**는 점을 활용해 `UIScreen.brightness` 값을 ambient light의 프록시 신호로 사용한다.

## Goals

- 사용자가 매번 라이트/다크를 수동 토글하지 않아도 환경에 맞춰 자동 전환된다.
- 사용자에게 명시적 제어권(자동 / 라이트 / 다크) 3-way를 보장한다.
- 추가 권한(카메라, 위치 외) 없이 구현한다.
- 호구미터 기존 아키텍처(@Observable, SettingsRepository, SwiftUI)와 일관성을 유지한다.

## Non-Goals

- 정확한 lux 값 측정.
- 카메라 ISO/EV 기반 측정.
- 화면별 부분 다크모드 (전역 적용만 다룬다).
- iOS 16 이하 지원.

## User Experience

### 설정 화면

`설정 → 표시 → 다크모드` 섹션에 3-way Picker 추가:

| 옵션 | 동작 |
|------|------|
| 자동 (조도 기반) | 화면 밝기를 모니터링해 자동 전환. **기본값.** |
| 라이트 | brightness 무시, 항상 라이트 |
| 다크 | brightness 무시, 항상 다크 |

선택 값은 `SettingsRepository`를 통해 UserDefaults에 영속화된다 (`darkModeStrategy` 키).

### 자동 모드 동작

- 앱 시작 시 현재 brightness 값을 한 번 평가하고 즉시 적용.
- 이후 `UIScreen.brightnessDidChangeNotification`을 구독해 변화에 반응.
- 임계값(threshold) 통과 시에만 모드 전환. 깜빡임 방지를 위한 hysteresis 적용:

| 현재 모드 | brightness | 동작 |
|----------|------------|------|
| light | ≥ 0.45 | 유지 |
| light | < 0.45 | dark로 전환 |
| dark  | ≤ 0.55 | 유지 |
| dark  | > 0.55 | light로 전환 |

0.45 ~ 0.55 사이는 hysteresis 영역으로 현재 모드를 유지한다 (경계에서의 깜빡임 방지). 임계값을 0.50 부근으로 끌어올리고 띠를 0.10으로 좁혀, 적당히만 어두워져도 다크로 전환되도록 민감도를 높였다(초기값 0.30/0.45 대비).

### UX 주의사항

- iOS 시스템에서 **자동 밝기**가 꺼져 있으면 `UIScreen.brightness`는 ambient light에 반응하지 않고 사용자 슬라이더 값만 반영한다. 이는 의도된 trade-off이며, 사용자가 `자동` 모드를 처음 선택할 때 안내한다:

  > 자동 다크모드는 iOS의 자동 밝기 기능과 연동됩니다. 보다 정확한 전환을 원하시면 iOS 설정 → 손쉬운 사용 → 디스플레이 및 텍스트 크기 → 자동 밝기를 켜주세요.

  (1회성 안내 토스트 또는 영구 hint 표시는 Open Questions 참고)

- 모드 전환은 SwiftUI `withAnimation`으로 0.3~0.4초 부드럽게 한다.

## Architecture

### File Structure

```
HoguMeter/
├── App/
│   └── HoguMeterApp.swift                       # 수정: 전역 .preferredColorScheme 적용
├── Domain/
│   ├── Entities/
│   │   └── DarkModeStrategy.swift               # 신규: 3-way enum
│   └── Services/
│       └── AmbientLightObserver.swift           # 신규: UIScreen.brightness 관찰
├── Data/
│   └── Repositories/
│       └── SettingsRepository.swift             # 수정: darkModeStrategy 저장/조회 추가
└── Presentation/
    ├── ViewModels/
    │   └── AppearanceViewModel.swift            # 신규: effective colorScheme 산출
    └── Views/
        └── Settings/
            └── SettingsView.swift               # 수정: 다크모드 Picker 섹션 추가
```

### Core Models

#### DarkModeStrategy

```swift
enum DarkModeStrategy: String, CaseIterable, Codable, Identifiable {
    case auto
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto:  return "자동 (조도 기반)"
        case .light: return "라이트"
        case .dark:  return "다크"
        }
    }
}
```

#### AmbientLightObserver

`UIScreen.brightnessDidChangeNotification`을 구독하며 hysteresis 로직으로 `inferredScheme`을 갱신한다.

```swift
@MainActor
@Observable
final class AmbientLightObserver {
    /// 현재 측정값
    private(set) var brightness: Double
    /// 현재값과 hysteresis를 반영한 inferred color scheme
    private(set) var inferredScheme: ColorScheme = .light

    private let lightToDarkThreshold: Double = 0.30
    private let darkToLightThreshold: Double = 0.45

    private var observerToken: NSObjectProtocol?

    init() {
        let initial = Self.currentBrightness()
        self.brightness = initial
        self.inferredScheme = initial < lightToDarkThreshold ? .dark : .light
    }

    func startObserving() { /* notification 등록 + 즉시 평가 */ }
    func stopObserving()  { /* notification 해제 */ }

    /// iOS 17+ multi-scene 환경에서 connectedScenes에서 brightness 조회
    static func currentBrightness() -> Double { /* ... */ }
}
```

**중요**: iOS 17.0에서 `UIScreen.main`은 multi-scene 환경에서 비권장이다. 프로젝트는 `UIApplicationSupportsMultipleScenes: true`이므로 다음 경로로 brightness를 조회한다:

```swift
static func currentBrightness() -> Double {
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    return Double(scene?.screen.brightness ?? 0.5)
}
```

#### AppearanceViewModel

`strategy`와 `AmbientLightObserver.inferredScheme`을 합쳐 최종 `colorScheme: ColorScheme?`을 산출. SwiftUI `.preferredColorScheme`는 `nil` 시 시스템 따라가지만, 본 기능은 사용자 선택을 우선하므로 반드시 명시 값을 내려준다.

```swift
@MainActor
@Observable
final class AppearanceViewModel {
    private let settingsRepository: SettingsRepositoryProtocol
    private let observer: AmbientLightObserver

    var strategy: DarkModeStrategy {
        didSet {
            settingsRepository.darkModeStrategy = strategy
        }
    }

    /// SwiftUI .preferredColorScheme에 그대로 주입
    var effectiveColorScheme: ColorScheme {
        switch strategy {
        case .auto:  return observer.inferredScheme
        case .light: return .light
        case .dark:  return .dark
        }
    }
}
```

## Detailed Behavior

### 영속화

`SettingsRepository`에 키 추가:

| 키 | 타입 | 기본값 |
|----|------|--------|
| `darkModeStrategy` | String (DarkModeStrategy rawValue) | `"auto"` |

기존 키와 충돌하지 않도록 prefix 컨벤션 따른다.

### Notification 라이프사이클

- 앱 scene이 `.active`로 진입 시: `observer.startObserving()`
- `.background` 진입 시: `observer.stopObserving()` (NotificationCenter 누수 방지)

`HoguMeterApp.swift`의 `.onChange(of: scenePhase)`에서 처리한다.

### 첫 평가 타이밍

`AmbientLightObserver.init` 시 즉시 한 번 평가하므로, 화면이 처음 그려질 때 이미 올바른 모드가 적용되어 있다. (깜빡임 없음)

## Edge Cases

1. **첫 실행**: strategy 기본값 `.auto`. 현재 brightness로 즉시 평가하므로 깜빡임 없음.
2. **사용자가 수동 슬라이더로 화면 밝기 조절**: 동일하게 반응. "사용자가 어두운 곳에 있다고 표현한 의도"로 해석.
3. **자동 밝기 OFF**: brightness가 ambient에 반응 안 함. 사용자가 자동 모드 선택 시 1회 안내 (위 UX 섹션 참고).
4. **외부 디스플레이/Mirroring**: 호구미터는 iPhone 전용이고 Mac Catalyst 미지원이므로 무시.
5. **시스템 다크모드 변경**: 본 기능이 명시 값을 우선 적용하므로 시스템 변경은 무시된다. (사용자가 라이트/다크를 명시 선택했다는 의도 존중)
6. **brightness 0.0 또는 1.0 경계값**: hysteresis 임계 비교가 `<`, `>`이므로 경계는 안전.
7. **앱 background 중 brightness 변화**: notification이 안 옴. 복귀 시 `.active` 진입에서 `startObserving()`이 즉시 재평가.

## Testing

### Unit Tests

#### `AmbientLightObserverTests`
- `init(brightness: 0.2)` → `inferredScheme == .dark`
- `init(brightness: 0.5)` → `inferredScheme == .light`
- light 상태에서 brightness가 0.40으로 떨어져도 유지 (hysteresis)
- light 상태에서 brightness가 0.29로 떨어지면 dark
- dark 상태에서 brightness가 0.35로 올라가도 유지
- dark 상태에서 brightness가 0.46으로 올라가면 light

테스트 가능성을 위해 임계값 / brightness 입력을 외부 주입 가능하도록 설계.

#### `AppearanceViewModelTests`
- strategy=auto, observer.inferredScheme=.dark → effectiveColorScheme=.dark
- strategy=light → observer 값 무관하게 .light
- strategy=dark → observer 값 무관하게 .dark
- strategy 변경 시 SettingsRepository에 영속화 호출 확인

### Manual QA

1. iPhone 자동 밝기 ON, 손바닥으로 ambient 센서 가리기 → 다크 전환
2. 손바닥 떼기 → 라이트 전환 (1~2초 내)
3. 자동 밝기 OFF, 화면 밝기 슬라이더 수동 조작 → 즉시 반응
4. 라이트 고정 모드에서 brightness 변화 시 무반응 확인
5. 다크 고정 모드에서 brightness 변화 시 무반응 확인
6. 앱을 백그라운드로 보냈다가 복귀 → 현재 brightness에 맞게 즉시 재평가
7. 영수증 캡쳐가 다크모드에서 깨지지 않는지 (특히 흰 배경 가정 코드)
8. 면책 마키 텍스트 가독성
9. 말 애니메이션 색·이펙트가 다크 배경에서 자연스러운지

## Open Questions

1. **자동 모드 첫 선택 시 안내 UI 형태**: 1회성 토스트 vs 영구 hint Text vs 안내 sheet. → 1회성 토스트 + UserDefaults `didShowAmbientDarkModeHint` 권장.
2. **모드 전환 시 햅틱 피드백**: 라이트↔다크 전환에 가벼운 진동(`UIImpactFeedbackGenerator.light`) 줄지? → 잦은 전환 시 거슬릴 가능성. 기본 OFF, 설정 옵션 별도.
3. **TimeOfDayBackgroundView 같은 시간대 시각화 기능과의 결합**: 다크모드일 때 시간대 분위기 배경의 톤도 더 어둡게 동적 조정할지. → 별도 후속 task로 분리.
4. **영수증/공유 이미지의 색 스킴**: 영수증 이미지는 항상 라이트 톤 고정이 자연스러움. 다크모드에서도 영수증 캡쳐는 라이트로 강제할지 확정 필요.

## Risks

- `UIScreen.brightness`는 사용자가 자동 밝기를 끄면 ambient 신호가 아니라 사용자 의도 신호가 된다. 이는 SPEC 한계이며 사용자가 알 수 있게 안내해야 한다.
- 깜빡임 방지 hysteresis 임계값(0.30/0.45)은 합리적 추정값이다. 실기기 QA에서 조정 가능.
- 영수증/지도/말 애니메이션 등 기존 화면이 라이트 가정으로 색상을 하드코딩하고 있다면 다크모드에서 시각 회귀가 발생할 수 있다. Phase 6 QA에서 반드시 확인.
