# QA REPORT

- phase: `HOGU-NAVIGATION-THERMAL-OPTIMIZATION`
- status: `USER_QA_REQUIRED`
- owner: `USER`
- updated_at: `2026-07-29 16:38 KST`
- scope: THERMAL-01~07, 요구사항 HTML/첨부 화면, 현재 미커밋 diff, `HoguMeter` scheme 및 `HoguMeterTests` target

## LOOP 최종 QA (2026-07-29 16:38 KST)

`USER_QA_REQUIRED / USER`

- app build: `xcodebuild build -project HoguMeter.xcodeproj -scheme HoguMeter -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`: exit 0, `** BUILD SUCCEEDED **`.
- test bundle compile: `xcodebuild build-for-testing -quiet -project HoguMeter.xcodeproj -scheme HoguMeter -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`: exit 0.
- 전체 test suite: `xcodebuild test-without-building -quiet -project HoguMeter.xcodeproj -scheme HoguMeter -configuration Debug -destination 'id=CF7A1AE6-F593-4C6D-B0FB-4BFB63C038CA' CODE_SIGNING_ALLOWED=NO`: exit 0, elapsed `172.146s`.
- reset round 최신 test: `xcodebuild test-without-building -quiet ... -destination 'iPhone 16 Plus (CF7A1AE6-F593-4C6D-B0FB-4BFB63C038CA)' CODE_SIGNING_ALLOWED=NO`: 전체 suite exit 0, elapsed `26.999s`.
- RouteSampleSelector P1: 첫 실패 케이스였던 `routeSampleSelector_25m이내중복좌표를제거한다`를 포함해 전체 suite가 재통과했습니다.
- 비차단 경고: `MockCLLocationManager.swift:47,55`의 conditional downcast 2건만 관측됐습니다. 이번 요구사항과 무관하며 컴파일·test bundle 생성을 차단하지 않습니다.
- 최신 build-for-testing 비차단 경고: `SpeedCameraAPIClient.swift:162`의 unnecessary `await` 1건입니다. 동작·test bundle 생성과 무관합니다.
- 빌드 로그에서 기존 `MeterViewModel` Timer actor-isolation error, `.previewDevice` warning, `AccentColor` warning이 재발하지 않았습니다.
- 후속 `HoguNavigationPerformanceMonitor` `StaticString` signpost name 및 `SpeedCameraAPIClient` `Task<Result<...>, Never>`/`Date` sendability 컴파일 오류도 재발하지 않았습니다.
- `git diff --check`: 통과. 제품 코드·커밋·푸시는 QA에서 수행하지 않았습니다.

## 최종 판정

`USER_QA_REQUIRED / USER`

이전 P1인 `HoguNavigationPerformanceMonitor.swift` app target 미포함과 RouteSampleSelector small-input early-return P1은 해소됐습니다. app build, build-for-testing, 전체 test suite는 성공했고 정적 P1/P2는 발견하지 못했습니다. UI screenshot comparator와 실기기 발열·충전·주행 시각 검증은 사용자 게이트로 남습니다. 제품 코드·커밋·푸시는 수행하지 않았습니다.

## P1 수정 재검증

- `HoguNavigationPerformanceMonitor.swift`, `HoguNavigationOptimizationFlags.swift`는 각각 PBXFileReference 1개, PBXBuildFile 1개, `HoguMeter` app `PBXSourcesBuildPhase` 등록 1개를 가집니다.
- 두 파일은 `Core/Performance` group의 정확한 상대 path에 있고 `HoguMeterTests` Sources에는 포함되지 않습니다.
- `plutil -lint HoguMeter.xcodeproj/project.pbxproj`: 통과.
- `git diff --check`: 통과.

## 정적 컴파일·회귀 검토

- 배포 기준: iOS `17.0`, Swift `5.9`. `actor`, `Task`, Swift Testing async API, `ProcessInfo.thermalStateDidChangeNotification`, MapKit camera, `os.signpost`/`OSSignpostID`는 배포 기준과 호환됩니다.
- 테스트: `HoguMeterTests.swift`는 test target Sources에 등록돼 있고 `Testing`, `CoreLocation`, `Combine`, `@testable import HoguMeter`를 포함합니다. actor 호출은 async context에서 `await`로 사용됩니다.
- 위치: shared-location flag 활성 주행은 navigation own manager callback을 차단하고 `LocationService` publisher를 구독합니다. one-shot은 session generation으로 start/stop/restart stale callback을 차단합니다.
- projection: `RouteProjectionIndex`가 경로 변경 시 캐시를 만들고 `handleLocation`의 주행 이벤트에서 한 번 투영해 `NavigationFrame`으로 guidance·speed camera·MapView에 전달합니다.
- speed camera: route/camera 변경 시 background projection index를 만들고, GPS callback은 frame progress에서 앞 후보 최대 3개만 판정합니다. actor client는 TTL, failure backoff, in-flight requestID owner completion을 사용합니다.
- render/thermal: camera 0.5~2Hz, 5m/3도, overlay 10m/1초 이상 budget, 중첩 animation 제거, nominal/fair/serious/critical 정책과 30초 recovery hysteresis를 확인했습니다.
- privacy: Release performance monitor는 no-op이며 signpost payload는 count·thermal level만 기록합니다. raw coordinate, address, road, camera ID 기록은 확인되지 않았습니다.
- 화면 요구사항: camera focus `0.24`로 차량 약 10px 상향 의도, 주행 화면의 tab bar local visibility, geometry maneuver SSOT의 문구·아이콘 연결을 정적으로 확인했습니다.

## 자동완성·방위 UI 정적 QA

- compass clearance: 검색 패널은 `searchPanelCompassClearance = 72`을 top padding에 적용합니다. Map compass와 검색 패널의 직접 겹침 회피 의도를 코드에서 확인했습니다.
- 자동완성 목록: `ScrollView` 안 `LazyVStack`으로 렌더링되며, 결과는 `HoguNavigationSearchResultPolicy.visibleLimit == 12`로 제한됩니다.
- 중복 정책: title/subtitle 정규화 후 최초 결과만 유지하고, 같은 title이라도 subtitle이 다르면 유지하는 unit test가 있습니다.
- stale response: query·target·generation token을 묶은 `HoguNavigationSearchResponseGate`가 이전 성공/오류 응답과 target 변경 응답을 차단하며, 해당 시나리오 test가 있습니다.
- test target: `HoguMeterTests.swift`는 `HoguMeterTests` Sources build phase에 등록됐고 `build-for-testing` 성공으로 bundle compile까지 확인됐습니다.

## Navigation Estimate Reset 정적·런타임 논리 QA

- 재현 상태: 목적지 query를 편집하고 keyboard가 열린 상태에서 이전 `routeSummary`가 남아 자동완성 영역을 가리는 시나리오를 기준으로 확인했습니다.
- 실제 query 변경은 같은 event 경로에서 `routePreview`를 즉시 clear하므로, `searchList`가 해제된 영역을 차지할 수 있습니다.
- 빈 query는 recent suggestions를 표시하는 정책을 유지합니다.
- 명시 reset은 출발지·목적지 endpoint를 보존하면서 preview/estimate만 숨기는 정책입니다.
- query·target·generation stale-response gate 및 reset 관련 테스트가 존재하며, 최신 전체 suite 통과에 포함됩니다.

## 실제 렌더·실기 검증 미완료

app build, test bundle compile, 전체 test suite는 성공했습니다. 다만 실제 UI screenshot comparator와 실기기 발열·충전 검증은 수행하지 않았습니다.

```sh
실기 iPhone에서 HoguMeter와 Apple 지도 동일 조건 A/B 20분 주행
```

UI screenshot comparator와 실제 iPhone 발열/충전 결과를 수집해야 합니다.

## TODO-minam — 실기기 최종 QA

- [ ] P1 수정본을 동일 iPhone/iOS에서 build·설치하고 `HoguMeterTests/HoguMeterTests` focused test 실행
- [ ] 검색 패널·compass 72pt clearance, 자동완성 12건 ScrollView scroll, 중복 결과 제거, 빠른 검색어/출발지·도착지 전환의 stale 결과 미표시를 screenshot으로 확인
- [ ] 경로를 한 번 계산한 뒤 목적지를 탭해 삭제/재입력: summary가 즉시 사라지고 keyboard 위에서 자동완성 12건을 scroll할 수 있는지 동일 상태 screenshot으로 확인
- [ ] reset 버튼: 출발지·목적지는 남고 summary/estimate만 즉시 숨겨지는지 확인
- [ ] 차량 아이콘이 이전 대비 약 10px 위에 안정적으로 보이는지 확인
- [ ] 주행 시작 시 하단 `미터기 | 호구게이션 | 기록 | 통계 | 설정` tab bar가 숨겨지고, 우하단 토글·종료에서 복원되는지 확인
- [ ] 실제 좌회전에서 카드 아이콘·방향 문구·경로 geometry가 모두 좌회전인지 확인
- [ ] same-region/cross-region reroute에서 speed-camera warning이 stale 상태로 남지 않는지 확인
- [ ] 동일 iPhone 모델·iOS·HoguMeter build 번호, 화면 밝기 50%, 케이스, 외기/차량 온도, 네트워크를 기록
- [ ] 유선과 MagSafe/무선 각각 충전 방식·충전기 출력·충전 보류 문구/발생 시각을 기록
- [ ] HoguMeter와 Apple 지도를 동일 경로·시간대에 각 20분씩 3회 실행
- [ ] 시작/종료 배터리, surface temperature, `thermalState` 변화 시각, 충전 보류 여부를 기록
- [ ] Energy Log/Power Profiler, Time Profiler, Core Animation/Display, Network trace 및 signpost를 수집
- [ ] 중앙값 기준: 20분 내 `.serious`/`.critical` 미진입, Apple 지도 대비 온도 `+3°C` 이내, 배터리 소모 `1.25배` 이내, 제어된 유선 충전에서 보류 미발생 확인

## 완료 조건

실기기 자동 test/build와 위 A/B·충전 검증을 완료한 뒤에만 `COMPLETE / DONE`으로 전환합니다.
