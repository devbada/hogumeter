# DEVELOPER HANDOFF

- status: `READY_FOR_CODE_REVIEW`
- owner: `CODE_REVIEWER`
- updated_at: `2026-07-29 10:22 KST`

## 변경 파일

- `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift`
- `HoguMeter/Presentation/Views/HoguNavigation/HoguNavigationView.swift`
- `HoguMeter/Presentation/Views/ContentView.swift`
- `HoguMeter/Core/Extensions/Notification+Extensions.swift`

## 요구사항별 구현 근거

1. 차량 기준점을 하단 요약창 쪽으로 이동: 주행 카메라가 차량 진행방향 앞쪽을 바라보게 하여 차량이 화면 하단에 위치하도록 구성했습니다.
2. 다음 안내 실시간 갱신: GPS 위치를 경로 진행거리로 정규화하고, 다음 `MKRoute.Step`의 회전 문구와 남은 거리를 갱신합니다.
3. 경로선 차량 표시/방향: 가장 가까운 경로 세그먼트 투영점(90m 이내)을 차량 아이콘 및 카메라 중심에 사용하고 GPS course 또는 경로 heading을 적용합니다.
4. 남은 거리·시간·예상 호구비 실시간 갱신: 현재 구간의 원래 거리/ETA와 진행률을 분리해 하단 요약을 GPS마다 갱신합니다.
5. 재탐색 비용 보존: 재탐색 전 진행거리/ETA를 `accumulated*`로 새 구간에 이월하고, 전체 거리·시간으로 예상 호구비를 다시 계산합니다.
6. 하단 탭 숨김/복원: 주행 시작/종료 알림으로 `TabView` 탭바를 숨김/복원하고, 주행 화면 우하단 작은 토글에서 직접 전환합니다.
7. 상단 호구게이션 영역 숨김: 주행 중 navigation bar/title을 숨깁니다.

## 검증

- `git diff --check`: 통과.
- 요구사항 관련 구조·호출부 정적 검색: 완료.
- `xcodebuild -project HoguMeter.xcodeproj -scheme HoguMeter -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO`: Sandbox에서는 Xcode module cache/Simulator 접근 권한 오류. 권한 확장 후 재실행은 약 410초 뒤 사용자 중단. 성공/실패 컴파일 판정 없음.

## 남은 위험 / Code Review 요청

- 실제 iOS 기기 또는 정상 Simulator에서 컴파일·주행 GPS 시뮬레이션 필요.
- 재탐색 순간의 누적 예상비와 실제 미터기 비용의 허용 오차는 실제 요금 정책/시간대 데이터로 QA 확인 필요.
- 기존 미커밋 변경(`SpeedCameraAPIClient`, `Info.plist`, `MainMeterView`, HTML preview)은 보존했으며 이 개발 handoff에서 되돌리지 않았습니다.

## FIX Round 1 — CODE_REVIEW P1/P2 반영

- updated_at: `2026-07-29 10:31 KST`
- P1: `HoguNavigationRouteProjector`를 추가했습니다. 폴리라인 꼭짓점이 아닌 각 선분 투영점의 거리·진행거리·heading을 계산하며, 이탈 판정, 다음 안내/요약 갱신, 속도카메라 경로 앞 거리, 차량 스냅, 경과/잔여 overlay가 동일 결과를 사용합니다.
- P2: 최근 route 선택은 저장한 출발지·목적지를 함께 복원하고 즉시 계산하도록 복구했습니다.
- P2: `hasUsableCourse`를 별도 상태로 전달했습니다. `CLLocation.course`가 무효이거나 저속이면 차량/camera heading이 경로 선분 heading으로 fallback합니다.
- P2: 새 경로 계산·새 안내 시작·안내 종료·입력 변경에서는 reroute cooldown을 초기화합니다. 같은 주행의 reroute 성공 직후에는 cooldown을 유지합니다.
- 테스트: 기존 test target에 `HoguNavigationRouteProjector` 긴 선분 중간 진행거리/heading, 120m 이탈 경계 단위 테스트 2건을 추가했습니다.
- 검증: `git diff --check` 통과. 직전 Xcode build는 환경/사용자 중단으로 판정이 없어 이번 라운드에서 장시간 재실행하지 않았습니다. Code Reviewer는 정상 Simulator 또는 실기기에서 새 테스트와 GPS 시각 QA를 실행해야 합니다.

## FIX Round 2 — optional routePreview 컴파일 수정

- updated_at: `2026-07-29 10:33 KST`
- `updateUIView`가 언래핑한 `routePreview`를 `updateVehicleAnnotation(_:context:routePreview:)`의 non-optional 인자로 명시 전달하도록 수정했습니다.
- 차량 스냅·heading 헬퍼는 이제 동일한 non-optional 경로 preview를 사용합니다.
- 검증: 호출부/시그니처 정적 검색 및 `git diff --check` 통과. Xcode build는 이전 환경/사용자 중단 이력으로 재실행하지 않았습니다.

## USER QA FIX Round 3

- updated_at: `2026-07-29 10:46 KST`
- 차량 아이콘: 차량 annotation anchor는 지도 좌표 자체에 고정되어 있어 화면 높이는 카메라 focus가 결정합니다. 진행방향 전방 focus offset을 카메라 거리의 `28%`에서 `24%`로 줄였습니다. 차량 기준점이 약 10px 위로 이동하면서 전방 지도 확보는 유지합니다.
- TabView 탭바: 기존 `.toolbar(..., for: .tabBar)`는 `ContentView`의 `TabView` 바깥에 적용되어 선택된 호구게이션 화면의 toolbar preference로 반영되지 않았습니다. modifier를 실제 `HoguNavigationView`의 `NavigationView` 계층으로 이동했습니다. 주행 시작 시 숨김, 작은 우하단 컨트롤 토글 시 복원/재숨김, 주행 종료 시 복원이 같은 로컬 상태로 적용됩니다.
- 검증: 탭바 visibility modifier가 단일 화면 계층에만 존재하는 것과 주행 상태/컨트롤 상태 연결을 정적 확인했습니다. `git diff --check` 통과. Simulator/실기기 시각 확인은 USER QA가 필요합니다.

## USER QA FIX Round 4 — geometry maneuver SSOT

- updated_at: `2026-07-29 11:06 KST`
- 원인: 기존 구현은 `MKRoute.Step.instructions` 원문으로 문구를 저장하고 UI가 한글 좌/우 문자열을 다시 파싱해 아이콘을 골랐습니다. Step 경계 geometry와 독립된 두 판단 경로여서 이미지처럼 문구/아이콘과 실제 좌회전 경로가 불일치할 수 있었습니다.
- 수정: 각 MapKit step의 polyline에서 짧은 중복점을 건너뛴 진입/진출 heading을 구하고, heading 변화량으로 `left/right/straight/uTurn` maneuver를 모델링했습니다. `HoguNavigationRouteStep`, ViewModel 상태, 카드 아이콘이 이 단일 maneuver를 사용합니다.
- 안전 교정: geometry가 충분히 큰 회전(35도 이상)을 가리키고 원문 방향과 충돌할 때만 geometry를 우선합니다. 원문의 도로명/진입 정보는 보존하고 방향 토큰만 제거해 geometry 방향을 앞에 표시합니다. geometry가 짧거나 직진 수준이면 원문을 유지합니다.
- 테스트: 좌/우/직진 heading 분류와 `완만히 우회전하여 양화로로 진입` 원문이 geometry 좌회전일 때 좌회전 문구·아이콘 모델로 함께 교정되는 회귀 테스트를 추가했습니다.
- 검증: `git diff --check` 통과. Simulator 환경 문제로 focused test 실행은 QA에서 필요합니다.

## FIX Round 4-3 — 언어 fallback / step boundary helper

- updated_at: `2026-07-29 11:22 KST`
- 영문 또는 방향 없는 원문은 `우회전 Continue...`처럼 혼합하지 않고 geometry 방향 단독 한국어 문구를 표시합니다. 원문 도로명은 이 경우 표시하지 않는 tradeoff이며, 방향과 아이콘의 불일치를 피하는 것을 우선합니다. 한국어 원문 도로명은 기존대로 보존합니다.
- `HoguNavigationStepBoundaryResolver`를 추출했습니다. 이전 step 마지막 유효 선분과 현재 step 첫 유효 선분만으로 maneuver를 산정하고, 중복/5m 미만 좌표와 step 내부 뒤쪽 곡률은 배제합니다.
- 테스트: 영문 fallback 최종 문자열 `우회전`, step boundary의 중복/5m 미만 좌표 skip과 내부 곡률 배제 검증을 추가했습니다.

## FIX Round 4-4 — next-step 정렬 고정

- updated_at: `2026-07-29 11:25 KST`
- `HoguNavigationGuidanceSelector`를 추가했습니다. `startDistance > progress + 25m` 선택 기준을 순수 helper 하나로 고정했습니다.
- `updateRouteGuidance`는 helper가 반환한 단일 `HoguNavigationRouteStep`에서 instruction, maneuver, distance를 함께 가져와 세 published 값에 적용합니다.
- 테스트: progress+25m 직전(선택), 동일 경계(다음 step 선택)에서 instruction/maneuver/반환 distance가 같은 step에 정렬되는지 검증했습니다.

## FIX Round 4-2 — maneuver 문구/경계 회귀 보강

- updated_at: `2026-07-29 11:18 KST`
- geometry가 명확한 좌/우/유턴이면 원문이 방향 토큰 없이 영문이거나 source maneuver를 판별할 수 없어도 geometry 한국어 방향을 문구 앞에 포함하도록 수정했습니다. 동일 방향 원문은 그대로 유지하고, 충돌 원문만 방향 토큰을 제거하므로 중복 표기를 만들지 않습니다.
- 테스트 추가: 북쪽 0도 경계 좌/우 wraparound, 유턴, 영문 원문에서 문구와 아이콘 SSOT, 중복/5m 미만 좌표가 있는 route projection 진행거리.
- 검증: `git diff --check` 통과. Simulator 환경 문제로 focused test 실행은 QA에서 필요합니다.
- Thermal Round 1-B: navigation 시작 뒤 자체 `CLLocationManager` 연속 업데이트를 시작하지 않고, `MeterViewModel.locationService.locationPublisher`를 주입·구독합니다. one-shot delegate callback은 navigation 시작 뒤 무시해 경쟁을 막고 종료 시 Combine 구독을 취소합니다. Phase C projection cache는 후속 round로 이월했습니다.
- Thermal Round 1-B Fix: shared publisher 구독을 start notification보다 먼저 설정해 첫 위치 유실을 막았습니다. one-shot callback은 main queue 처리 시점에 navigation 상태와 session generation을 재검증해 start/stop/restart 경쟁에서 shared stream과 중복 처리되지 않습니다.
- Thermal Round 1-B Fix2: lifecycle generation gate의 subscribe-before-start, delayed one-shot invalidation, start-stop-start stale callback, stop invalidation 테스트를 추가했습니다.
- Thermal Round 1-B Fix3: ViewModel의 generation Int를 제거하고 production `HoguNavigationLocationSessionGate` 인스턴스를 start/stop/one-shot main-queue 검증의 단일 source of truth로 사용합니다.

## Thermal Round 2-C — RouteProjectionIndex / NavigationFrame 실제 연결

- updated_at: `2026-07-29 12:05 KST`
- 경로 미리보기 생성과 재탐색 성공 시 `RouteProjectionIndex`를 한 번 재구축합니다. 입력 변경/현재 위치 출발지 재설정/안내 종료 시 index와 frame을 함께 무효화합니다. 진행에 따라 `routePreview` 요약만 갱신할 때는 동일 polyline index를 유지합니다.
- `handleLocation`은 안내 중 `routeProjectionIndex.project(location)`을 정확히 한 번 호출해 `HoguNavigationFrame`으로 발행합니다. 이탈 판정과 안내/요약 갱신은 같은 projection 인자를 사용합니다.
- `HoguNavigationMapView`는 frame의 투영 좌표와 heading을 overlay, 차량 annotation, 저속 heading fallback, camera focus에 공유합니다. 지도 내부의 위치 갱신별 `HoguNavigationRouteProjector.project` 호출은 제거했습니다.
- `RouteProjectionIndex`는 경로 변경 시 만든 `MKMapPoint`, 선분 거리, 누적 거리, heading 배열을 재사용합니다. duplicate/0m 선분은 baseline projector와 같이 건너뜁니다.
- 테스트 추가: index-vs-baseline 결과, duplicate segment parity, 위치당 단일 projection/frame 재사용 request count, 재탐색용 새 index 분리를 검증합니다.
- 검증: `git diff --check` 통과. `xcodebuild test -project HoguMeter.xcodeproj -scheme HoguMeter -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:HoguMeterTests/HoguMeterTests`는 권한 확장 환경에서 package graph resolve까지 정상 종료(exit 0)했으나 test execution summary가 출력되지 않아 개별 테스트 실행 증거로는 불충분합니다. Code Review/QA에서 정상 Simulator 또는 실기기로 재확인 필요합니다.
- 범위 외 기존 미커밋 변경은 보존했습니다. 커밋·푸시하지 않았습니다.

## Thermal Round 2-C P1 Fix / Phase D — Speed Camera Route Index

- updated_at: `2026-07-29 12:22 KST`
- P1 해소: GPS callback의 `updateSpeedCameraWarning`은 `NavigationFrame.projection`만 사용합니다. 기존 `routeAheadDistance`와 callback 내부 `HoguNavigationRouteProjector.project` 재호출을 제거했습니다. 따라서 주행 위치 이벤트의 route projection은 `handleLocation`의 `routeProjectionIndex.project(location)` 한 번뿐입니다.
- 경로 생성·재탐색·카메라 목록 갱신 시, bbox 후보를 background utility queue에서 별도 snapshot index로 미리 투영합니다. 경로에서 160m 초과인 카메라는 제외하고 progressDistance 오름차순으로 저장합니다.
- GPS callback은 frame progress를 binary search하여 뒤 카메라를 제외한 앞쪽 최대 3개만 거리·방향·600m 경고 범위로 판정합니다.
- `HoguNavigationSpeedCameraPrecomputeGate` generation을 경로 재생성·clear·stop·candidate refresh 때 무효화합니다. 이전 route의 background 결과는 main queue 반영 전에 차단합니다.
- 테스트 추가: camera progress 순서, 160m route 거리 필터, behind camera 제외, 최대 3개 제한, stale precompute gate 차단. 기존 index parity/duplicate/frame 단일 request/새 route index 테스트는 유지합니다.
- 검증: `git diff --check` 통과. 추가 build/test는 상위 지시에 따라 실행하지 않았습니다. 이전 Round 2-C 범위의 Simulator generic build는 성공했으나 새 test bundle 실행은 QA가 정상 Simulator에서 재확인해야 합니다.
- 커밋·푸시하지 않았고, 범위 외 미커밋 변경을 보존했습니다.

## Thermal Phase E+F — Render Budget / Thermal Adaptation

- updated_at: `2026-07-29 12:42 KST`
- camera: `HoguNavigationRenderBudget`이 기본 2Hz, fair/serious 1Hz, critical 0.5Hz를 적용합니다. 마지막 반영 뒤 5m 이동 또는 3도 heading 변화가 있어야 갱신하며, 장시간 정지 때는 3초마다 최소 갱신합니다. 중첩 `UIView.animate + setCamera(animated:)`를 제거하고 MapKit camera animation 한 방식만 사용합니다.
- overlay: 진행거리 10m 이상 및 1초 이상 간격에서만 재구축합니다. serious는 15m/1.5초, critical은 route 변경 외 진행 overlay 갱신을 중단합니다.
- vehicle: animation은 0.25초로 단축하고 serious/critical에서는 즉시 위치 반영합니다.
- thermal: `ProcessInfo.thermalStateDidChangeNotification` observer를 ViewModel lifecycle에 연결하고 deinit에서 제거합니다. 저하는 즉시 적용하며, 복구는 30초 안정화 뒤 적용합니다. nominal/fair/serious/critical별 camera, overlay, pitch, POI, map/vehicle animation, HUD material 정책을 `HoguNavigationEnergyPolicy`로 명시했습니다.
- serious/critical: POI 제거, HUD의 material blur를 불투명 배경으로 전환합니다. serious는 pitch 35도·camera 1Hz, critical은 2D pitch·camera 0.5Hz·진행 overlay 중단입니다. 안내·이탈·speed camera safety path는 ViewModel에서 계속 실행됩니다.
- 테스트 추가: thermal policy 경계, 즉시 저하/30초 복구 hysteresis, camera 2Hz·3도 heading 및 overlay 1초/10m budget을 pure helper로 검증합니다.
- 검증: `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push는 실행하지 않았습니다. TODO-minam: 실기기 장시간 충전 주행에서 serious/critical 전환, 지도 가독성, 차량 위치/좌우 안내/탭바 유지 확인 필요.

## Thermal Phase E+F P2 — Recovery 예약 단일화

- updated_at: `2026-07-29 12:52 KST`
- `HoguNavigationThermalRecoveryScheduler`를 추가해 recovery 후보·deadline·generation을 단일 source of truth로 관리합니다. 동일 후보/deadline notification은 새 work item을 예약하지 않습니다.
- fair→nominal처럼 후보가 바뀌면 기존 `DispatchWorkItem`을 cancel하고 새 generation으로 교체합니다. serious/critical 등 재악화 또는 observer deinit에서는 work item과 scheduler를 즉시 cancel/invalidate합니다.
- 30초 callback은 captured generation, candidate, deadline 경과 및 현재 raw thermal state가 candidate와 같은 경우에만 recovery policy를 적용합니다. stale callback은 무시됩니다.
- 테스트 추가: 동일 recovery 반복 단일 예약, fair→nominal 후보 교체, cancel 뒤 stale callback 거부를 pure scheduler로 검증합니다.
- 검증: `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push는 실행하지 않았습니다.

## Thermal Phase A+G — 계측 / Geocode·Camera 요청 절감 / Rollback Flags

- updated_at: `2026-07-29 13:08 KST`
- `HoguNavigationPerformanceMonitor`는 location callback, route projection, guidance, speed camera, map update, overlay rebuild, camera update signpost를 기록합니다. 시간·count·thermal level만 기록하며 좌표·주소·도로명·camera ID는 로그에 남기지 않습니다.
- counter event: projector calls, route segments, evaluated camera, overlay replacement, camera update. thermal level도 개인정보 없이 event로 기록합니다.
- route geocode sample은 최대 3개 대표 좌표로 축소했습니다. `SpeedCameraAPIClient`의 기존 region memory cache를 사용하며, 재탐색에서 기존 camera 목록을 즉시 삭제하지 않아 같은 지역 reroute의 재다운로드/공백을 막습니다.
- rollback flags 4개는 UserDefaults 미설정 시 모두 enabled입니다. shared location, route index, camera background index, thermal adaptation 경계에 연결했습니다. serious/critical thermal 보호와 privacy-safe performance logs는 flag로 비활성화하지 않습니다.
- 테스트 추가: 3-point sample selector와 안전 기본 flag. `git diff --check` 통과. build/test/commit/push 미실행.
- TODO-minam: Instruments 실기기에서 signpost count·Energy Log·20분 충전 주행을 A/B 비교합니다.

## Thermal Phase A+G P1/P2 Follow-up

- updated_at: `2026-07-29 13:20 KST`
- route generation과 normalized region-key set을 보관합니다. 동일 region은 기존 목록을 재사용하고, cross-region route는 새 fetch를 허용하며 완료 시 route generation이 일치할 때만 camera 목록·precompute 결과를 atomic replace합니다.
- sample selector는 최대 3개 결과에서 25m 미만 근접 좌표를 geocode 전에 제거합니다.
- release performance monitor는 debug assertion configuration에서만 signpost를 발행합니다. projector counter는 실제 projector 호출 branch에서만 기록합니다.
- `git diff --check` 통과. API client TTL/failure backoff/in-flight request sharing은 별도 P2 검토가 필요합니다. build/test/commit/push 미실행.

## Thermal Phase A+G P2 — Region TTL / Backoff / In-flight Dedupe

- updated_at: `2026-07-29 13:30 KST`
- `SpeedCameraAPIClient`은 region key별 성공 cache에 TTL(일반 10분, 정상 empty response 1분)을 기록합니다. 네트워크 실패 결과는 cache하지 않습니다.
- 실패는 10초부터 지수 backoff를 적용하고 5분에서 cap합니다. 성공 시 failure state를 제거합니다. cooldown 중 요청은 네트워크에 재접속하지 않습니다.
- 동일 region의 동시 요청은 in-flight `Task` 하나를 공유합니다. 완료 뒤에만 cache/failure state를 갱신합니다.
- ViewModel의 route generation/region key stale guard는 유지해 cross-region reroute 결과가 현재 route에만 atomic replace되게 합니다.
- 테스트: pure retry policy의 증가/cap을 추가했습니다. `git diff --check` 통과. build/test/commit/push 미실행.

## Thermal Phase A+G P2 — Async 계약 자동 테스트 / cross-region 즉시 무효화

- updated_at: `2026-07-29 14:05 KST`
- `SpeedCameraAPIClient`의 기존 `regionFetchOverride`·`nowProvider` seam을 사용해 실제 네트워크·sleep 없이 async 계약을 고정했습니다.
- 동일 region 동시 성공/실패 요청은 upstream fetch 1회만 수행하고, 단일 실패 후 backoff 상태도 owner task가 한 번만 반영하는지 검증합니다.
- 한 waiter를 취소해도 unstructured shared request와 다른 waiter는 정상 완료되는지 검증합니다.
- 일반 성공 TTL 10분, 정상 empty TTL 1분, 실패 결과의 성공-cache 미저장과 cooldown 후 retry를 clock test double로 검증합니다.
- multi-region partial failure 뒤 성공 region은 TTL cache를 재사용하고, 실패 region만 cooldown 뒤 재요청하는지 검증합니다.
- route sample 25m dedupe 회귀 테스트는 유지합니다.
- cross-region 전환 시 `HoguNavigationSpeedCameraRegionTransition`이 warning, 마지막 warned ID, 일반/투영 camera candidates와 precompute generation을 fetch 완료 전에 즉시 무효화하도록 ViewModel에 연결했습니다. same-region은 유지합니다.
- 검증: `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행. Code Review에서 Swift Testing target compile 및 runtime 확인이 필요합니다.

## QA P1 — Performance production files target membership

- updated_at: `2026-07-29 14:12 KST`
- `HoguMeter/Core/Performance/HoguNavigationPerformanceMonitor.swift`를 PBXFileReference, PBXBuildFile, `Core/Performance` group, HoguMeter app target Sources phase에 등록했습니다.
- 같은 디렉터리의 신규 production 파일 `HoguNavigationOptimizationFlags.swift`도 동일 group과 app Sources phase에 등록해 target 누락을 함께 해소했습니다.
- 새 UUID 5개는 기존 project에서 미사용임을 확인했습니다. 각 BuildFile UUID는 정의/Sources 2회, group UUID는 Core child/group definition 2회, FileReference UUID는 정의/group/BuildFile reference 3회로 고아·중복 참조가 없습니다.
- `plutil -lint HoguMeter.xcodeproj/project.pbxproj`: 통과.
- `git diff --check`: 통과. 제품 코드/build/test/commit/push 미실행.

## User Build Failure Fix — Timer actor / Preview / AccentColor

- updated_at: `2026-07-29 14:32 KST`
- `MeterViewModel.startTimer`의 `@Sendable` Timer callback은 actor-isolated 상태를 직접 읽지 않습니다. `Task { @MainActor [weak self] in ... }` 내부에서 self와 `tripStartTime`을 확인하고 duration/night/speed-timeout을 갱신하도록 이동했습니다.
- `AppStoreScreenshots.swift`의 `#Preview` 6개에서 deprecated `.previewDevice(...)` 호출만 제거했습니다. Preview 이름과 화면 구성은 유지합니다.
- project build setting의 `AccentColor` 이름과 맞는 `Assets.xcassets/AccentColor.colorset/Contents.json`을 추가했습니다. 기존 주황 계열과 일치하는 universal sRGB system-orange 색상을 사용해 light/dark 모두 같은 accent를 유지합니다.
- Accent JSON은 `jq` 구조 검사를 통과했습니다. 현재 `plutil -lint`가 `.json` 확장자를 직접 plist로 인식하지 않아, `plutil -convert xml1` 변환 후 생성 plist의 `plutil -lint` 통과를 확인했습니다.
- `git diff --check` 통과. build/test/commit/push 미실행.

## User Build Failure Fix P2 — Timer lifecycle generation

- updated_at: `2026-07-29 14:40 KST`
- `MeterTimerGenerationGate`를 추가해 timer start/stop lifecycle을 세대로 구분합니다. `startTimer`는 기존 timer를 먼저 invalidate하고 새 generation을 callback에 값으로 캡처합니다.
- Timer callback의 `Task { @MainActor }`는 captured generation 일치, `.running` 상태, `tripStartTime` 존재를 모두 확인한 뒤에만 duration/night/speed-timeout 상태를 갱신합니다.
- `stopTimer`는 timer invalidate/nil 처리 뒤 generation을 올려 이미 enqueue된 Task를 무효화합니다. `resetMeter`도 먼저 `stopTimer`를 호출해 reset 이후 stale callback을 차단합니다.
- Timer/sleep에 의존하지 않는 pure gate 테스트로 active generation의 허용 조건과 start-stop-start 이후 구 callback 차단을 검증합니다.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## Actual Build P1 — Static signpost names

- updated_at: `2026-07-29 14:50 KST`
- `HoguNavigationPerformanceMonitor.Span`의 `String` raw-value 계약을 제거하고, 각 case를 compile-time `StaticString`으로 대응하는 exhaustive `signpostName` 매핑을 추가했습니다.
- `begin`과 `end`는 같은 `span.signpostName`을 사용하므로 기존 signpost pairing과 명칭은 유지됩니다. 좌표·주소·도로명·camera ID 등 개인정보를 추가하지 않았습니다.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## Actual Build Round 2 P1/P2 — Shared task Result / Sendable clock

- updated_at: `2026-07-29 15:00 KST`
- `SpeedCameraAPIClient`의 신규 in-flight task를 `Task<Result<[SpeedCamera], Error>, Never>`로 명시해 weak-self 조기 반환의 `.failure`까지 concrete `Result` 문맥에서 추론되도록 수정했습니다.
- `nowProvider`의 `@Sendable` 기본값은 initializer 함수 참조 대신 `{ Date() }` closure로 변경해 Swift 5.9 sendability 경고를 제거했습니다.
- actor 내부 task 생성, 동일 region in-flight task 공유, request ID 기반 완료 반영, TTL/backoff 상태 갱신 계약은 유지합니다.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## Navigation Search UI — Compass clearance / 12 results / deduplication

- updated_at: `2026-07-29 15:15 KST`
- 비주행 검색 패널의 상단 여백을 `searchPanelCompassClearance = 72`로 추출·적용해 우측 상단 native MapKit compass의 footprint 아래로 이동했습니다. 검색 패널의 폭과 스타일 및 주행 UI 배치는 변경하지 않았습니다.
- 검색 목록은 `ScrollView + LazyVStack`으로 전환하고 축소 가능한 `maxHeight = 420`을 적용했습니다. 최근 검색은 기존 최대 5건을 유지하며, 자동완성 결과의 visible limit만 6건에서 12건으로 확대했습니다.
- `HoguNavigationSearchResultPolicy`는 title/subtitle을 각각 trim하고 case/diacritic/width insensitive folding한 복합 키로 중복을 제거합니다. 최초 결과 순서를 유지하며, 같은 title이라도 subtitle이 다르면 별도 결과로 남깁니다.
- pure policy 테스트: 정확 중복의 최초 결과 유지, 공백·대소문자·전각·발음부호 정규화 중복, 동일 title/다른 subtitle 유지, 최초 순서와 최대 12건을 추가했습니다.
- TODO-minam: 실제 기기 작은 화면을 포함해 compass와 검색 패널 사이가 12pt 이상인지 확인해 주세요.
- TODO-minam: 실제 기기에서 자동완성 12건이 표시되고 목록 끝까지 스크롤 가능한지 확인해 주세요.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## Navigation Search UI P1 — Response generation gate

- updated_at: `2026-07-29 15:25 KST`
- `HoguNavigationSearchResponseGate`와 query/target/generation token을 production 자동완성 callback에 연결했습니다. focus, clear, 빈 query, 새 nonempty query 및 target 변경 경로에서 generation을 갱신합니다.
- success callback은 진입 시 trim한 `queryFragment`, 선택 target, 현재 generation, results 배열을 값으로 캡처합니다. error callback도 동일 token과 MKError code/localized description을 캡처합니다.
- main queue 반영 직전에 active query, selected target, generation이 모두 token과 일치해야 합니다. 따라서 A callback enqueue 뒤 B query/target으로 바뀌면 A success와 error는 모두 무시됩니다. 검색 결과 선택도 clear 경로로 generation을 무효화합니다.
- MapKit `MKLocalSearchCompleter`는 completion payload별 request ID나 원본 query를 제공하지 않습니다. callback 진입 이전에 이미 바뀐 `queryFragment`와 전달 results의 연관성을 추가로 입증할 수 없는 API 한계가 있으며, callback 진입 이후 발생하는 앱 내부 race는 generation gate로 차단합니다.
- pure gate 테스트: A success stale, A error stale, 동일 query/target 변경 stale, active token accept를 추가했습니다. 기존 compass 72pt, 12건 scroll, dedup 정책과 테스트는 유지합니다.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## QA Test-build P1 — Test product/module output separation

- updated_at: `2026-07-29 15:35 KST`
- `HoguMeterTests` target의 Debug/Release에 `PRODUCT_NAME = HoguMeterTests`, `PRODUCT_MODULE_NAME = HoguMeterTests`를 명시해 app의 `HoguMeter.swiftmodule` 산출물과 충돌하지 않도록 분리했습니다.
- 기존 test product reference UUID와 target membership은 보존하고, PBXFileReference path 및 모든 comment만 `HoguMeterTests.xctest`로 일관되게 수정했습니다.
- `TEST_HOST = $(BUILT_PRODUCTS_DIR)/HoguMeter.app/HoguMeter`와 `BUNDLE_LOADER = $(TEST_HOST)`는 그대로 유지했으며 app target 설정은 변경하지 않았습니다.
- `handleRouteDeviationIfNeeded`의 미사용 `routePreview` 바인딩을 `routePreview != nil` 존재 조건으로 바꿔 경고만 제거했습니다. 이후 로직과 재탐색 동작은 동일합니다.
- `plutil -lint HoguMeter.xcodeproj/project.pbxproj`와 `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## QA Test-build P1 — Swift Testing mutating macro isolation

- updated_at: `2026-07-29 15:45 KST`
- 제품 코드는 변경하지 않고 `HoguMeterTests/HoguMeterTests.swift`만 수정했습니다.
- thermal state controller의 `receive/advance`, recovery scheduler의 `schedule`, render budget의 `shouldUpdateCamera/shouldUpdateOverlay` mutating 호출을 `#expect/#require` 밖에서 기존 상태 전이 순서대로 먼저 평가했습니다. 매크로에는 평가된 local 값만 전달합니다.
- scheduler의 optional generation은 mutating `schedule` 결과를 local에 저장한 뒤 `#require`로 unwrap합니다. overlay의 `recordOverlay`는 기존과 동일하게 initial 판단 뒤, 다음 두 판단 전에 실행됩니다.
- 파일 전체에서 동일한 mutating-in-macro 패턴을 검색했으며 대상 호출이 남아 있지 않음을 확인했습니다. 변경 후 관련 범위는 테스트 파일 337~430행입니다.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## Simulator Test P1 — Route sample dedupe before early return

- updated_at: `2026-07-29 16:10 KST`
- `HoguNavigationRouteSampleSelector.representativeCoordinates`의 `coordinates.count <= maximumCount` 조기 반환을 제거했습니다. 이제 해당 경로도 전체 입력을 대상으로 최초 순서를 유지하며 25m 미만 중복을 제거합니다.
- `maximumCount <= 0` 또는 빈 입력은 빈 배열을 반환합니다. 입력이 제한보다 크면 기존 균등 sampling을 유지하고, 제한이 1이면 첫 좌표를 사용한 뒤 공통 dedupe 단계로 진행합니다.
- sampling 후보는 최대 `maximumCount`개이고 dedupe는 추가만 제거하므로 최종 결과 count가 제한을 넘지 않습니다. 기존 9개 중 3개 대표좌표 `[0, 4, 8]` 계약은 유지됩니다.
- 경계 테스트로 빈 입력, 0/음수 제한, 1개 제한의 첫 좌표 유지를 추가했습니다. 기존 `count == maximumCount`의 25m dedupe 회귀 테스트를 유지합니다.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.

## Navigation Estimate Reset — Explicit reset / stale calculation gate

- updated_at: `2026-07-29 16:30 KST`
- screenshot 근거: 목적지 TextField를 지우고 키보드가 열린 재검색 상태에서도 기존 `29.5km / 47분 / 26,100원` routeSummary와 `안내 시작`이 하단을 계속 차지해 자동완성 목록을 가렸습니다.
- `updateSearchQuery` 진입 즉시 진행 중 일반 경로 계산을 취소·무효화하고 routePreview/index/navigationFrame 및 안내·카메라 preview 상태를 제거합니다. 따라서 실제 출발/도착 text 변경의 같은 UI 흐름에서 routeSummary가 사라집니다. `focusSearch`에는 이 처리를 연결하지 않아 단순 focus만으로 결과가 사라지지 않습니다.
- 비주행 routeSummary의 기존 `안내 시작` 아래에 secondary 버튼 `호구비 계산 초기화`를 추가했습니다. 접근성 label과 “출발지와 목적지는 유지하고 계산 결과만 지웁니다” hint를 제공합니다. routeSummary 자체가 비주행에서만 생성되므로 안내 중에는 reset 버튼이 노출되지 않습니다.
- 명시 reset은 계산 결과와 route tracking preview 상태만 제거합니다. `originText`, `destinationText`, `originMapItem`, `destinationMapItem`, 최근 장소·경로 저장 데이터는 변경하지 않아 바로 재계산할 수 있습니다. `stopNavigation`은 변경하지 않아 안내 종료 뒤 결과가 자동 초기화되지 않습니다.
- 일반 `MKDirections` 계산에 `HoguNavigationRouteCalculationGate` generation과 active directions cancel을 연결했습니다. reset, query 편집, 검색 결과 적용, 최근 경로 적용, 사용자의 현재 위치 출발지 선택 및 새 계산은 이전 callback을 거부합니다. reroute용 `MKDirections` 경로는 분리된 채 유지됩니다.
- `prepareOnAppear`의 초기 위치 요청은 `clearRoutePreview: false`를 유지합니다. 사용자 버튼을 통한 현재 위치 출발지 변경만 `true`로 전환했습니다.
- pure gate 테스트: active success 허용, reset 후 stale success 차단, 새 계산이 이전 계산을 차단하는 계약을 추가했습니다.
- `git diff --check` 통과. 상위 지시에 따라 build/test/commit/push 미실행.
