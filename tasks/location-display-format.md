# Feature Specification: Location Display Format (지역 표시 방식 변경)

**Task ID:** LOCATION-001
**Created:** 2025-01-14
**Completed:** 2026-01-14
**Branch:** feature/location-display-format
**Status:** ✅ Completed

---

## 목표

현재 위치를 더 직관적이고 간결하게 표시하도록 변경

## 현재 문제점

- 전체 주소가 너무 길게 표시됨 (예: 서울특별시 강서구 화곡동)
- 고속도로/대로에서는 동 이름이 계속 바뀌어 혼란스러움
- 도로명(고속도로, 대로, 대교)이 표시되지 않음

## 새로운 표시 규칙

### 1. 고속도로

| 조건 | 표시 방식 | 예시 |
|------|-----------|------|
| 고속도로 주행 중 | 도로명 · 시/군 | 경부고속도로 · 천안시 |

### 2. 대로 (주요 간선도로)

| 조건 | 표시 방식 | 예시 |
|------|-----------|------|
| 서울/광역시 내 대로 | 도로명 · 구 | 올림픽대로 · 강서구 |
| 도 지역 대로 | 도로명 · 시/군 | 김포대로 · 김포시 |

### 3. 대교

| 조건 | 표시 방식 | 예시 |
|------|-----------|------|
| 대교 통과 중 | 도로명만 | 한강대교 |

### 4. 일반 도로 (동/읍/면 기반)

| 지역 유형 | 표시 방식 | 예시 |
|-----------|-----------|------|
| 서울특별시 | 구 + 동 | 강서구 화곡동 |
| 광역시 | 구 + 동 | 해운대구 우동 |
| 도 + 시 (구 없음) | 시 + 동 | 김포시 마산동 |
| 도 + 시 (구 있음) | 시 + 구 + 동 | 천안시 동남구 신부동 |
| 도 + 군 | 군 + 읍/면 | 고령군 개진면 |

### 핵심 원칙

- 특별시/광역시/도는 항상 생략
- 최소 2단계 지역 정보 유지 (중복 방지)
- 고속도로/대로에서는 도로명 + 큰 지역 표시

---

## 기술 설계

### CLPlacemark 속성 매핑

| CLPlacemark 속성 | 한글 의미 | 예시 |
|------------------|-----------|------|
| administrativeArea | 시/도 | 서울특별시, 경기도 |
| locality | 시/군/구 | 천안시, 강서구 |
| subLocality | 동/읍/면 | 화곡동, 개진면 |
| thoroughfare | 도로명 | 올림픽대로, 경부고속도로 |
| subAdministrativeArea | 군/구 (도 지역) | 동남구 |

### 신규 파일

1. **AddressInfo.swift** (`Domain/Entities/`)
   - 상세 주소 정보를 담는 구조체

2. **LocationFormatter.swift** (`Core/Utils/`)
   - 주소 포맷팅 유틸리티

3. **LocationFormatterTests.swift** (`HoguMeterTests/Unit/`)
   - 단위 테스트

### 수정 파일

1. **RegionDetector.swift**
   - AddressInfo 반환하도록 수정
   - 도로명(thoroughfare) 정보 추가 수집

2. **MeterViewModel.swift**
   - currentAddressInfo 추가
   - currentRegion을 포맷팅된 값으로 변경

---

## 구현 상세

### AddressInfo 모델

```swift
struct AddressInfo: Equatable {
    let administrativeArea: String?  // 시/도 (서울특별시, 경기도)
    let locality: String?            // 시/군/구 (천안시, 강서구)
    let subLocality: String?         // 동/읍/면 (화곡동, 개진면)
    let subAdministrativeArea: String? // 군/구 (도 지역: 동남구)
    let thoroughfare: String?        // 도로명 (올림픽대로, 경부고속도로)
}
```

### LocationFormatter 로직

```swift
static func format(_ address: AddressInfo) -> String {
    // 1. 고속도로 체크
    if isExpressway(address) {
        return "\(roadName) · \(city)"
    }

    // 2. 대로 체크
    if isMainRoad(address) {
        return "\(roadName) · \(district)"
    }

    // 3. 대교 체크
    if isBridge(address) {
        return roadName
    }

    // 4. 일반 도로: 지역 기반
    return formatByRegion(address)
}
```

---

## 테스트 케이스

| 시나리오 | 입력 | 기대 출력 |
|----------|------|-----------|
| 고속도로 | 경부고속도로 + 천안시 | 경부고속도로 · 천안시 |
| 서울 대로 | 올림픽대로 + 강서구 | 올림픽대로 · 강서구 |
| 대교 | 한강대교 | 한강대교 |
| 서울 일반 | 서울특별시 + 강서구 + 화곡동 | 강서구 화곡동 |
| 광역시 | 부산광역시 + 해운대구 + 우동 | 해운대구 우동 |
| 도+시(구없음) | 경기도 + 김포시 + 마산동 | 김포시 마산동 |
| 도+시(구있음) | 충남 + 천안시 + 동남구 + 신부동 | 천안시 동남구 신부동 |
| 도+군 | 경북 + 고령군 + 개진면 | 고령군 개진면 |

---

## 검증 체크리스트

- [x] 고속도로에서 "도로명 · 시/군" 형식으로 표시
- [x] 대로에서 "도로명 · 구/시" 형식으로 표시
- [x] 대교에서 도로명만 표시
- [x] 서울/광역시에서 "구 + 동" 형식으로 표시
- [x] 도 + 시에서 "시 + (구) + 동" 형식으로 표시
- [x] 도 + 군에서 "군 + 읍/면" 형식으로 표시
- [x] 모든 단위 테스트 통과
- [x] 빌드 성공
- [ ] 실제 주행 테스트 완료

---

## 파일 변경 목록

| 파일 | 작업 |
|------|------|
| tasks/location-display-format.md | 생성 - 스펙 문서 |
| HoguMeter/Domain/Entities/AddressInfo.swift | 생성 - 주소 모델 |
| HoguMeter/Core/Utils/LocationFormatter.swift | 생성 - 포맷팅 로직 |
| HoguMeterTests/Unit/LocationFormatterTests.swift | 생성 - 단위 테스트 |
| HoguMeter/Domain/Services/RegionDetector.swift | 수정 - AddressInfo 반환 |
| HoguMeter/Presentation/ViewModels/MeterViewModel.swift | 수정 - 포맷팅 적용 |
