# CODE REVIEW

- phase: `20260729-HOGU-NAVIGATION`
- reviewer: `CODE_REVIEWER`
- reviewed_at: `2026-07-29 10:24 KST`
- scope: 요구사항 HTML/첨부 화면, `HEAD` 대비 전체 미커밋 diff, LOOP handoff 문서
- verification: 정적 diff 검토 및 `git diff --check` 통과. 빌드·테스트·커밋·푸시는 역할 범위상 실행하지 않음.

## 판정

`NEEDS_FIX / DEVELOPER`

요구사항 1·6·7의 UI 구조와 요구사항 4·5의 누적 모델은 구현되었습니다. 그러나 요구사항 2~5의 기준 데이터인 경로 진행률/이탈 판정이 경로 **선분**이 아닌 꼭짓점만 사용합니다. 실제 도로 선 위에 있어도 긴 선분의 중간에서는 90m/120m 경계를 넘을 수 있어, 안내·남은 거리/시간/예상 호구비 갱신이 멈추거나 불필요한 재탐색이 발생합니다. 수정 전 QA로 넘길 수 없습니다.

## 발견사항

### P1 — 경로 선분 중간에서 정상 주행을 이탈로 판정하고 실시간 갱신을 멈춤

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:724-727, 898-916, 1224-1263`
- 영향: `nearestRouteDistance`는 polyline 꼭짓점까지의 거리만 최소값으로 계산하고, `routeProgressDistance`도 가장 가까운 꼭짓점까지 누적합니다. MapKit polyline에 긴 선분이 있으면 차량이 실제 선 위에 있어도 꼭짓점에서 90m 이상 떨어질 수 있습니다. 그 결과 차량 표시만 선분 투영으로 스냅되는 반면, ViewModel은 (a) 다음 회전/거리, 남은 거리·시간·예상 호구비 갱신을 중단하고, (b) 3회 누적 후 재탐색을 요청합니다. 요구사항 2, 3, 4, 5를 직접 위반합니다.
- 권고: 단일 선분 투영 헬퍼를 ViewModel의 이탈 거리·진행 거리 계산에 공통 적용하십시오. 각 선분의 투영점, 선분까지의 거리, 해당 선분 시작 누적거리 + 선분 비율을 반환해야 합니다. UI의 `HoguNavigationMapView.routeSnap`과 계산식을 중복하지 말고 공유 가능한 순수 타입/헬퍼로 추출하십시오. 90m/120m 경계, 긴 직선 중간, 교차/평행 도로, 역방향 GPS 튐을 단위 테스트로 고정하십시오.

### P2 — 최근 경로 선택 동작 회귀

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:318-338`
- 영향: 기존에는 최근 경로 선택 시 저장한 출발/도착을 함께 복원하고 즉시 경로를 계산했습니다. 변경 후에는 선택된 입력칸에 최근 경로의 **도착지만** 넣고, 출발지·자동 계산을 버립니다. 출발지 입력칸에서 선택하면 도착지를 출발지로 넣는 잘못된 경로가 됩니다. 요구사항 범위 밖이지만 기존 핵심 탐색 흐름 회귀입니다.
- 권고: `.route`는 기존처럼 저장된 출발/도착을 원자적으로 복원 후 계산하거나, 입력칸별 최근 장소와 최근 경로를 UI에서 명확히 분리하십시오. origin/destination 각각의 선택 회귀 테스트를 추가하십시오.

### P2 — GPS course 무효 상태에서 차량 heading이 이전 값(초기값 0도)으로 고정 가능

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:683-690`, `HoguMeter/Presentation/Views/HoguNavigation/HoguNavigationView.swift:981-992`
- 영향: `heading(from:)`은 `course < 0`이면 이전 `userHeading`을 반환합니다. 이후 UI는 속도 5km/h 이상이면 `userHeading`이 유효하다고 간주해 선분 heading fallback을 건너뜁니다. 초기값 `0`도 유효로 취급되어, course가 잠시 무효인 이동 중 차량 아이콘/카메라가 북쪽을 보는 상태가 발생할 수 있습니다. 요구사항 3의 진행 방향 정확성을 훼손합니다.
- 권고: `CLLocation.course`의 유효성 상태를 별도로 전달하거나, 최근 유효 course 타임아웃을 적용하십시오. course가 무효/오래됐으면 속도와 무관하게 경로 선분 heading을 사용하십시오. `course == -1`, 정지 후 출발, 방향 전환 케이스 테스트를 추가하십시오.

### P2 — 재시작 뒤 재탐색 쿨다운이 이전 주행에서 누수

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:420-447, 459-462, 749-756`
- 영향: `resetRouteTrackingState()`가 `lastRerouteAt`을 초기화하지 않습니다. 안내를 종료한 뒤 45초 안에 새 안내를 시작하면 이전 주행의 재탐색 시각 때문에 새 주행의 유효한 이탈 재탐색이 막힙니다.
- 권고: 주행 시작/종료와 새 경로 계산의 상태 경계를 정의하고, 새 세션에서는 `lastRerouteAt`을 초기화하십시오. 동일 세션의 45초 debounce만 유지하도록 테스트하십시오.

### P2 — 회귀 방지 테스트 부재

- 파일/줄: `HoguMeterTests/` (호구게이션 전용 테스트 없음), `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:714-990`
- 영향: 이번 변경의 GPS 진행률, 요금 누적, reroute, tab bar 복원, heading/camera offset을 자동으로 검증하는 테스트가 없습니다. 정적 검토만으로 실제 GPS/MapKit 조건의 완료 판정을 할 수 없습니다.
- 권고: 순수 경로 투영/진행/누적 비용 계산을 테스트 가능한 타입으로 분리하고, 아래를 최소 단위/UI 테스트로 추가하십시오: 실시간 거리·시간·예상총비용 감소/유지, reroute 후 누적 보존, 90m snap·120m 이탈 경계, 긴 선분, course 무효, 시작/종료와 탭 숨김·복원. 이후 정상 Simulator/실기기 GPS 시뮬레이션 QA를 수행하십시오.

## 요구사항 추적

1. 차량 기준점 하단 이동: 구현 근거 있음 — camera focus를 진행방향 전방으로 28% 이동 (`HoguNavigationView.swift:848-858`). 실기기 시각 QA 필요.
2. 다음 회전/거리 실시간 갱신: 구현 시도 있음. P1 때문에 신뢰 불가.
3. 차량 route snap/heading: UI 선분 snap 구현 있음 (`HoguNavigationView.swift:976-1020`). P1/P2 때문에 전체 충족 불가.
4. 남은 거리·시간·예상 호구비 실시간 갱신: 누적 모델 구현 있음 (`HoguNavigationViewModel.swift:931-967`). P1 때문에 신뢰 불가.
5. reroute 시 누적 이동비용 보존: 누적 이월 구현 있음 (`HoguNavigationViewModel.swift:794-823`). P1 때문에 경계조건 검증 불가.
6. 하단 tab 숨김/복원: 시작/종료 알림과 작은 복원 컨트롤 구현 있음 (`ContentView.swift:85-95`, `HoguNavigationView.swift:467-480`). UI QA 필요.
7. 상단 title hide: 주행 중 navigation bar hide 구현 있음 (`HoguNavigationView.swift:119-121`). UI QA 필요.

## 범위 외 변경

- `HoguMeter/Domain/Services/SpeedCameraAPIClient.swift`: 응답 `items` 누락/문자열 처리 완화. 이번 요구사항과 별개. 되돌리지 않았습니다.
- `HoguMeter/Info.plist`: `INIntentsSupported` 추가. 이번 요구사항과 별개. 되돌리지 않았습니다.
- `HoguMeter/Presentation/Views/Main/MainMeterView.swift`, `docs/hogu-navigation-speed-camera-preview.html`: 문구 변경. 이번 요구사항의 핵심 구현과 별개. 되돌리지 않았습니다.

## 수정 후 필수 재검토

1. 선분 투영 기반 진행/이탈 계산의 단위 테스트 통과.
2. reroute 누적 거리/시간/예상 총비용 보존 테스트 통과.
3. 최근 경로 선택 회귀 테스트 통과.
4. 정상 Simulator 또는 실기기에서 GPS 주행, heading, camera vertical offset, tab/title hide·복원 시각 QA.

---

## Round 2 — FIX Round 1 재검토

- reviewed_at: `2026-07-29 10:30 KST`
- verification: `HEAD` 대비 현재 diff 및 `DEV_HANDOFF.md` FIX Round 1 정적 검토. `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 기존 지적 확인

- 이전 P1 선분 투영 누락: `HoguNavigationRouteProjector`가 선분 투영·누적 진행거리·heading을 계산하고, 이탈 판정/안내/속도카메라 전방거리/overlay/차량 snap에 연결되었습니다. 구현 방향과 단위 테스트 타깃 포함(`HoguMeterTests.swift in Sources`)은 확인했습니다.
- 이전 P2 최근 경로 선택: 저장된 출발지·목적지를 복원하고 `calculateRoute()`를 호출하도록 복구되었습니다.
- 이전 P2 GPS course: `hasUsableCourse`를 분리해 course 무효/저속 시 선분 heading fallback을 사용하도록 수정되었습니다.
- 이전 P2 reroute cooldown: 새 안내/종료/입력변경/새 경로 계산은 cooldown을 초기화하고, reroute 성공 뒤에는 유지하도록 구분되었습니다.
- 이전 P2 테스트 부재: 긴 선분 중간·120m 이탈 경계 테스트 2건이 기존 `HoguMeterTests` target의 `HoguMeterTests.swift in Sources`에 포함된 것을 확인했습니다. 다만 실행은 QA 단계에서 필요합니다.

### P1 — optional `routePreview`를 non-optional 인자로 전달해 컴파일 불가

- 파일/줄: `HoguMeter/Presentation/Views/HoguNavigation/HoguNavigationView.swift:792-799, 823-831, 956-966, 987-1007`
- 영향: `HoguNavigationMapView.routePreview`의 타입은 `HoguNavigationRoutePreview?`입니다. `updateUIView`에서 `if let routePreview`로 언래핑했지만 `updateVehicleAnnotation`에는 그 값을 전달하지 않습니다. 해당 함수 내부에서는 프로퍼티 optional `routePreview`를 `snappedVehicleCoordinate(for:)`와 `vehicleDisplayHeading(for:)`의 `HoguNavigationRoutePreview` non-optional 인자에 그대로 전달합니다. Swift 컴파일러가 optional 값을 언래핑하지 못하므로 앱/테스트 타깃 빌드가 차단됩니다.
- 권고: `updateVehicleAnnotation(_:context:routePreview:)`로 non-optional preview를 명시 전달하고 `updateUIView`의 언래핑된 지역 상수를 넘기십시오. 또는 함수에서 `guard let routePreview`로 먼저 언래핑하십시오. 수정 뒤 `xcodebuild`로 실제 컴파일을 확인하십시오.

### Round 2 판정

`NEEDS_FIX / DEVELOPER`

공통 projector의 선분 계산·접근 제어(`internal` + `@testable import`)·기존 테스트 타깃 포함은 정적으로 적절합니다. 그러나 P1 컴파일 차단이 남아 QA로 넘길 수 없습니다. 수정 후 차량 annotation 호출부와 overlay의 같은 projection 기준, 새 테스트 실행을 다시 확인해야 합니다.

---

## Round 3 — 최종 정적 재검토

- reviewed_at: `2026-07-29 10:34 KST`
- verification: Round 2 수정 및 전체 현재 diff 정적 재검토, `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### Round 2 P1 해소 확인

- `HoguNavigationMapView.updateUIView`가 언래핑된 `routePreview`를 `updateVehicleAnnotation(_:context:routePreview:)`에 non-optional로 전달합니다 (`HoguNavigationView.swift:823-831`).
- `updateVehicleAnnotation` 및 차량 snap/heading 헬퍼의 인자가 모두 `HoguNavigationRoutePreview` non-optional로 일치합니다 (`HoguNavigationView.swift:956-1012`). optional 전달 컴파일 차단은 해소되었습니다.

### 최종 정적 확인

- 선분 projector는 이탈 판정, 안내 진행률/잔여 요약, speed-camera 전방 거리, overlay, 차량 snap/heading에 재사용됩니다.
- overlay는 projector의 `segmentIndex`/`segmentRatio`로 통과·잔여 polyline을 분리하며, 차량 annotation과 camera도 같은 언래핑된 preview를 사용합니다.
- `HoguNavigationRouteProjector`는 app target 소스(`HoguNavigationViewModel.swift`)에 포함되어 있고, 테스트는 기존 `HoguMeterTests.swift in Sources` target에 포함됩니다. `internal` 접근 수준과 `@testable import HoguMeter` 조합도 유효합니다.
- Round 1의 최근 경로 선택, course fallback, reroute cooldown 초기화 수정은 유지됩니다.
- 현재 diff에서 추가 P1/P2 또는 정적 컴파일 차단은 확인되지 않았습니다.

### 최종 판정

`READY_FOR_QA / QA`

정적 검토 통과. 단, 실제 컴파일/테스트 실행, GPS 주행·reroute 누적 예상비, 차량 snap/heading, camera vertical offset, 상단 title 및 하단 tab hide·복원은 QA가 정상 Simulator 또는 실기기에서 검증해야 합니다.

---

## USER QA FIX Round 3 재검토

- reviewed_at: `2026-07-29 10:53 KST`
- scope: camera focus `28% -> 24%`, tab bar toolbar modifier 계층/상태 단일화
- verification: 현재 diff 정적 검토 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### camera focus

- `HoguNavigationView.swift:844-860`에서 진행방향 전방 focus 거리를 camera distance의 `28%`에서 `24%`로 줄였습니다.
- 전방으로 이동한 camera center의 양을 줄이면 차량 좌표와 center의 전후 차이가 작아져 차량이 화면에서 위쪽으로 이동합니다. 사용자 요청인 “약 10px 위”와 방향이 일치하며, camera distance·pitch(58)·heading·animation·snap fallback은 변경하지 않아 다른 카메라 동작 회귀는 정적으로 확인되지 않았습니다.
- 정확한 픽셀 이동량은 기기 크기, safe area, pitch, 속도별 camera distance에 좌우되므로 USER QA 화면 확인이 최종 기준입니다.

### tab bar 상태/계층

- `ContentView`에서 tab bar modifier와 navigation visibility 상태/notification receiver가 제거되었습니다 (`ContentView.swift:10-84`). `hoguNavigationTabBarVisibilityChanged` notification도 제거되어 이중 source가 남지 않았습니다 (`Notification+Extensions.swift:10-14`).
- tab bar visibility modifier는 `HoguNavigationView`의 `NavigationView` 계층에 하나만 존재합니다 (`HoguNavigationView.swift:120-126`). 이 view는 `ContentView`의 `TabView` 선택 화면이므로 toolbar preference가 상위 tab bar에 적용되는 구조입니다.
- 주행 시작: `isNavigationStarted == true`와 local `isNavigationTabBarHidden == true`로 숨김. 작은 우하단 컨트롤: local state toggle로 보기/재숨김. 주행 종료: `isNavigationStarted == false`와 local state reset으로 복원됩니다 (`HoguNavigationView.swift:151-156, 471-483`).
- 정적 검토상 P1/P2 없음. 실제 `NavigationView`/`TabView` 렌더링과 사용자 조작은 USER QA에서 확인해야 합니다.

### 판정

`USER_QA_REQUIRED / USER`

USER QA에서 차량이 요청한 위치로 이동했는지, 주행 시작 숨김 → 작은 토글 복원/재숨김 → 안내 종료 복원이 iPhone/iPad에서 모두 동작하는지 확인 후 완료 처리하십시오.

---

## USER QA FIX Round 4 재검토 — geometry maneuver

- reviewed_at: `2026-07-29 11:16 KST`
- verification: 현재 diff/USER QA FIX Round 4 정적 검토 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 확인된 구현

- `routeGuidanceSteps`는 이전 step의 마지막 유효 segment heading과 현재 step의 첫 유효 segment heading을 비교합니다 (`HoguNavigationViewModel.swift:1002-1028`). 한 step 내부의 first/last heading을 비교하지 않으므로 “step 진입 시 회전” 기준은 올바르게 적용되었습니다.
- `startDistance`는 현재 step 전까지의 거리이고, `nextStep`도 해당 시작 거리를 기준으로 선택합니다 (`HoguNavigationViewModel.swift:1020, 1101-1113`). maneuver와 표시 거리가 같은 step 경계에 정렬됩니다.
- heading 추출은 5m 미만 중복/짧은 좌표를 건너뛰고, signed delta는 0도 북쪽 wraparound를 `[-180, 180)`로 정규화합니다 (`HoguNavigationViewModel.swift:221-223, 1041-1052`). 150도 이상은 u-turn으로 분류합니다.
- 아이콘은 카드가 문자열 재파싱 없이 `HoguNavigationManeuver.iconName`만 사용합니다 (`HoguNavigationView.swift:98-103, 680-688`).

### P2 — 방향 토큰이 없는/영문 원문에서는 geometry와 문구가 다시 불일치 가능

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:187-210`
- 영향: geometry가 의미 있는 회전이고 원문에서 방향을 인식하지 못하면 `sourceManeuver == nil`입니다. 현재 `guard let sourceManeuver ... else` 경로는 원문을 그대로 반환하면서 maneuver만 geometry 값으로 설정합니다. 예: `"양화로로 진입"` 또는 영문 `"Turn right onto ..."`가 geometry상 좌회전이면 카드 아이콘은 좌회전인데 문구는 방향을 표시하지 않거나 우회전을 유지합니다. Round 4의 문구·아이콘 단일 진실원천 목표를 충족하지 못합니다.
- 권고: geometry가 35도 이상인 경우에는 `sourceManeuver == nil`도 교정 대상으로 포함하십시오. 방향 토큰이 없는 원문에는 `"좌회전 " + roadText`처럼 geometry label을 반드시 앞에 추가하고, 영문/기타 로캘 방향 토큰도 제거 또는 원문 유지 정책을 명시하십시오. 화면 텍스트와 icon은 같은 `Guidance` 모델의 geometry maneuver로 생성되게 유지하십시오.

### P2 — geometry 경계/예외 회귀 테스트가 부족

- 파일/줄: `HoguMeterTests/HoguMeterTests.swift:46-63`, `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1002-1052`
- 영향: 현재 테스트는 heading 분류 3건과 원문 방향 충돌 1건만 검증합니다. 이전 step 마지막 segment vs 현재 step 첫 segment 경계, 350도→10도/10도→350도 wraparound, 180도 u-turn, 5m 미만 중복/짧은 좌표 fallback, 방향 토큰 없는/영문 원문, `startDistance`와 next step maneuver alignment가 고정되지 않았습니다. 이번 수정의 핵심 회귀를 차단하지 못합니다.
- 권고: heading extraction/step-boundary guidance를 순수 helper로 분리하거나 내부 접근 테스트 가능 범위로 노출해 위 케이스를 단위 테스트로 추가하십시오. 특히 step 내부 곡률과 step 경계 회전을 서로 다르게 설정한 fixture를 추가해 잘못된 first/last 비교가 재도입되지 않게 하십시오.

### Round 4 판정

`NEEDS_FIX / DEVELOPER`

step 진입 geometry 선택 자체는 올바르지만, P2 문구·아이콘 불일치 가능성과 핵심 경계 테스트 누락이 남았습니다. 수정 뒤 다시 정적 검토 후 USER QA로 전달하십시오.

---

## CODE REVIEW Round 4-2 최종 재검토

- reviewed_at: `2026-07-29 11:19 KST`
- verification: FIX Round 4-2 현재 diff/테스트 정적 검토 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 기존 P2 해소 확인

- source maneuver가 없는 영문 원문도 geometry maneuver label을 앞에 붙여 icon/text 방향 불일치를 해소했습니다 (`HoguNavigationViewModel.swift:187-210`). north wraparound와 180도 u-turn 분류, 영문 source nil, projector의 중복 좌표 진행거리 테스트도 추가되었습니다 (`HoguMeterTests.swift:52-98`).

### P2 — 영문 source nil 교정 문구가 자연스럽지 않음

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:202-210`, `HoguMeterTests/HoguMeterTests.swift:71-82`
- 영향: 영문 원문 `"Continue onto Yanghwa-ro"`의 현재 결과는 `"우회전 Continue onto Yanghwa-ro"`입니다. 방향은 icon과 일치하지만 한국어 길안내 카드로는 문법상 부자연스럽고, 이번 검토 기준의 자연스러운 문구를 충족하지 못합니다. 테스트도 방향 토큰/도로명 존재만 확인하므로 이 품질 저하를 허용합니다.
- 권고: 영문/방향 토큰 없는 원문에는 구분자 또는 한국어 템플릿을 적용하십시오. 예: `"우회전 · Continue onto Yanghwa-ro"`처럼 의미 단위를 구분하거나, 안전한 경우 `"우회전 후 Yanghwa-ro로 진입"`으로 정규화하십시오. 한국어/영문 source nil 각각의 정확한 최종 문자열을 테스트로 고정하십시오.

### P2 — 핵심 step 경계 및 표시 거리 정렬 테스트는 여전히 없음

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1002-1052, 1101-1113`, `HoguMeterTests/HoguMeterTests.swift:46-98`
- 영향: 추가된 중복 좌표 테스트는 `HoguNavigationRouteProjector`만 검증합니다. Round 4 핵심인 “이전 step 마지막 유효 segment vs 현재 step 첫 유효 segment” heading extraction, step 내부 곡률을 무시하는지, 그리고 그 current step의 `startDistance`가 `nextStep`의 안내 거리/카드 maneuver에 그대로 연결되는지는 테스트하지 않습니다. 따라서 first/last를 같은 step에서 다시 비교하는 회귀나 안내 거리와 icon이 다른 step을 가리키는 회귀를 막지 못합니다.
- 권고: step 경계 heading 산출과 guidance step 생성을 순수 helper로 추출하고, (1) 이전 step 종료는 북향, 현재 step 진입은 서향·내부 후반 곡률은 다른 방향인 fixture, (2) 5m 미만/중복을 포함한 boundary fixture, (3) `startDistance - progressDistance`와 선택된 maneuver의 일치 fixture를 추가하십시오.

### Round 4-2 판정

`NEEDS_FIX / DEVELOPER`

새 컴파일 차단/P1은 확인되지 않았습니다. 그러나 자연스러운 영문 안내와 step 경계 정렬 회귀 테스트가 P2로 남아 USER QA 전달 전 보완이 필요합니다.

---

## CODE REVIEW Round 4-3 최종 재검토

- reviewed_at: `2026-07-29 11:21 KST`
- verification: FIX Round 4-3 현재 diff/테스트 정적 검토 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 해소 확인

- 영문/무방향 ASCII 원문은 geometry label만 반환합니다. `"Continue onto Yanghwa-ro"` + 북향→동향은 정확히 `"우회전"`과 `.right` icon으로 고정되었습니다 (`HoguNavigationViewModel.swift:202-213`, `HoguMeterTests.swift:71-81`). 혼합 언어 문구는 제거되었습니다.
- `HoguNavigationStepBoundaryResolver`는 이전 step 마지막 유효 선분과 현재 step 첫 유효 선분만 사용합니다 (`HoguNavigationViewModel.swift:229-259`). 테스트 fixture는 중복과 5m 미만 좌표를 건너뛰고 current step 후반 내부 곡률을 배제하는 것을 확인합니다 (`HoguMeterTests.swift:99-116`).
- 사용자 보고 사례를 직접 추적했습니다. 북상(0도) → 서쪽(270도)은 signed delta `-90`으로 `.left`; 원문 `"완만히 우회전하여 양화로로 진입"`은 `"좌회전 양화로로 진입"`과 `arrow.turn.up.left`로 귀결됩니다 (`HoguNavigationViewModel.swift:175-213`, `HoguMeterTests.swift:58-69`, `HoguNavigationView.swift:98-103, 680-688`).
- north wrap/u-turn/중복 좌표/영문 fallback은 테스트로 보강됐고, 새 P1 또는 정적 컴파일 차단은 확인되지 않았습니다.

### P2 — startDistance/next-step/card maneuver 정렬 회귀 테스트 미포함

- 파일/줄: `HoguNavigationViewModel.swift:1037-1062, 1114-1126`, `HoguMeterTests/HoguMeterTests.swift:99-116`
- 영향: 경계 helper 테스트는 maneuver 분류만 확인합니다. 실제 주행 중 사용하는 `HoguNavigationRouteStep.startDistance`, `nextStep` 선택 조건(`startDistance > progress + 25`), `upcomingRouteInstructionDistance`, `upcomingRouteManeuver`가 같은 current step을 가리키는지 검증하지 않습니다. 따라서 다음 step의 icon/text와 거리 값이 다른 step에 붙는 회귀를 자동으로 차단하지 못합니다.
- 권고: guidance step 선택을 순수 helper로 추출하고, 여러 step fixture에서 progress가 첫/둘째 step 경계 전후일 때 선택된 instruction/maneuver와 `startDistance - progress`가 함께 일치하는 테스트를 추가하십시오. 25m look-ahead 경계도 포함하십시오.

### Round 4-3 판정

`NEEDS_FIX / DEVELOPER`

문구, geometry 경계, 아이콘 SSOT은 통과했습니다. 마지막 P2인 startDistance/next-step/card 정렬 회귀 테스트를 보강한 뒤 USER QA로 전달하십시오.

---

## CODE REVIEW Round 4-4 최종

- reviewed_at: `2026-07-29 11:23 KST`
- verification: FIX Round 4-4 현재 diff/테스트 정적 검토 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 마지막 P2 해소 확인

- `HoguNavigationGuidanceSelector.nextStep`가 `startDistance > progressDistance + 25` 선택 규칙을 단일 helper로 고정했습니다 (`HoguNavigationViewModel.swift:261-268`).
- `updateRouteGuidance`는 helper가 반환한 단일 `HoguNavigationRouteStep`에서 instruction, `startDistance - progress` 거리, maneuver를 함께 published state에 적용합니다 (`HoguNavigationViewModel.swift:1124-1136`). 서로 다른 step의 문구·거리·아이콘을 조합하는 경로가 없습니다.
- 테스트는 progress 74m에서 첫 step(100m)을, 75m 경계에서 다음 step(160m)을 선택하는 strict `>` 규칙과 각 step의 instruction/maneuver/거리 값을 함께 확인합니다 (`HoguMeterTests.swift:118-147`).

### 사용자 보고 사례 최종 추적

- 북상 0도 → 서쪽 270도: signed delta `-90`, `.left`.
- 원문 `"완만히 우회전하여 양화로로 진입"`: geometry 충돌 교정 후 `"좌회전 양화로로 진입"`, `.left`.
- 카드: 같은 maneuver의 `arrow.turn.up.left` icon을 사용.
- 문구·아이콘·회전 geometry가 모두 좌회전으로 일치합니다.

### 최종 판정

`USER_QA_REQUIRED / USER`

정적 P1/P2 및 컴파일 차단 없음. 정상 Simulator 또는 실기기에서 실제 MapKit step/GPS 주행으로 문구·아이콘·거리, camera 위치, tab bar hide/restore를 사용자 검증 후 완료 처리하십시오.

---

## Thermal Round 1-B — shared location stream 정적 재검토

- reviewed_at: `2026-07-29 11:44 KST`
- scope: `HOGU-NAVIGATION-THERMAL-OPTIMIZATION` Phase B incremental patch
- verification: 현재 diff, `HOGU_NAVIGATION_THERMAL_OPTIMIZATION.md`, LOOP 문서 및 위치/미터 lifecycle 정적 검토. `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 확인된 사항

- `HoguNavigationViewModel`은 안내 시작 뒤 자체 `CLLocationManager.startUpdatingLocation()`을 호출하지 않고, `MeterViewModel.locationService.locationPublisher`를 구독합니다. `LocationService`만 연속 `startUpdatingLocation()`을 보유하므로 주행 중 앱 소유 연속 manager는 정적으로 1개입니다.
- 검색·출발지 선택용 navigation manager는 `requestLocation()`만 사용합니다. preview의 현재 위치 선택 흐름은 유지됩니다.
- `stopNavigation()`은 shared Combine 구독을 취소한 뒤 미터 stop notification을 보내며, 종료 뒤 nav callback이 살아남는 누수는 정적으로 확인되지 않았습니다. sink의 `[weak self]`도 적절합니다.
- 미터는 기존 `LocationService` publisher를 계속 구독하므로 요금 계산, 경로 기록, 무이동·GPS 신호 처리는 같은 `CLLocation` 이벤트를 사용합니다.

### P2 — 미터 시작 notification이 navigation 구독보다 먼저 발생해 첫 위치 이벤트를 놓칠 수 있음

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:622-629`, `HoguMeter/Presentation/Views/Main/MainMeterView.swift:190-197`, `HoguMeter/Domain/Services/LocationService.swift:33-35, 142-166`
- 영향: `startNavigationFromPreview()`는 `.hoguNavigationDidStart`를 먼저 post합니다. `MainMeterView`가 동기적으로 `startMeter()` → `LocationService.startTracking()`을 수행하고, 그 뒤에야 navigation의 `PassthroughSubject` sink가 설치됩니다. publisher에는 replay/buffer가 없으므로 이 사이에 도착한 첫 위치는 미터에는 전달되지만 길안내에는 유실됩니다. 후속 위치로 회복될 수 있으나 첫 안내·차량 표기·이탈 판단의 지연은 허용하면 안 됩니다.
- 권고: `isNavigationStarted`와 route state를 먼저 설정한 뒤 shared publisher sink를 설치하고, 그 다음 `.hoguNavigationDidStart`를 post하십시오. 가능하면 기존 cancellable을 명시 취소한 뒤 재설치하십시오. 위치 stream을 replay하지 않는 현재 계약을 유지한다면 이 순서가 필수입니다.

### P2 — one-shot callback의 start 전 guard가 main-queue 전달 시점에는 재검사되지 않아 navigation 후 중복 처리 가능

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:855-867, 870-884`
- 영향: `didUpdateLocations`가 navigation 시작 직전에 실행되면 `guard !isNavigationStarted`를 통과한 뒤 `DispatchQueue.main.async`로 `handleLocation`을 예약합니다. 그 사이 navigation이 시작되면 예약된 one-shot 위치도 안내 분기로 실행되고, 이어서 shared location stream의 같은/새 위치가 다시 처리됩니다. 이는 “navigation 시작 뒤 one-shot callback 무시” 목표를 만족하지 못하며 stale 위치로 reroute·안내를 한 번 갱신할 수 있습니다.
- 권고: async block 내부에서 `guard !self.isNavigationStarted else { return }`를 다시 확인한 후 one-shot origin 처리만 수행하십시오. one-shot과 shared stream의 입력 경로를 분리하면 의도를 더 명확히 고정할 수 있습니다.

### 테스트 공백

- 현재 `HoguMeterTests.swift`의 8개 신규 테스트는 projector/maneuver/guidance selector 회귀만 다룹니다. shared publisher 구독이 notification보다 먼저 설치되는 순서, navigation 시작 직후 one-shot callback 무시, stop→restart 시 단일 subscription, 미터 요금·route recording의 동일 이벤트 처리 계약을 검증하는 테스트가 없습니다.
- 권고: 주입 가능한 subject와 meter spy 또는 순수 lifecycle helper를 사용해 위 순서·중복 방지 케이스를 unit test로 고정하고, QA에서 실기기 GPS로 시작/종료/재시작을 확인하십시오.

### Round 1-B 판정

`NEEDS_FIX / DEVELOPER`

연속 CLLocationManager 단일화와 cancellation 방향은 맞습니다. 다만 start 순서와 one-shot callback 경합을 보완하고 lifecycle 회귀 테스트를 추가한 뒤 재검토해야 합니다.

---

## Thermal Round 1-B Fix 재검토

- reviewed_at: `2026-07-29 11:46 KST`
- verification: FIX diff 및 `HoguMeterTests` 정적 재검토, `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 기존 경합 해소 확인

- `startNavigationFromPreview()`가 shared publisher sink를 설치한 뒤 `.hoguNavigationDidStart`를 post합니다 (`HoguNavigationViewModel.swift:623-631`). 따라서 `MainMeterView`가 notification 처리 중 `startMeter()`로 `LocationService`를 시작해도 navigation subscriber가 먼저 존재하며, replay 없는 `PassthroughSubject`의 첫 위치 유실 경로는 해소됐습니다.
- `locationSessionGeneration`은 navigation start/stop마다 증가하고, one-shot delegate callback은 main queue 실행 시점에 `!isNavigationStarted`와 generation 일치를 재확인합니다 (`HoguNavigationViewModel.swift:623-625, 640-645, 858-874`). start 직전 예약된 callback과 stop→restart 이전 callback은 현재 session에서 `handleLocation`으로 진입하지 않습니다.
- stop 시 subscription cancel 후 nil 처리도 유지되어 종료 후 nav subscriber 누수는 정적으로 확인되지 않았습니다. 재시작에서 property 재대입은 이전 `AnyCancellable` 해제로 기존 subscription을 취소합니다.

### P2 — 요구된 start/stop/restart lifecycle 테스트가 추가되지 않음

- 파일/줄: `HoguMeterTests/HoguMeterTests.swift:12-149`
- 영향: 테스트 파일에는 projector/maneuver/guidance selector 8건만 있으며, 이번 Fix의 핵심인 (1) subscriber 설치 후 meter start notification, (2) start 직전 one-shot의 delayed callback 무시, (3) stop 후 shared event 미수신, (4) restart 후 새 session만 단일 수신을 검증하는 테스트가 없습니다. 구현 의도는 정적으로 맞지만, 비동기 순서·cancellation 회귀를 자동으로 차단할 수 없습니다.
- 권고: 주입한 `PassthroughSubject<CLLocation, Never>` 및 notification observer/counting sink 또는 테스트 가능한 lifecycle helper로 위 4개 시나리오를 unit test로 고정하십시오. 특히 generation 값이 다른 delayed one-shot callback과 restart 뒤 publisher event를 분리해 검증하십시오.

### Round 1-B Fix 판정

`NEEDS_FIX / DEVELOPER`

앞선 두 구현 P2는 해소됐습니다. 다만 명시된 lifecycle 테스트가 실제 target에 없으므로 추가 후 재검토가 필요합니다.

---

## Thermal Round 1-B Fix2 최종 재검토

- reviewed_at: `2026-07-29 11:47 KST`
- verification: production policy/seam, lifecycle test 3건, Xcode test target 등록을 정적 검토하고 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 확인된 사항

- `HoguMeterTests.swift`는 `HoguMeterTests` target의 Sources에 등록되어 있습니다 (`HoguMeter.xcodeproj/project.pbxproj:133, 1079`). `@testable import HoguMeter` 및 새 helper의 internal 접근 수준도 정적으로 컴파일 가능한 형태입니다.
- 새 테스트는 start generation 발급, start→stop→start stale generation 차단, stop 뒤 동일 generation 차단을 각각 확인합니다 (`HoguMeterTests.swift:149-169`). helper 자체의 generation 규칙은 일관됩니다.

### P2 — lifecycle helper가 production policy와 분리되어 테스트가 실제 구현을 검증하지 못함

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:272-280, 633-641, 650-655, 868-884`; `HoguMeterTests/HoguMeterTests.swift:149-169`
- 영향: 새 `HoguNavigationLocationSessionGate`는 테스트에서만 사용됩니다. 실제 `HoguNavigationViewModel`은 별도 `Int locationSessionGeneration`을 직접 증감·비교하고 helper의 `start()`, `stop()`, `acceptsOneShot(...)`를 전혀 호출하지 않습니다. 따라서 테스트가 통과해도 production의 subscribe-before-notification 순서, one-shot acceptance condition, stop/restart invalidation이 변경·회귀해도 검출하지 못합니다. 또한 추가된 것은 4개가 아닌 3개 테스트이며 shared publisher cancellation/재구독을 직접 관찰하지 않습니다.
- 권고: production property를 `HoguNavigationLocationSessionGate`로 교체하고 start/stop/callback에서 helper를 직접 호출하십시오. 이후 테스트에는 notification observer 또는 publisher spy를 추가해 sink 설치가 post보다 앞서는지, stop 뒤 event가 전달되지 않는지, restart 뒤 새 subscription만 1회 수신하는지를 실제 ViewModel lifecycle 또는 동일 production seam으로 검증하십시오.

### Round 1-B Fix2 판정

`NEEDS_FIX / DEVELOPER`

test target 등록과 helper 문법은 적절하지만, production과 분리된 테스트라 lifecycle 회귀 보증으로 인정할 수 없습니다.

---

## Thermal Round 1-B Fix3 최종 재검토

- reviewed_at: `2026-07-29 11:49 KST`
- verification: production gate SSOT 연결, lifecycle tests, shared publisher lifecycle을 정적 검토하고 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### Fix2 P2 해소 확인

- `HoguNavigationViewModel`이 별도 generation `Int`를 제거하고 `HoguNavigationLocationSessionGate`를 실제 상태로 소유합니다 (`HoguNavigationViewModel.swift:378-380`). start/stop/callback 모두 production gate의 `start()`, `stop()`, `generation`, `acceptsOneShot(...)`를 사용합니다 (`HoguNavigationViewModel.swift:633-655, 868-887`).
- 따라서 새 gate tests는 delayed one-shot 및 stop→restart stale generation invalidation이라는 production 정책을 직접 검증합니다. 테스트 파일은 test target Sources 등록도 유지됩니다.
- shared sink 설치는 계속 notification post보다 앞서며, stop에는 explicit cancel/nil이 있습니다 (`HoguNavigationViewModel.swift:638-641, 650-655`). 구현 순서 자체는 적절합니다.

### P2 — shared publisher cancellation 및 start→stop→start 단일 수신을 자동 검증하지 않음

- 파일/줄: `HoguMeterTests/HoguMeterTests.swift:149-169`; `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:633-655`
- 영향: 세 lifecycle test는 gate의 one-shot acceptance만 다룹니다. `AnyCancellable`의 cancel 뒤 publisher event가 nav에 전달되지 않는지, restart 후 새 subscription 하나만 event를 받는지, subscriber 설치가 `.hoguNavigationDidStart` notification보다 먼저인지에는 subject/observer 기반 검증이 없습니다. 이 부분은 이번 thermal patch에서 실제로 위치 manager 단일화와 중복 안내를 보장하는 핵심이라, code ordering만으로 회귀 방지가 충분하지 않습니다.
- 권고: `PassthroughSubject<CLLocation, Never>`를 주입한 ViewModel lifecycle test를 추가해 (1) notification observer에서 subject를 send했을 때 첫 event가 nav로 도달하는지, (2) stop 뒤 send가 처리되지 않는지, (3) start→stop→start 뒤 event가 정확히 한 번만 처리되는지를 카운터/observable state로 고정하십시오.

### Round 1-B Fix3 판정

`NEEDS_FIX / DEVELOPER`

production gate SSOT와 one-shot stale callback 보장은 통과했습니다. shared publisher cancellation/restart를 실제로 검증하는 테스트를 추가한 뒤 PASS할 수 있습니다.

---

## Thermal Round 1-B Fix4 최종 재검토

- reviewed_at: `2026-07-29 11:51 KST`
- verification: production subscription coordinator, `PassthroughSubject` tests, retain-cycle/lifecycle 정적 검토 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### Fix3 P2 해소 확인

- production `HoguNavigationSharedLocationSubscription`이 publisher와 cancellable을 소유하고, ViewModel이 `startNavigationFromPreview`/`stopNavigation`에서 같은 coordinator의 `start()`/`stop()`을 호출합니다 (`HoguNavigationViewModel.swift:282-303, 660-689`). 중복 start는 guard로 막고 stop은 cancel/nil 처리하며 deinit도 stop합니다.
- coordinator sink와 ViewModel callback은 모두 `[weak self]`를 사용해 `ViewModel -> coordinator -> closure -> ViewModel` retain cycle을 만들지 않습니다 (`HoguNavigationViewModel.swift:294, 443-445`).
- `PassthroughSubject` tests 3건은 start 직후 수신, stop 후 새 이벤트 미수신, stop→restart 및 중복 start 후 1회 수신을 production coordinator에 대해 검증합니다 (`HoguMeterTests.swift:172-197`). subscriber start가 notification post보다 앞서는 production 순서도 유지됩니다.

### P2 — 이미 main queue에 예약된 shared callback은 stop/restart 뒤에도 처리될 수 있음

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:443-445, 660-689`; `HoguMeterTests/HoguMeterTests.swift:181-197`
- 영향: coordinator는 publisher 이벤트를 받으면 `onLocation`에서 `DispatchQueue.main.async`로 `handleLocation`을 예약합니다. 이벤트 수신 직후 `stopNavigation()` 또는 start→stop→start가 일어나면 `stop()`의 cancel은 미래 publisher event만 막고 이미 예약된 main-queue closure는 취소하지 못합니다. 해당 closure에는 session generation/isNavigation guard가 없어 종료 뒤 origin 상태를 갱신하거나 재시작 뒤 이전 session 위치로 안내·이탈 판단을 수행할 수 있습니다. one-shot에는 이미 같은 종류의 delayed callback guard가 있으므로 shared stream도 동등하게 보호해야 합니다.
- 권고: shared callback을 enqueue할 때 현재 gate generation을 capture하고 main queue block에서 현재 generation 및 `isNavigationStarted`를 재검사하십시오. 또는 coordinator가 main scheduler delivery/cancellable을 소유하도록 해 stop 시 pending delivery까지 무효화하십시오. 테스트는 `subject.send` 직후 즉시 stop/restart한 뒤 main queue drain을 거쳐 stale event가 0회 처리되는지를 추가해야 합니다.

### Round 1-B Fix4 판정

`NEEDS_FIX / DEVELOPER`

coordinator, cancellation, duplicate subscription, weak capture 및 기본 subject tests는 적절합니다. 다만 queued shared callback의 stale session 경합을 해소·검증해야 PASS할 수 있습니다.

---

## Thermal Round 1-B Fix5 재검토

- reviewed_at: `2026-07-29 11:53 KST`
- verification: token/generation coordinator와 suspended queue test를 정적 검토, `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### queued stale callback 구현 확인

- `HoguNavigationSharedLocationSubscription`은 start/stop마다 token을 변경하고, delivery queue block에서 active cancellable 및 token 일치를 확인합니다 (`HoguNavigationViewModel.swift:282-315`). stop→restart 전에 queue에 쌓인 old token callback은 새 session에서 실행되지 않습니다.
- suspended serial queue test는 old event를 queue에 보류한 뒤 stop→start와 새 event를 수행하여 old callback을 배제하고 새 callback 1회만 전달되는 정책을 의도대로 다룹니다 (`HoguMeterTests.swift:199-215`).

### P1 — test target에 `Combine` import가 없어 `PassthroughSubject` 컴파일 불가

- 파일/줄: `HoguMeterTests/HoguMeterTests.swift:8-10, 173, 182, 191, 200`
- 영향: 테스트 파일은 `Testing`, `CoreLocation`, `@testable import HoguMeter`만 import합니다. `PassthroughSubject`는 Combine 타입이고 app target의 import는 test module에 전파되지 않으므로 식별자를 찾지 못해 test target 컴파일이 중단됩니다.
- 권고: `HoguMeterTests.swift`에 `import Combine`을 추가하고 실제 test target 컴파일을 QA에서 확인하십시오.

### P2 — 기본 subscription 테스트가 main-queue 비동기를 기다리지 않아 실패/비결정적임

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:289-304`; `HoguMeterTests/HoguMeterTests.swift:172-197`
- 영향: production coordinator의 기본 delivery queue는 `.main`이고 `onLocation`은 `async`로 예약됩니다. start 직후/재시작 테스트는 `subject.send` 직후 즉시 `#expect(received == 1)`을 실행하므로 main queue가 block을 실행하기 전에 0을 관찰할 수 있습니다. 테스트가 main thread에서 실행되면 특히 확정적으로 queue drain 전 assertion을 수행합니다. 이 테스트들은 lifecycle 성공을 안정적으로 검증하지 못합니다.
- 권고: 해당 테스트도 suspended custom queue 또는 XCTest/Swift Testing expectation으로 delivery completion을 기다린 뒤 assert하십시오. `received` 접근은 같은 queue 또는 actor로 직렬화해 data race도 피하십시오.

### Round 1-B Fix5 판정

`NEEDS_FIX / DEVELOPER`

queued stale token 정책과 전용 queue 테스트 방향은 맞지만 P1 test import와 P2 비동기 assertion을 보완해야 합니다.

---

## Thermal Round 1-B Fix6 최종 재검토

- reviewed_at: `2026-07-29 11:54 KST`
- verification: Combine import, production coordinator, suspended queue의 deterministic drain 정적 검토 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### Fix5 보완 확인

- `HoguMeterTests.swift`가 `import Combine`을 추가해 `PassthroughSubject` test target compile blocker는 해소됐습니다 (`HoguMeterTests.swift:8-11`).
- stale queued callback test는 suspended serial queue를 resume한 뒤 같은 queue의 `sync {}` barrier로 drain을 보장합니다 (`HoguMeterTests.swift:199-214`). 이전 `Task.sleep` 기반 타이밍 의존은 제거됐고, token/cancellable guard로 old event가 0회·new event가 1회 전달되는 production coordinator 정책을 검증합니다.
- production coordinator의 start-before-notification, stop cancel/nil, token increment와 weak capture 연결은 유지됩니다 (`HoguNavigationViewModel.swift:282-315, 455-457, 672-701`).

### P2 — start/restart 성공 테스트는 여전히 main queue delivery를 drain하지 않음

- 파일/줄: `HoguMeterTests/HoguMeterTests.swift:172-179, 190-197`; `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:289-304`
- 영향: 두 테스트는 `HoguNavigationSharedLocationSubscription`을 기본 `deliveryQueue: .main`으로 생성합니다. coordinator는 `subject.send` 뒤 `DispatchQueue.main.async`로 callback을 예약하지만, 테스트는 main queue가 실행되기 전에 즉시 `#expect(received == 1)`을 평가합니다. suspended queue test만 deterministic drain을 사용하며, start 직후 수신과 restart 단일 수신 테스트에는 적용되지 않았습니다. 따라서 해당 두 테스트는 실패하거나 스케줄러에 따라 비결정적으로 통과할 수 있습니다.
- 권고: 두 테스트에도 명시적 serial `deliveryQueue`와 `queue.sync {}` barrier를 적용하거나, main queue expectation을 완료까지 기다린 뒤 assert하십시오. 모든 비동기 delivery assertion은 동일한 deterministic drain 방식을 사용해야 합니다.

### Round 1-B Fix6 판정

`NEEDS_FIX / DEVELOPER`

P1과 stale queue test는 해소됐습니다. 기본 start/restart success tests의 main async drain을 고정한 뒤 PASS할 수 있습니다.

---

## Thermal Round 1-B Fix7 최종 재검토

- reviewed_at: `2026-07-29 11:55 KST`
- verification: 모든 subscription test의 serial delivery queue/barrier, production coordinator/gate 연결, test target 정적 등록 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 해소 확인

- `HoguMeterTests.swift`는 Combine import를 포함하며 test target Sources 등록을 유지합니다. `PassthroughSubject` compile blocker가 없습니다.
- start 직후 수신, stop 뒤 미수신, restart 단일 수신, suspended queue stale callback 4개 subscription test 모두 명시적 serial `deliveryQueue`를 주입하고 `queue.sync {}` barrier 뒤 assertion을 수행합니다 (`HoguMeterTests.swift:172-220`). main queue scheduling/timing에 의존하지 않습니다.
- production `HoguNavigationSharedLocationSubscription`은 duplicate start를 차단하고, stop/deinit에서 cancellable을 취소·nil 처리합니다. token은 pending delivery가 현재 session인지 재확인합니다 (`HoguNavigationViewModel.swift:282-315`). ViewModel은 이 production coordinator를 start notification 이전에 시작하고 stop 때 종료합니다 (`HoguNavigationViewModel.swift:452-457, 672-701`).
- `HoguNavigationLocationSessionGate`는 production start/stop/one-shot callback에 직접 연결되어 delayed one-shot 세션 경합도 계속 차단합니다.

### 최종 판정

`READY_FOR_NEXT_DEVELOPMENT / DEVELOPER`

Thermal Round 1-B의 shared location 단일화, one-shot 및 queued shared callback stale-session 차단, subscription lifecycle 정적 검토를 통과했습니다. 실제 빌드/테스트와 GPS start-stop-restart 동작은 다음 QA gate에서 검증해야 합니다.

---

## Thermal Round 2-C 정적 코드리뷰

- reviewed_at: `2026-07-29 12:08 KST`
- verification: RouteProjectionIndex/NavigationFrame production 연결, current diff, MapView 호출 검색, test target 정적 구조 및 `git diff --check` 검토. 역할 범위에 따라 build/test/commit/push 미실행.

### 확인된 구현

- 일반 경로 계산과 reroute 성공 시 route preview 설정 뒤 `RouteProjectionIndex`를 재구축하고 frame을 nil로 초기화합니다 (`HoguNavigationViewModel.swift:721-737, 1178-1198, 806-820`). 입력 변경은 preview/index/frame을 함께 제거합니다.
- navigation 위치 처리에서 `routeProjectionIndex?.project(location)`을 한 번 호출해 `HoguNavigationFrame`을 만들고, 동일 projection을 이탈 판정과 다음 안내에 전달합니다 (`HoguNavigationViewModel.swift:1021-1045, 1088-1106, 1281-1295`).
- MapView는 frame의 projection으로 overlay, 차량 annotation, low-speed heading fallback, camera focus를 사용하며 `HoguNavigationRouteProjector.project` 직접 호출은 없습니다 (`HoguNavigationView.swift:811-860, 892-983`).
- index는 MKMapPoint/선분 거리/누적 거리/heading을 route 생성 시 캐시하고 0m duplicate segment를 baseline projector와 같이 skip합니다. baseline parity와 duplicate parity 테스트, frame 단일 index request count 테스트, 새 index 분리 테스트는 `HoguMeterTests` target 소스에 존재합니다 (`HoguMeterTests.swift:100-165`).

### P1 — GPS event당 projection 1회 계약이 speed-camera 경로에서 계속 깨짐

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1029-1044, 1491-1525, 1549-1565`
- 영향: `handleLocation`은 index를 한 번 호출한 뒤 매 GPS event에 `updateSpeedCameraWarning()`도 호출합니다. 이 함수는 후보 camera마다 `routeAheadDistance`를 호출하고, 그 안에서 기존 `HoguNavigationRouteProjector.project`를 사용자 좌표와 camera 좌표에 대해 각각 다시 수행합니다. 후보가 C개이면 GPS event 하나에 최소 `1 + 2C`회 전체 polyline 투영이 발생합니다. 따라서 Round 2-C의 “GPS event당 project 정확히 1회” 및 frame 공유 성능 목표를 충족하지 못하며, 발열 원인인 반복 O(C × P) 계산이 남습니다.
- 권고: frame의 user projection을 `updateSpeedCameraWarning`에 전달해 user 재투영을 제거하고, camera projection은 index 구축/후보 갱신 시 캐시하거나 RouteProjectionIndex 기반의 별도 precomputed candidate progress로 전환하십시오. `HoguNavigationRouteProjector.project`의 runtime 호출이 location callback 경로에서 0회인지 정적/단위 테스트로 고정하십시오.

### Round 2-C 판정

`NEEDS_FIX / DEVELOPER`

index/frame/MapView 연결과 기본 parity는 적절하지만, GPS event마다 speed-camera 후보 수만큼 기존 projector를 반복 호출하는 핵심 P1이 남아 있습니다.

---

## Thermal Round 2-C P1 Fix + Phase D 재검토

- reviewed_at: `2026-07-29 12:13 KST`
- verification: production hot path/precompute generation/selector/테스트 정적 검토, Presentation 소스의 `HoguNavigationRouteProjector.project` 호출 0건 및 `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### P1 해소 확인

- `handleLocation`은 주행 위치마다 `routeProjectionIndex?.project(location)`을 한 번 호출해 frame을 발행하고, speed warning에는 동일 `navigationFrame`을 전달합니다 (`HoguNavigationViewModel.swift:1092-1116`). Presentation ViewModel/MapView runtime 경로에는 baseline `HoguNavigationRouteProjector.project` 호출이 남아 있지 않습니다.
- speed-camera 경로 투영은 route 생성·reroute·camera refresh 때만 별도 snapshot index를 utility queue에서 계산합니다. GPS hot path는 frame progress 기반 binary search와 최대 3개 candidate 판정만 수행합니다 (`HoguNavigationViewModel.swift:1530-1584, 1587-1627`).
- precompute gate는 refresh/rebuild/clear/stop에서 invalidate되고, background 결과는 main 반영 전 generation을 재확인합니다 (`HoguNavigationViewModel.swift:830-847, 873-891, 1530-1583`). 이전 route/camera 결과가 현재 frame에 반영되는 stale 경로를 차단합니다.

### 정책·회귀 확인

- precompute indexer는 route에서 160m 초과 camera를 제외하고 progressDistance 오름차순으로 저장합니다. selector는 frame progress보다 뒤인 후보를 binary search로 건너뛰고 최대 3개만 반환합니다 (`HoguNavigationViewModel.swift:340-395`).
- 경고 거리(`SpeedCameraWarning.distanceM`)는 기존 요구에 맞게 frame route progress와 camera route progress의 차이인 route-ahead 거리입니다. 600m route-ahead, 45도 전방, 700m direct-distance guard를 함께 적용해 경로상 먼 camera/반대 방향/비정상 오투영 경로를 배제합니다 (`HoguNavigationViewModel.swift:1594-1620`).
- index parity/duplicate, frame 단일 request, reroute index 분리, 160m filter·정렬, 뒤 camera 제외·최대 3개, stale gate tests가 기존 `HoguMeterTests` target 소스에 있고 `@testable import` 및 필요한 imports가 존재합니다 (`HoguMeterTests.swift:100-205`). 정적 컴파일 차단은 확인되지 않았습니다.

### 최종 판정

`READY_FOR_NEXT_DEVELOPMENT / DEVELOPER`

Round 2-C P1과 Phase D hot path 최적화는 정적 검토를 통과했습니다. QA는 정상 Simulator/실기기에서 route/reroute, camera 경고의 거리·방향·최대 노출 수와 background stale 결과를 검증해야 합니다.

---

## Thermal Phase E+F 정적 코드리뷰

- reviewed_at: `2026-07-29 12:19 KST`
- verification: render budget, MapView 적용, thermal observer/state controller 및 test target 정적 검토, `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 확인된 구현

- camera budget은 policy interval(기본 0.5초=2Hz)을 먼저 적용하고, 5m 이동 또는 3도 heading 변화가 없을 때도 3초 후 한 번 갱신합니다 (`HoguNavigationViewModel.swift:473-499`). camera는 같은 frame의 차량 projection/heading을 사용하고 nested `UIView.animate + setCamera` 조합을 제거했습니다 (`HoguNavigationView.swift:849-869`).
- overlay는 최소 시간과 진행거리 조건을 모두 만족할 때만 재생성해 10m/1초 이하의 과도 갱신을 차단합니다 (`HoguNavigationViewModel.swift:501-516`, `HoguNavigationView.swift:918-954`).
- nominal/fair/serious/critical 정책은 camera interval, pitch, animation, POI, opaque HUD를 구분합니다. critical은 2초(0.5Hz), pitch 0, animation/effect 비활성, overlay 사실상 중지로 적용되며 MapView의 POI filter와 HUD background에도 실제 연결됩니다 (`HoguNavigationViewModel.swift:416-439`, `HoguNavigationView.swift:169-172, 800-821`).
- thermal observer는 `.main` queue에 등록하고 deinit에서 해제합니다. 안내·이탈·speed-camera 계산에는 energy policy guard가 없어 정확도 경로가 제한되지 않습니다 (`HoguNavigationViewModel.swift:737-751`). 테스트는 policy, 30초 hysteresis 기본 경로, camera/overlay threshold를 기존 `HoguMeterTests` target에서 정적으로 컴파일 가능한 형태로 확인했습니다 (`HoguMeterTests.swift:207-239`).

### P2 — 동일 recovery 상태 notification마다 30초 timer를 중복 예약함

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:753-763`
- 영향: serious 상태에서 nominal/fair notification이 반복되면 controller는 같은 `pendingRecoveryLevel`과 deadline을 유지하지만, `updateThermalPolicy`는 매번 `observedLevel < effectiveLevel` 조건만으로 새 `DispatchQueue.main.asyncAfter`를 예약합니다. 이후 열 상태가 다시 나빠졌거나 recovery 목표가 바뀌어도 기존 timer들이 남아 순서대로 `advance`와 `energyPolicy` 할당을 수행합니다. 최종 state가 대개 유지되더라도 정책 갱신이 중복되고 timer 경합 없이 30초 hysteresis를 보장해야 한다는 계약을 충족하지 못합니다.
- 권고: recovery work item/token을 ViewModel에 하나만 보유하고 새 recovery 후보·악화 시 기존 작업을 cancel/invalidate하십시오. timer callback에도 captured recovery generation과 pending deadline 일치를 확인하십시오. 동일 nominal notification 반복, fair→nominal 후보 변경, recovery 대기 중 serious 재악화 시나리오를 unit test로 고정하십시오.

### Phase E+F 판정

`NEEDS_FIX / DEVELOPER`

render budget, critical 저하, MapView/HUD 반영과 기능 경로 보존은 정적으로 적절합니다. recovery timer 단일화·stale callback 차단을 보완한 뒤 재검토가 필요합니다.

---

## Thermal Phase E+F P2 재검토 — Recovery 예약 단일화

- reviewed_at: `2026-07-29 12:22 KST`
- verification: 최신 production diff, DEV_HANDOFF, scheduler tests 및 `git diff --check` 정적 검토. 역할 범위에 따라 build/test/commit/push 미실행.

### P2 해소 확인

- `HoguNavigationThermalRecoveryScheduler`가 candidate/deadline/generation을 단일 source of truth로 유지합니다. 동일 candidate·deadline은 새 generation을 발급하지 않고, 후보 변경 및 cancel은 generation을 무효화합니다 (`HoguNavigationViewModel.swift:476-498`).
- ViewModel은 scheduler가 새 generation을 반환할 때만 work item을 만들고, 후보 변경 시 이전 `DispatchWorkItem`을 cancel합니다. raw thermal state가 effective level 이상으로 재악화되면 `cancelThermalRecovery()`가 work item과 scheduler를 함께 무효화합니다 (`HoguNavigationViewModel.swift:784-818`). deinit에서도 동일 취소를 수행합니다.
- callback은 captured generation, candidate, deadline 경과, current raw thermal state와 candidate 일치를 모두 확인한 뒤에만 `advance` 및 policy 변경을 실행합니다 (`HoguNavigationViewModel.swift:799-809`). stale work item이 실행되더라도 scheduler acceptance guard를 통과할 수 없습니다.
- scheduler test는 동일 후보의 중복 예약 거부, fair→nominal 후보 교체에서 기존 generation 거부, cancel 뒤 stale callback 거부를 순수 helper 대상으로 검증합니다. 기존 `HoguMeterTests` target의 imports/`@testable import` 조합에서 정적 컴파일 차단은 확인되지 않았습니다 (`HoguMeterTests.swift:225-244`).

### 판정

`READY_FOR_NEXT_DEVELOPMENT / DEVELOPER`

Recovery timer 중복·후보 교체·재악화 stale callback P2는 정적으로 해소됐습니다. 실제 thermal notification 순서와 30초 복귀 체감은 QA에서 확인해야 합니다.

---

## Thermal Phase A+G 정적 코드리뷰 — 계측·카메라 조회·Rollback Flag

- reviewed_at: `2026-07-29 13:09 KST`
- verification: 최신 ViewModel/MapView/API client/rollback flag 및 test source 정적 검토, hot-path 호출 검색, `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 확인된 구현

- signpost는 location callback, route projection, guidance, speed camera, MapView update, overlay rebuild, camera update의 실제 호출 경계에 연결되어 있고 begin/end는 각 경로에서 짝을 이룹니다. payload는 count와 thermal level뿐으로 신규 계측에 좌표·주소·도로명·camera ID를 전달하지 않습니다.
- 4개 rollback flag는 미설정 시 모두 enabled이며 shared location, route index, camera background index, thermal adaptation에 연결됩니다. thermal flag가 꺼져도 serious/critical policy는 계속 적용되고 privacy-safe 계측은 flag로 꺼지지 않습니다.
- route sample selector는 start/middle/end 최대 3개를 선택하고, region API client의 `sido|sigungu` key는 요청 필드와 일치합니다.

### P1 — 지역을 넘는 재탐색에서 기존 카메라가 남아 새 지역 조회가 영구 차단됨

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1530-1535, 1714-1730`
- 영향: 재탐색 성공 뒤 기존 `speedCameras`를 유지한 채 `loadSpeedCamerasIfNeeded()`를 호출하지만, 함수 첫 줄이 `guard speedCameras.isEmpty else { return }`입니다. 따라서 서울에서 경기처럼 route region이 바뀌어도 geocode/region fetch가 한 번도 실행되지 않습니다. 기존 배열은 새 bbox에서 비거나 일부만 남아 speed-camera warning이 누락될 수 있으며, 개발 보고의 “같은 지역 reroute 공백 방지”가 새 지역 stale 혼합 방지까지 충족하지 못합니다.
- 권고: 현재 route의 normalized region set/generation을 보관하고, 동일 set일 때만 기존 목록을 즉시 재사용하십시오. 새 set이면 기존 후보는 표시 가능한 범위에서 유지하되 새 region fetch를 시작하고, 완료 시 현재 route generation·region set이 일치할 때만 원자적으로 교체하십시오. cross-region reroute, fetch 지연 중 stale 결과, 동일-region reroute 재사용 테스트를 추가하십시오.

### P2 — 보고된 API failure backoff·10초 polling 중복 억제가 구현되어 있지 않음

- 파일/줄: `HoguMeter/Domain/Services/SpeedCameraAPIClient.swift:36-123`; `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1714-1762`
- 영향: camera/geocode 요청에는 failure timestamp, retry delay, in-flight task, 10초 polling gate가 없습니다. `rg` 검색상 해당 경로에 backoff/poll 제어도 존재하지 않습니다. 더구나 region request가 실패하면 빈 배열을 즉시 region cache에 저장하므로 해당 앱 세션에서는 재시도하지 않고, cache TTL도 없어 데이터/실패 결과가 무기한 stale입니다. 개발 보고의 backoff/dedupe 절감 주장은 현재 코드 근거가 없습니다.
- 권고: region key별 성공 cache TTL과 실패 backoff(예: exponential cap), in-flight task 공유 및 마지막 poll 시각을 명시적으로 도입하십시오. 10초 안의 동일 region 요청은 하나만 실행하고 완료/실패 시 gate 상태를 갱신하십시오. 실패 후 backoff, TTL 만료, 동시 재탐색 dedupe, retry 성공을 deterministic test로 고정하십시오.

### P2 — geocode sample 중복 요청과 Release 계측 비용·counter 의미가 고정되지 않음

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1339-1353, 1733-1765`; `HoguMeter/Core/Performance/HoguNavigationPerformanceMonitor.swift:15-30`
- 영향: sample selector는 최대 3개만 제한할 뿐 중복 coordinate를 제거하지 않아 duplicate polyline/짧은 경로에서 같은 위치의 reverse geocode를 반복합니다. region `Set`은 geocode 완료 뒤에만 적용됩니다. 또한 Release guard 없이 매 GPS callback마다 `OSSignpostID` 생성과 routeSegments event를 수행하며, 실제 projection이 없는 branch에서도 `projectorCalls`를 증가시킵니다. 계측의 Release overhead와 counter가 “실제 projector 호출”을 뜻한다는 계약을 검증할 테스트가 없습니다.
- 권고: geocode 전 coordinate dedupe(정확도 기준을 문서화)와 region 결과 memoization을 적용하고, Release에서는 no-op 또는 compile-time guard로 hot-path 비용을 제한하십시오. projectorCalls는 실제 project 호출 branch에서만 증가시키고, sample dedupe·counter·Release monitor 정책을 unit test/빌드 설정 검토로 고정하십시오.

### 판정

`NEEDS_FIX / DEVELOPER`

P1 cross-region reroute safety 경로를 먼저 보완해야 합니다. 이후 backoff/TTL/in-flight polling gate와 geocode dedupe·계측 Release contract를 구현하고 재리뷰를 요청하십시오. 정상 Simulator/실기기 build·GPS/thermal 실험은 수정 후 QA gate에서 수행해야 합니다.

---

## Thermal Phase A+G P1/P2 수정분 재리뷰

- reviewed_at: `2026-07-29 13:31 KST`
- verification: 최신 route-generation/region key 교체, sample selector, performance monitor, region cache/backoff/in-flight 구현과 test source 정적 검토, `git diff --check` 통과. 역할 범위에 따라 build/test/commit/push 미실행.

### 해소 확인

- route rebuild마다 `speedCameraRouteGeneration`을 증가시키고, fetch 완료 시 captured generation이 현재와 같을 때만 `speedCameras`·region key·precompute 결과를 갱신합니다. 같은 normalized region-key set과 비어 있지 않은 camera 목록은 재사용하므로 동일 지역 reroute의 재다운로드는 피합니다.
- route sample은 start/middle/end 최대 3개이며 각 후보가 이미 선택된 좌표와 25m 미만이면 geocode 전에 제외합니다.
- performance monitor는 debug assertion configuration에서만 signpost/event를 발행하고 Release는 invalid/no-op으로 반환합니다. projectorCalls는 실제 projection branch에서만 증가합니다. 신규 계측 payload에 raw coordinate/address/road/camera ID는 없습니다.
- region 성공 cache TTL은 일반 10분·정상 empty 1분이고, region network 실패는 성공 cache에 저장하지 않습니다. retry policy는 10초부터 5분 cap으로 증가합니다.

### P1 — cross-region fetch 대기 중 이전 지역 speed-camera warning이 계속 노출될 수 있음

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1530-1551, 1799-1830, 1865-1906`
- 영향: reroute 성공 직후 `refreshSpeedCameraCandidates()`는 기존 `speedCameras`로 새 route 후보를 다시 만들고, `speedCameraWarning`과 `lastWarnedCameraId`를 clear하지 않습니다. 이후 새 region geocode/fetch가 진행되는 동안 기존 warning은 published 상태로 유지됩니다. 새 route bbox에서 후보가 0개여도 `refreshSpeedCameraCandidates()`는 warning을 갱신하지 않아 old-region camera의 경고/햅틱 상태가 남습니다. cross-region에서는 새 목록을 얻을 때까지 old-region 오탐을 허용하지 않아야 한다는 계약을 충족하지 못합니다.
- 권고: region set이 달라지는 reroute를 확정하는 시점에 현재 warning, projected candidates, lastWarnedCameraId를 invalidation generation과 함께 clear하십시오. same-region reuse는 유지하되, cross-region fetch 중에는 old camera를 경고에 사용하지 마십시오. cross-region fetch 지연 중 old warning 0회, stale completion 무시, same-region warning 연속성 테스트를 추가하십시오.

### P2 — in-flight 공유의 완료 side effect가 대기자마다 중복되고, geocode 실패 fallback은 backoff/실패 미캐시 계약 밖임

- 파일/줄: `HoguMeter/Domain/Services/SpeedCameraAPIClient.swift:59-92, 120-155`
- 영향: 같은 key의 두 caller는 하나의 `Task`를 공유하지만, 두 caller 모두 `await task.value` 뒤 `inFlightRegionTasks[key] = nil` 및 cache/failure state 갱신을 실행합니다. failure이면 두 번째 대기자가 failure count를 다시 올려 10초→20초처럼 한 번의 네트워크 실패를 여러 번 집계할 수 있으며, mutable dictionary는 actor/serial executor 보호가 없어 concurrent call에서 data race가 가능합니다. 또한 regions가 비었을 때 사용하는 `fetchCameras()`는 기존 global cache를 쓰며 실패 후 빈 배열을 `cachedCameras`에 영구 저장하므로 “failure 미캐시/backoff/10초 중복 억제” 정책이 적용되지 않습니다.
- 권고: region coordinator를 `actor` 또는 lock-guarded 단일 executor로 만들고, task를 생성한 owner만 completion side effect(cache/failure/in-flight removal)를 수행하게 하십시오. awaiter는 결과만 공유해야 합니다. geocode 실패의 global fallback도 동일 coordinator 정책으로 넣거나 failure를 cache하지 말고 retry/backoff/in-flight 계약을 적용하십시오. 동시 2/3 caller의 단일 failure가 failureCount 1회만 증가하는지, cancellation 뒤 shared request가 불필요하게 취소되지 않는지, global fallback 실패 뒤 재시도가 가능한지를 deterministic test로 고정하십시오.

### P2 — 성공 cache/partial 결과 및 새 요구 테스트의 검증 범위가 불충분함

- 파일/줄: `HoguMeter/Domain/Services/SpeedCameraAPIClient.swift:108-117, 145-155`; `HoguMeterTests/HoguMeterTests.swift:262-283`
- 영향: multi-region fetch에서 일부 region이 cooldown/failure여도 성공한 일부 목록을 반환하고 ViewModel은 전체 `regionKeys`로 atomic replace합니다. 이후 같은 region set은 재사용되어 누락 region의 retry가 막힐 수 있습니다. 또한 추가 테스트는 retry policy 숫자와 3개 샘플만 확인하며 25m dedupe, TTL(10분/1분), failure 미캐시, in-flight 공유, cross-region stale/old-warning, Release no-op/counter를 검증하지 않습니다.
- 권고: fetch result에 complete/partial 상태를 포함하거나 실패 key를 ViewModel reuse 조건에 반영해 누락 region이 cooldown 후 재시도되게 하십시오. 위 계약을 testable clock/network stub으로 unit test하고, test target 컴파일과 실제 concurrent request는 QA에서 실행하십시오.

### 판정

`NEEDS_FIX / DEVELOPER`

generation 기반 atomic replace와 same-region reuse, 25m sample dedupe, Release signpost no-op은 반영됐습니다. 다만 cross-region old warning P1과 request coordinator의 exactly-once completion/fallback 정책 P2를 보완해야 QA로 전환할 수 있습니다.

---

## Thermal Phase A+G 최신 수정분 재리뷰 — actor coordinator

- reviewed_at: `2026-07-29 13:43 KST`
- verification: 최신 actor request client, ViewModel stale/warning guard, test source 및 `git diff --check` 정적 검토. 역할 범위에 따라 build/test/commit/push 미실행.

### 해소 확인

- `SpeedCameraAPIClient`는 `actor`로 변경되어 region cache·failure·in-flight dictionary의 일반적인 concurrent access data race는 차단합니다.
- route rebuild가 speed-camera generation을 증가시키면서 warning과 last warned ID를 즉시 clear합니다. reroute fetch의 stale generation 결과는 갱신하지 않으므로 old-region warning P1은 해소됐습니다.
- global fallback은 HTTP/network 실패 시 `cachedCameras`에 저장하지 않고, HTTP 성공의 empty 결과만 cache합니다. region 성공 empty TTL 1분·일반 성공 10분과 partial failure가 있을 때 same-set reuse를 막는 `hasPendingRetry` 연결도 확인했습니다.
- unstructured shared task이므로 한 waiter의 cancellation이 underlying network task를 직접 cancel하지 않는 구조입니다.

### P2 — shared task의 completion side effect가 여전히 모든 waiter에서 실행되어 exactly-once 계약을 위반함

- 파일/줄: `HoguMeter/Domain/Services/SpeedCameraAPIClient.swift:140-163`
- 영향: actor 선언에도 불구하고 첫 caller가 생성한 task와 후속 caller가 같은 `task.value`를 await한 뒤, 각 caller가 차례로 `inFlightRegionTasks[key] = nil` 및 cache/failure state update를 실행합니다. 동일 네트워크 failure 하나에 failure count가 waiter 수만큼 증가해 backoff가 10초가 아닌 20초/40초로 확대될 수 있습니다. 먼저 완료한 waiter가 in-flight entry를 제거한 뒤 새 caller가 들어오면 기존 task가 아직 다른 waiter에 전달 중이어도 새 network task를 만들 여지도 있습니다.
- 권고: actor 내부에 completion을 담당하는 owner task를 만들고 그 task가 cache/failure/in-flight removal을 정확히 한 번 수행하도록 하십시오. 외부 waiter는 결과만 await하게 하며 cancellation은 waiter만 중단하고 shared owner는 유지하는지 명시적으로 테스트하십시오.

### P2 — 요청한 핵심 검증 테스트가 아직 존재하지 않음

- 파일/줄: `HoguMeterTests/HoguMeterTests.swift:262-283`
- 영향: 현재 추가 테스트는 3-point selector와 retry policy 숫자뿐입니다. 25m dedupe, actor in-flight 단일 network call, waiter cancellation, owner cleanup 1회, global failure 미캐시/HTTP empty 1분, TTL 10분, partial failure 이후 같은 set retry, cross-region warning 즉시 clear/stale generation 차단을 검증하는 test double·테스트가 없습니다. 따라서 actor 전환과 failure/retry 계약의 compile/runtime 회귀를 포착할 수 없습니다.
- 권고: injectable clock/transport를 사용해 위 시나리오를 deterministic async test로 추가하십시오. test target은 actor 호출에 `await`를 사용하고, new test source가 HoguMeterTests build phase에 포함되는지 QA에서 컴파일로 확인하십시오.

### 판정

`NEEDS_FIX / DEVELOPER`

cross-region warning P1은 해소됐습니다. shared owner의 exactly-once completion과 핵심 async test를 보완한 뒤 QA gate로 전환할 수 있습니다.

---

## Thermal Phase A+G 최종 정적 코드리뷰

- reviewed_at: `2026-07-29 14:06 KST`
- verification: 최신 production diff, 테스트 전담 DEV_HANDOFF, actor requestID owner 경로, rollback/privacy 연결, HoguMeterTests source/build-phase 등록 및 `git diff --check` 정적 검토. 역할 범위에 따라 build/test/commit/push 미실행.

### 최종 확인

- `SpeedCameraAPIClient` actor는 key별 `InFlightRegionRequest(requestID, task)`를 보관하고, owner task만 `completeRegionRequest`를 호출합니다. completion은 현재 requestID가 일치할 때만 in-flight 제거·TTL cache·failure backoff를 갱신하므로 여러 waiter가 같은 결과를 받아도 side effect는 정확히 한 번입니다.
- waiter는 shared unstructured task의 value만 await하므로 개별 waiter cancellation이 owner request를 취소하지 않습니다. requestID guard는 stale owner completion이 새 요청 상태를 덮지 못하게 합니다.
- cross-region route rebuild와 region transition은 fetch 완료 전 warning, last warned ID, 일반/투영 candidate 및 precompute generation을 무효화합니다. 완료 결과는 route generation 일치 시에만 atomic replace합니다. 같은 region set은 성공 cache 재사용을 유지하고, partial failure는 pending retry로 재사용을 막아 실패 key만 재시도합니다.
- 일반 성공/정상 empty TTL은 각각 10분/1분이며 실패는 성공 cache에 저장하지 않고 10초부터 5분 cap backoff를 적용합니다. Release instrumentation은 no-op이고 event payload는 count/thermal level만 사용합니다. 4개 rollback flag의 기본 enabled 및 shared location/route index/camera index/thermal 경계 연결, serious/critical 보호 유지도 확인했습니다.

### Async 테스트 정적 검토

- 새 테스트는 실제 production `SpeedCameraAPIClient` actor에 `nowProvider`와 `regionFetchOverride` seam을 주입합니다. 동시 success/failure, waiter cancellation, 10분/1분 TTL, failure 미캐시·cooldown retry, partial failure의 성공 key 재사용/실패 key 재시도, 25m sample dedupe와 cross-region transition을 다룹니다.
- Swift Testing의 async `@Test`, `Task.value`, `#expect(await ...)` 사용은 test 함수의 async context에 맞고, test helper는 actor 또는 lock을 사용합니다. `@testable import HoguMeter`, `Testing`/`Combine` imports 및 `HoguMeterTests.swift` test Sources 등록을 확인해 정적 컴파일 차단은 발견되지 않았습니다.

### 판정

`READY_FOR_QA / QA_AGENT`

Thermal Phase A+G의 정적 코드리뷰를 통과했습니다. QA는 정상 Simulator/실기기에서 새 async tests, cross-region reroute warning, retry/TTL과 Release/thermal 장시간 주행을 실행해 확인해야 합니다.

---

## QA P1 — Thermal Performance 파일 Xcode target membership 재리뷰

- reviewed_at: `2026-07-29 14:13 KST`
- verification: `project.pbxproj` object 참조/target Sources 정적 대조, UUID definition uniqueness 검사, `plutil -lint`, `git diff --check` 실행. build/test/commit/push 미실행.

### 확인 결과

- `HoguNavigationPerformanceMonitor.swift`와 `HoguNavigationOptimizationFlags.swift`는 각각 PBXFileReference 1개와 PBXBuildFile 1개를 갖습니다. 각 BuildFile은 올바른 FileReference를 가리키고 HoguMeter app `PBXSourcesBuildPhase`에 정확히 1회만 등록됩니다.
- 두 FileReference는 `Core` 아래 `Performance` group의 올바른 상대 path(`Core/Performance`)에 각각 1회 자식으로 배치됩니다. 신규 group과 네 object UUID의 definition 중복은 없고, `project.pbxproj` 문법은 `plutil -lint`를 통과했습니다.
- HoguMeterTests `PBXSourcesBuildPhase`에는 두 production BuildFile이 없으며 test target 오등록은 없습니다. 현재 신규 production Swift 파일은 `Core/Performance`의 두 파일뿐이고 모두 app target membership을 갖습니다.

### 판정

`READY_FOR_QA / QA_AGENT`

QA P1 target membership 누락은 정적으로 해소됐습니다. 실제 Xcode build/test와 주행 QA를 계속 진행하십시오.

---

## User Build Failure Fix 정적 코드리뷰 — Timer actor / Preview / AccentColor

- reviewed_at: `2026-07-29 14:33 KST`
- verification: MeterViewModel timer lifecycle, AppStoreScreenshots Preview diff, asset catalog JSON/jq schema, project accent build setting 및 `git diff --check` 정적 검토. build/test/commit/push 미실행.

### 해소 확인

- `Timer.scheduledTimer`의 `@Sendable` closure는 MeterViewModel의 `tripStartTime`·duration·night/speed 상태를 직접 읽거나 쓰지 않습니다. weak capture한 뒤 `Task { @MainActor [weak self] in ... }` 내부에서만 actor-isolated state에 접근하므로 사용자 빌드 오류의 직접 원인은 제거됐습니다.
- `AppStoreScreenshots.swift`의 여섯 `#Preview`에서 deprecated `.previewDevice(...)`만 제거됐으며 Preview label/body는 각각 하나의 View expression으로 정상입니다. 전체 Swift source에서 `.previewDevice` 호출이 남아 있지 않습니다.
- `Resources/Assets.xcassets/AccentColor.colorset/Contents.json`은 `info(author: xcode, version: 1)`, universal idiom, sRGB RGBA component를 갖는 유효한 colorset JSON이며 `jq` 구조 검증을 통과했습니다. app Debug/Release 설정의 `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`와 이름·asset catalog resource 연결도 일치합니다.

### P2 — stop/reset 뒤 이미 예약된 MainActor Task가 meter 상태를 다시 갱신할 수 있음

- 파일/줄: `HoguMeter/Presentation/ViewModels/MeterViewModel.swift:402-410, 160-164, 424-427`
- 영향: Timer callback은 task를 main actor에 enqueue한 뒤 즉시 반환합니다. 그 사이 `stopMeter()`/`resetMeter()`가 `timer.invalidate()`를 실행해도 이미 enqueue된 task는 취소되지 않으며, `tripStartTime`이 남아 있으면 duration·night mode·speed timeout을 한 번 더 갱신합니다. 이전 동기 callback에는 없던 post-stop update window라 lifecycle/표시 상태 회귀가 가능합니다.
- 권고: task 실행 시 `state == .running`과 current timer session generation을 확인하거나, timer generation/token을 start/stop/reset에서 무효화해 queued task가 최신 주행 세션일 때만 실행되게 하십시오. start→tick enqueue→stop/reset→task drain 및 stop→새 start stale task 차단 테스트를 추가하십시오.

### 색상 확인 메모

- 새 accent는 `#FF7A00`(sRGB 1.000/0.478/0.000)입니다. schema는 유효하지만 코드의 `Color.orange`/`UIColor.systemOrange`와 정확히 같지는 않습니다. global accent 적용 범위의 색상 일관성은 QA 시각 확인이 필요합니다.

### 판정

`NEEDS_FIX / DEVELOPER`

Timer session stale-task P2를 보완한 뒤 QA로 되돌릴 수 있습니다. Preview warning과 AccentColor asset 누락은 정적으로 해소됐습니다.

---

## User Build Failure Fix P2 — Timer lifecycle generation 재리뷰

- reviewed_at: `2026-07-29 14:41 KST`
- scope: `MeterViewModel`의 Timer lifecycle P2 수정, production gate 순수 테스트, Accent/Preview 변경 유지
- verification: 최신 변경분 정적 diff/호출 경로 확인, `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- `MeterTimerGenerationGate.start()`와 `stop()`은 각각 generation을 증가시키며, Timer callback은 캡처 generation·`.running` 상태·`tripStartTime` 존재를 모두 만족할 때만 상태를 갱신합니다.
- `stopTimer()`는 Timer 무효화/해제 후 generation을 증가시키고, `resetMeter()`도 이를 경유합니다. 따라서 stop/reset 직전에 이미 queue된 `Task { @MainActor }` 콜백은 generation 불일치로 종료됩니다.
- start-stop-start 시에도 구 callback의 generation은 새 start generation과 일치하지 않아 차단됩니다. `startTimer()`의 기존 Timer 교체 역시 새 generation 발급으로 구 callback을 무효화합니다.
- production `MeterTimerGenerationGate`를 `@testable import HoguMeter` 테스트가 직접 사용합니다. 시작 허용 조건과 stop 후 재시작의 stale callback 차단을 순수 테스트로 검증하도록 구성되어 접근성과 대상 범위가 일관됩니다.
- `previewDevice` 제거 상태와 `AccentColor.colorset` JSON, `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor` 연결은 유지됩니다. 기존 색상 톤 차이는 실제 기기/스크린샷 QA 확인 항목으로 남깁니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 실제 Timer callback이 MainActor에서 start-stop-start 및 reset 직후 stale update 없이 동작하는지, 관련 단위 테스트 및 앱 빌드, AccentColor 실제 렌더링을 확인해야 합니다.

---

## Actual Build P1 — os_signpost StaticString 재리뷰

- reviewed_at: `2026-07-29 14:51 KST`
- scope: `HoguNavigationPerformanceMonitor.Span`의 StaticString 매핑, signpost begin/end API·pairing, privacy
- verification: production source 정적 호출 대조 및 `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- `Span`은 raw-value enum이 아니며 7개 case(`locationCallback`, `routeProjection`, `guidance`, `speedCamera`, `mapUpdate`, `overlayRebuild`, `cameraUpdate`)를 빠짐없이 `switch`의 `StaticString` literal로 매핑합니다. `Span.rawValue` 사용은 남아 있지 않습니다.
- `os_signpost`의 `name:` 인자는 compile-time `StaticString`을 요구하는 API이고, `begin`·`end` 모두 동일한 `span.signpostName`을 전달합니다. 각 호출부도 같은 Span과 반환된 `OSSignpostID`를 짝지어 사용하며, defer가 있는 map/location 구간은 early-return에도 end를 보장합니다.
- event 이름도 문자열 보간이나 원격/사용자 입력이 아닌 `StaticString` literal이며, payload는 public 정수 count 또는 thermal level뿐입니다. 좌표·주소·도로명·camera ID·route/사용자 식별자는 signpost name/message에 전달되지 않습니다.
- release에서는 `_isDebugAssertConfiguration()` guard로 모든 signpost 호출이 no-op이므로 privacy-safe 계측 경계도 유지됩니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 실제 앱 빌드에서 `os_signpost` API 컴파일과 Instruments span pairing, Debug/Release 계측 동작을 확인해야 합니다.

---

## Actual Build Round 2 P1/P2 — SpeedCamera shared Task / Sendable clock 재리뷰

- reviewed_at: `2026-07-29 15:01 KST`
- scope: Swift 5.9 `Task` 결과 타입 문맥, `nowProvider` Sendable 기본값, actor owner/in-flight 완료 계약
- verification: `SpeedCameraAPIClient` 및 호출·테스트 seam 정적 대조, `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- `InFlightRegionRequest.task`와 생성 `Task`가 모두 `Task<Result<[SpeedCamera], Error>, Never>`로 명시됩니다. weak-self 조기 반환의 `.failure(...)`, override/network 결과, `task.value`가 동일한 concrete `Result` 문맥을 사용하므로 Swift 5.9의 결과 타입 추론 불명확성이 남지 않습니다.
- `nowProvider`는 `@Sendable () -> Date`이고 기본값이 noncapturing `{ Date() }` closure입니다. actor 밖 함수 참조를 전달하지 않으며, 테스트 clock도 `@unchecked Sendable` 동기화 객체를 캡처한 closure로 주입됩니다.
- actor는 새 요청에 request ID를 발급한 뒤 in-flight dictionary에 Task를 저장하고, 같은 region의 후속 호출은 그 Task만 await합니다. owner Task만 `completeRegionRequest`를 호출하고 request ID가 현재 owner와 일치할 때만 dictionary 제거·TTL cache·failure backoff를 반영하므로 완료 반영은 정확히 한 번입니다.
- 완료 이후 cache 성공은 failure state를 제거하고, 실패는 cache를 만들지 않은 채 backoff만 갱신합니다. waiter 취소는 shared unstructured Task를 cancel하지 않으며, 기존 TTL/backoff/in-flight 정책과 테스트 seam이 유지됩니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 Swift 5.9 실제 앱/테스트 target 빌드에서 concurrency diagnostics가 없는지와, 동시 성공·실패·waiter 취소·TTL/backoff 계약을 실행 확인해야 합니다.

---

## Navigation Search UI — 정적 CODE_REVIEW

- reviewed_at: `2026-07-29 15:16 KST`
- scope: compass/search panel 배치, 12건 검색 목록·최근 목록, 중복 제거·identity·divider, autocomplete callback, 테스트 구조
- verification: `HoguNavigationView`, `HoguNavigationViewModel`, `HoguMeterTests` 정적 대조 및 `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### P1 — 이전 autocomplete callback이 새 query 화면을 덮어쓸 수 있음

- 파일/줄: `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift:1321-1332, 1336-1350`
- 영향: `completerDidUpdateResults`와 실패 callback은 `DispatchQueue.main.async` 블록에서 `activeSearchQuery`가 비어 있지 않은지만 확인합니다. query A의 delegate callback이 main queue에 대기한 사이 사용자가 query B로 변경하면, A callback이 B의 `searchResults` 또는 `errorMessage`를 반영할 수 있습니다. 현재 query의 fragment/generation을 callback 시점에 캡처해 active query와 비교하는 stale guard가 없습니다.
- 수정 요청: delegate 진입 시 `completer.queryFragment` 또는 별도 incrementing query generation을 캡처하고, main queue 반영 직전에 `activeSearchQuery` 및 현재 target/generation과 모두 일치할 때만 결과·오류를 갱신하십시오. A→B 전환 뒤 A 결과/오류가 무시되는 회귀 테스트도 추가하십시오.

### 정적으로 유지 확인한 항목

- 비주행에서만 search panel/list가 표시되고, 주행 UI 분기는 변경되지 않았습니다. panel top `72pt`는 safe area 안쪽 좌표를 기준으로 배치되어 일반 native compass footprint(약 44pt) 아래에 최소 12pt 여유를 둘 수 있는 값입니다. 실제 MapKit compass 위치는 기기·화면 상태에 따라 달라 실기기 QA가 필요합니다.
- `ScrollView + LazyVStack`은 `maxHeight: 420`만 갖고 최소 높이를 강제하지 않아 작은 기기, keyboard, route summary가 같은 VStack 공간을 요구할 때 목록 영역이 축소될 수 있습니다. 12개 행 전체 표시/끝까지 scroll은 실기기 QA가 필요합니다.
- visible limit은 policy와 `ForEach`에 모두 12로 적용됐고, recent는 `prefix(5)`로 유지됩니다. title/subtitle 각각의 trim·case/diacritic/width insensitive composite key는 최초 순서를 보존하며 같은 title/다른 subtitle을 보존합니다.
- 결과는 매 수신 시 새 UUID를 갖는 `HoguNavigationSearchResult`로 변환되어 ForEach identity 충돌이 없고, divider는 현재 표시 prefix의 마지막 ID와 비교하므로 마지막 행 뒤에 divider를 추가하지 않습니다.
- pure policy 테스트는 tuple generic 입력과 실제 production policy를 직접 사용해 exact duplicate, 정규화, 같은 title/다른 subtitle, 최초 12건을 검증하는 구조입니다. stale callback 회귀 검증은 없습니다.

### 판정

`NEEDS_FIX / DEVELOPER`

P1 stale autocomplete callback guard와 회귀 테스트를 보완한 뒤 CODE_REVIEW로 되돌리십시오.

---

## Navigation Search UI P1 — stale callback generation gate 재리뷰

- reviewed_at: `2026-07-29 15:26 KST`
- scope: response token generation/query/target production 연결, success/error payload capture, invalidation·main 적용 guard, 회귀 테스트
- verification: `HoguNavigationViewModel`, View focus/clear 호출 경로, `HoguMeterTests`의 production gate 대조 및 `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- `HoguNavigationSearchResponseToken`은 trim된 query, target, generation을 함께 갖고, `HoguNavigationSearchResponseGate.accepts`가 세 항목의 현재값 일치를 요구합니다. token은 production `MKLocalSearchCompleter` success/error delegate 진입 시점에 생성됩니다.
- `focusSearch`, `clearSearchSuggestions`, 빈/nonempty `updateSearchQuery`, search/recent 결과 선택의 clear 경로가 모두 gate generation을 advance합니다. View의 focus 해제도 `clearSearchSuggestions`를 호출하므로 A→B 전환, 같은 query의 target 변경, dismiss/선택 뒤 response를 무효화합니다.
- success는 callback query/target/token 및 `completer.results` 배열을 main queue 전환 전에 값으로 capture하고, error도 query/target/token 및 error code/description을 capture합니다. main 적용 직전 gate guard를 통과한 active token만 `searchResults` 또는 `errorMessage`를 변경합니다.
- 현재 활성 query는 update 후 동일 generation/query/target token으로 callback을 받아 정상 수용됩니다. MapKit completer가 결과별 request ID를 제공하지 않는 제약은 남지만, callback 이후 main queue 대기 중 발생하는 앱 내부 stale race는 generation gate로 차단됩니다. 기존 callback도 UI 반영을 main queue에서 수행해 `@Published` mutation 경계를 유지합니다.
- 순수 테스트는 실제 production `HoguNavigationSearchResponseGate`로 A success stale, A error stale, 같은 query target 변경 stale, active token 수용을 직접 검증합니다. compass 72pt, 12-result/dedupe 정책과 기존 테스트도 유지됩니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 실제 MapKit 자동완성에서 빠른 A→B 입력·origin/destination 전환·dismiss/선택 중 stale 결과 또는 오류가 보이지 않는지와, 현재 query 결과가 정상 표시되는지를 확인해야 합니다.

---

## QA Test-build blocker — product/module/host 재리뷰

- reviewed_at: `2026-07-29 15:36 KST`
- scope: HoguMeterTests Debug/Release product·module·test host, productRef/scheme/PBX target 참조, routePreview guard
- verification: `project.pbxproj` target/configuration/reference 정적 대조, scheme XML `xmllint --noout`, `plutil -lint project.pbxproj`, `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- HoguMeterTests target의 Debug와 Release 모두 `PRODUCT_NAME = HoguMeterTests`, `PRODUCT_MODULE_NAME = HoguMeterTests`, bundle id `com.devbada.HoguMeterTests`를 사용합니다. 따라서 app `HoguMeter` module 및 `HoguMeter.swiftmodule` 산출물과 test module/output이 분리됩니다.
- target product reference UUID `DF6AB6681D6D5F3043F077C3`의 path, Products group, PBXNativeTarget `productReference`, scheme TestableReference가 모두 `HoguMeterTests.xctest`로 일치합니다. 이전 `HoguMeter.xctest` 참조는 남아 있지 않습니다.
- unit-test target은 app target `HoguMeter`에 PBXTargetDependency를 유지하고, Debug/Release 모두 `TEST_HOST = $(BUILT_PRODUCTS_DIR)/HoguMeter.app/HoguMeter`, `BUNDLE_LOADER = $(TEST_HOST)`를 유지합니다. scheme의 MacroExpansion과 runnable app도 `HoguMeter.app`, TestableReference만 `HoguMeterTests.xctest`여서 `@testable import HoguMeter` host 관계가 보존됩니다.
- HoguMeterTests source build phase와 target UUID는 변경되지 않았고, 기존 performance file의 app target membership UUID도 중복·고아 없이 유지됩니다. scheme XML/project plist 문법 검증을 통과했습니다.
- `handleRouteDeviationIfNeeded`의 guard는 unused binding `guard let routePreview`에서 `routePreview != nil`로만 변경됐습니다. 이후 route preview 값을 참조하지 않으므로 nil 차단/nonnull 통과 조건과 재탐색 흐름은 동일합니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 실제 Debug/Release test build에서 test bundle이 `HoguMeterTests.xctest`로 생성되고 `@testable import HoguMeter` 및 host loading이 정상 동작하는지 확인해야 합니다.

---

## QA Test-build blocker — Swift Testing mutating macro isolation 재리뷰

- reviewed_at: `2026-07-29 15:46 KST`
- scope: `HoguMeterTests.swift` thermal controller/scheduler/render budget의 mutating 호출 선평가 및 macro assertion 동등성
- verification: 관련 테스트 337~430행과 test file 전체 macro 패턴 정적 대조, `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- thermal controller는 `receive(.serious) → receive(.nominal) → advance(30s) → advance(31s)` 순서가 그대로이며, 각 mutating 반환값만 local로 먼저 평가한 뒤 기존과 같은 expected level을 assertion합니다.
- scheduler는 첫 schedule 결과를 local optional에 저장한 뒤 `#require`로 unwrap하고, 동일 후보 schedule은 그 다음에 실행해 `nil`을 검증합니다. 후보 교체와 cancel 뒤 stale generation 거부도 기존 상태 전이·assertion 의미를 유지합니다.
- render budget의 camera 판단 4회와 overlay 판단은 기존 순서를 유지합니다. `recordOverlay(progressDistance: 0, at: start)`는 initial overlay 허용 판단 후, throttled/permitted overlay 판단 전에 그대로 실행됩니다.
- `#expect`/`#require` 안에 thermal controller의 `receive/advance`, recovery scheduler의 `schedule`, render budget의 `shouldUpdateCamera/shouldUpdateOverlay/recordOverlay` mutating 호출은 남아 있지 않습니다. 매크로에는 local 값 또는 nonmutating 검증만 전달됩니다.
- 제품 코드는 변경되지 않았고, DEV_HANDOFF의 수정 범위·검증 기록도 현재 변경과 일치합니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 Swift Testing target의 실제 컴파일과 관련 pure tests 실행을 확인해야 합니다.

---

## Simulator Test P1 — RouteSampleSelector early-return 재리뷰

- reviewed_at: `2026-07-29 16:11 KST`
- scope: `HoguNavigationRouteSampleSelector.representativeCoordinates`의 small-input dedupe, sampling/max/first-order 계약 및 경계 테스트
- verification: production selector와 유일한 production call site, 관련 pure tests 정적 대조 및 `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- `maximumCount <= 0` 또는 빈 입력은 즉시 빈 배열을 반환합니다. `coordinates.count <= maximumCount`는 더 이상 조기 반환하지 않고 전체 입력을 `samples`로 정한 뒤 공통 25m 미만 dedupe 단계로 통과합니다.
- count가 limit보다 크면 기존의 첫·중간·끝 균등 sampling 식을 유지합니다. `maximumCount == 1`은 첫 좌표 하나만 sample하고, 이후 dedupe해 첫 좌표 계약을 보존합니다.
- dedupe reduce는 최초 등장 순서대로 추가하고 가까운 후속 좌표만 제거합니다. sample 후보 자체가 maximumCount 이하이므로 최종 결과도 항상 maximumCount 이하입니다.
- 기존 9개/3개 sample의 `[0, 4, 8]` 의미와 `count == maximumCount`인 25m 중복 제거 회귀 테스트가 유지됩니다. 빈 입력, 0/음수 limit, max 1의 첫 좌표 경계가 추가되어 이전 Simulator 실패 원인을 직접 덮습니다.
- selector의 production 사용처는 route geocode sample 생성 한 곳뿐이며, 다른 경로 로직 변경은 없습니다. DEV_HANDOFF의 수정 범위·계약 설명도 현재 구현과 일치합니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 Simulator에서 RouteSampleSelector pure tests와 실제 route geocode sample 동작을 실행 확인해야 합니다.

---

## Navigation Estimate Reset — routeSummary 잔존 / 일반 계산 stale gate 재리뷰

- reviewed_at: `2026-07-29 16:31 KST`
- scope: query/endpoint 변경 preview 제거, 명시 reset UI, 일반 `MKDirections` generation gate, current-location·reroute·stop 정책, pure tests
- verification: `HoguNavigationViewModel`, `HoguNavigationView`, `HoguMeterTests` 정적 호출·상태 전이 대조 및 `git diff --check` 통과. 빌드·테스트·커밋·푸시는 CODE_REVIEWER 범위에서 실행하지 않았습니다.

### 확인 결과

- 실제 TextField query 변경 경로인 `updateSearchQuery`는 시작 즉시 `clearRouteCalculationResult()`를 호출합니다. 이는 active general `MKDirections`를 cancel하고 generation을 무효화한 뒤 preview/index/frame/guidance/camera preview 상태를 제거하므로, routeSummary가 자동완성 목록 공간을 계속 차지하지 않습니다. 빈 query도 이후 recent suggestions를 다시 채웁니다.
- `focusSearch`는 search response만 초기화하고 route calculation result를 지우지 않아 단순 focus는 reset하지 않습니다. `prepareOnAppear`도 `clearRoutePreview: false`를 유지합니다. 사용자 current-location 출발지 선택은 `true`로 clear하며, 검색 결과/최근 장소 적용 및 최근 경로 적용도 preview 제거 또는 calculation invalidation 경로를 거칩니다.
- `HoguNavigationRouteCalculationGate`는 새 계산 start와 reset/query/endpoint 변경 invalidate에 generation을 증가시킵니다. 일반 directions completion은 main queue에서 generation 일치를 먼저 guard한 뒤에만 active directions·`isCalculatingRoute`·success/error state를 변경하므로 cancel callback, 이전 success/error, endpoint 변경 뒤 callback은 모두 반영되지 않습니다. 새 계산은 기존 directions cancel 후 새 generation을 발급합니다.
- `resetRouteCalculationResult`는 비주행에서만 동작하며 preview/tracking state만 제거합니다. origin/destination text·map item·recent 저장은 보존되어 즉시 재계산할 수 있고, `stopNavigation`은 변경되지 않아 안내 종료 정책도 유지됩니다. reroute용 directions 경로는 별도로 유지됩니다.
- 비주행 routeSummary에 secondary plain reset 버튼이 추가됐고, label/hint가 “출발지와 목적지는 유지하고 계산 결과만 지움”을 명시합니다. routeSummary 자체가 non-navigation 분기에서만 표시돼 안내 중에는 노출되지 않습니다.
- 실제 production gate를 사용하는 pure tests가 active success 수용, reset 후 stale 차단, 새 계산의 이전 generation 차단을 검증합니다. production completion은 error branch보다 앞의 동일 gate guard를 사용하므로 old error도 같은 방식으로 차단됩니다.

### 판정

`PASS — READY_FOR_QA / QA_AGENT`

QA는 screenshot 재현 상태에서 목적지 편집/키보드·빈 query·current location 선택·명시 reset·빠른 연속 계산을 실행해 routeSummary 및 stale success/error가 재등장하지 않는지 확인해야 합니다.
