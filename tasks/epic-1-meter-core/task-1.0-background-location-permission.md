# Task 1.0: 백그라운드 GPS 권한 설정

> **Epic**: Epic 1 - 미터기 핵심
> **Status**: 🟢 Done
> **Priority**: P0
> **PRD**: FR-1.3 (선행 작업)

---

## 📋 개요

미터기가 정상적으로 동작하기 위한 필수 선행 작업으로, iOS의 위치 권한 시스템을 설정합니다. 특히 백그라운드에서도 GPS 추적이 가능하도록 `Always` 권한과 Info.plist 설정을 구성합니다.

## ✅ Acceptance Criteria

- [x] Info.plist에 위치 권한 설명 추가
- [x] `NSLocationWhenInUseUsageDescription` 설정
- [x] `NSLocationAlwaysAndWhenInUseUsageDescription` 설정
- [x] Background Modes에 `location` 추가
- [x] 권한 요청 시나리오 문서화

## 🔗 관련 파일

### 설정 파일
- [x] `HoguMeter/Info.plist`
  - Privacy 설명 추가
  - Background Modes 설정

### 권한 관리
- LocationService에서 직접 처리 (별도 PermissionManager 불필요)

---

## 📝 구현 계획

### 1단계: Info.plist 설정

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>호구미터가 주행 중 거리를 측정하여 요금을 계산하기 위해 위치 정보가 필요합니다.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>백그라운드에서도 정확한 거리 측정을 위해 항상 위치 정보 접근이 필요합니다.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

### 2단계: PermissionManager 구현 (선택적)

```swift
final class PermissionManager {
    static let shared = PermissionManager()

    private let locationManager = CLLocationManager()

    var locationAuthorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    var isLocationAuthorized: Bool {
        let status = locationAuthorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
}
```

### 3단계: 권한 요청 시나리오

**첫 실행 시:**
1. 앱 시작 → "위치 접근 허용" 시스템 팝업
2. "앱 사용 중 허용" 선택 권장
3. 미터기 시작 시점에 "항상 허용"으로 업그레이드 요청

**권한 거부 시:**
- 설정 앱으로 이동하는 안내 Alert 표시
- "설정 > 개인 정보 보호 > 위치 서비스" 경로 안내

---

## 🧪 테스트 체크리스트

- [ ] 첫 설치 시 권한 팝업 정상 노출
- [ ] "앱 사용 중" 권한으로 포그라운드 추적 가능
- [ ] "항상 허용" 권한으로 백그라운드 추적 가능
- [ ] 권한 거부 시 적절한 안내 메시지 표시
- [ ] 설정 앱에서 권한 변경 시 앱 동작 확인

---

## 📖 참고 자료

- [Apple Documentation: Requesting Authorization for Location Services](https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services)
- [Apple Documentation: Background Execution](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes)
- [Human Interface Guidelines: Accessing User Data](https://developer.apple.com/design/human-interface-guidelines/privacy#Requesting-access-to-user-data)

---

## 🔗 다음 Task와의 연계

이 Task가 완료되어야 다음 Task들을 진행할 수 있습니다:
- Task 1.3: GPS 거리 측정 (LocationService 구현)
- Task 1.1: 미터기 컨트롤 (위치 권한 확인 후 시작)

---

## 📝 구현 노트

### 주요 구현 내용

1. **Info.plist 권한 설정 완료** (HoguMeter/Info.plist:23-35)
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>호구미터가 주행 거리를 측정하기 위해 위치 정보가 필요합니다.</string>

   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>앱이 백그라운드에서도 주행을 계속 측정하기 위해 위치 정보가 필요합니다.</string>

   <key>UIBackgroundModes</key>
   <array>
       <string>location</string>
   </array>
   ```

2. **권한 요청 구현**
   - LocationService에서 CLLocationManager 사용
   - 앱 시작 시 자동으로 "When In Use" 권한 요청
   - 백그라운드 위치 추적 활성화

3. **권한 상태 확인**
   - CLLocationManager.authorizationStatus로 상태 확인
   - 권한 없을 시 LocationService가 업데이트 중단
   - 사용자가 설정에서 직접 권한 관리

### 기술 스택
- Core Location Framework
- Info.plist Privacy Keys
- UIBackgroundModes

---

**Created**: 2025-12-09
**Completed**: 2025-12-10
**Status**: 🟢 Done

---

## 📘 개발 가이드

**중요:** 이 Task를 구현하기 전에 반드시 아래 문서를 먼저 읽고 가이드를 준수해야 합니다.

- [DEVELOPMENT_GUIDE-FOR-AI.md](../../docs/DEVELOPMENT_GUIDE-FOR-AI.md)

위 가이드는 다음 내용을 포함합니다:
- Swift 코딩 컨벤션 (네이밍, 옵셔널 처리 등)
- 파일 구조 및 아키텍처 가이드
- AI 개발 워크플로우
- 커밋 메시지 규칙
- 테스트 작성 규칙
- 배포 전 체크리스트

