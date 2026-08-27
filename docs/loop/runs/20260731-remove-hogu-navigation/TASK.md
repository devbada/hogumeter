# PHASE-17 — REMOVE-HOGU-NAVIGATION

- run_id: `REMOVE-HOGU-NAV-001`
- branch: `codex/remove-hogu-navigation`
- risk: `P1`
- source_decision: `사용자 요청 — 미완료 기능 개발 대신 호구게이션 제거`

## 목표

호구게이션을 앱의 사용자 진입점, production 코드, 전용 네트워크·설정, 테스트,
마케팅·법적 설명과 배포 자산에서 제거합니다. 일반 미터기와 기존 주행 경로 지도는
그대로 보존합니다.

## Acceptance Criteria

- **AC-01**: 앱은 `미터기 | 기록 | 통계 | 설정` 4개 탭만 표시하며 호구게이션 진입점,
  tab case, 유료 잠금 TODO가 없다.
- **AC-02**: HoguNavigation View/ViewModel, 전용 performance 파일, SpeedCamera entity/API와
  Xcode target membership이 제거되고 orphan PBX reference가 없다.
- **AC-03**: MainMeterView의 navigation active 상태, 조작 잠금, start/stop notification
  결합이 제거되고 일반 미터 start/stop/reset과 지도·영수증 흐름은 유지된다.
- **AC-04**: navigation 전용 예상 요금 API, speed-camera key/config/network 코드가 제거된다.
- **AC-05**: navigation/speed-camera/thermal 전용 테스트는 제거하되
  MeterTimerGenerationGate 공용 테스트는 보존하고 전체 suite가 통과한다.
- **AC-06**: marketing index, 한·영 privacy/terms, App Store 자산에서 호구게이션과
  과속카메라 기능 설명·이미지가 제거된다. 일반 GPS 위치 처리와 기존 경로 지도 설명은 유지한다.
- **AC-07**: 활성 feature spec, preview, need-fix, 이전 active loop 상태는 제거 또는
  `CANCELLED_AS_OBSOLETE` 이력으로 정리된다.
- **AC-08**: production/config/project/tests/활성 marketing에서
  `HoguNavigation`, `hoguNavigation`, `호구게이션`, `SpeedCamera`,
  `PublicSpeedCameraServiceKey`, `PUBLIC_SPEED_CAMERA_SERVICE_KEY` 잔존물이 0건이다.
  현재 removal run과 명시적 archive 설명은 예외다.
- **AC-09**: Debug/Release generic Simulator build, build-for-testing, booted Simulator 전체
  테스트가 통과한다.
- **AC-10**: Simulator에서 cold launch, 4개 탭, meter start→stop→receipt, 기존 map,
  history/statistics/settings 진입 smoke QA가 통과한다.

## 제거 대상

- `HoguMeter/Presentation/Views/HoguNavigation/`
- `HoguMeter/Presentation/ViewModels/HoguNavigationViewModel.swift`
- `HoguMeter/Core/Performance/HoguNavigation*`
- `HoguMeter/Domain/Entities/SpeedCamera.swift`
- `HoguMeter/Domain/Services/SpeedCameraAPIClient.swift`
- 전용 test, PBX membership, service key
- 전용 spec, preview, 마케팅·App Store asset

## 보호 대상

- `MeterViewModel`, `LocationService`, background location
- `MapContainerView`, `MapViewModel`, `MapViewRepresentable`
- `RouteManager`, `RouteOptimizer`, `RouteDataManager`
- 주행 기록, 영수증 지도, 통계 지도와 기존 Trip 데이터
- App Store `07_map` 자산

## Non-goals

- 새 기능 구현
- 일반 미터의 GPS·지도·요금 로직 변경
- 기존 Trip 또는 사용자 설정 삭제
- 버전 bump, commit, push

## 검증

1. `rg` 잔존물 검사
2. `plutil -lint` Info.plist/project.pbxproj
3. `xmllint` shared scheme
4. `git diff --check`
5. Debug build → build-for-testing → actual full test
6. Release build
7. 앱·마케팅 smoke QA

## Agent 정책

내부 agent 모델 상한은 `gpt-5.6-terra`입니다. 상위 모델을 사용하지 않습니다.
