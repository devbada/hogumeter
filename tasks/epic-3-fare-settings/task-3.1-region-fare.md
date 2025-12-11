# Task 3.1: 지역별 요금 추가 및 편집 기능

## 📋 Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-3.1 |
| Epic | Epic 3: 요금 설정 시스템 |
| 우선순위 | P1 (Should) |
| 예상 시간 | 6시간 |
| 상태 | 🔲 대기 |
| 담당 | Claude CLI |
| 생성일 | 2025-01-15 |
| 완료일 | - |

---

## 🎯 목표

서울시 택시요금 체계를 기반으로 주간/심야 요금을 세분화하여 관리하고, 사용자가 최대 3개 지역까지 추가/편집/삭제할 수 있는 기능 구현

---

## 📌 관련 PRD

- FR-3.1: 지역별 요금 관리
- 수락 기준:
  - [ ] 서울시 택시요금 체계 기반 데이터 구조
  - [ ] 주간/심야 요금 분리 관리
  - [ ] 심야 시간대별 차등 요금 (22~23시, 23~02시, 02~04시)
  - [ ] 최대 3개 지역까지 관리 가능
  - [ ] 설정 변경 시 즉시 반영

---

## 📊 서울시 택시요금 체계 (2023.02.01 04시~ 기준)

### 중형택시 요금표

| 구분 | 항목 | 요금 |
|------|------|------|
| **주간** | 기본요금 | 1.6km까지 4,800원 |
| | 거리요금 | 131m당 100원 |
| | 시간요금 | 30초당 100원 |
| **심야 (22~23시, 02~04시)** | 기본요금 | 1.6km까지 5,800원 |
| | 거리요금 | 131m당 120원 |
| | 시간요금 | 30초당 120원 |
| **심야 (23~02시)** | 기본요금 | 1.6km까지 6,700원 |
| | 거리요금 | 131m당 140원 |
| | 시간요금 | 30초당 140원 |

### 공통사항

| 항목 | 내용 |
|------|------|
| 시간·거리 병산 기준 | 15.72km/h 미만 시 |
| 시계외 할증 | 20% |
| 심야 할증율 | 22~23시, 02~04시: 20% / 23~02시: 40% |
| 심야·시계외 중복할증 | 최대 60% |
| 요금 반올림 | 십원단위 반올림 |

---

## 📝 상세 요구사항

### 1. 데이터 구조 (RegionFare Entity)

```swift
struct RegionFare: Identifiable, Codable {
    let id: UUID
    var code: String                    // "seoul", "custom_1" 등
    var name: String                    // "서울", "내 지역" 등
    var isDefault: Bool                 // 기본 제공 지역 여부
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - 주간 요금 (04:00 ~ 22:00)
    var dayBaseFare: Int                // 기본요금 (원)
    var dayBaseDistance: Int            // 기본거리 (m)
    var dayDistanceFare: Int            // 거리요금 (원)
    var dayDistanceUnit: Int            // 거리단위 (m)
    var dayTimeFare: Int                // 시간요금 (원)
    var dayTimeUnit: Int                // 시간단위 (초)
    
    // MARK: - 심야1 요금 (22:00 ~ 23:00, 02:00 ~ 04:00) - 20% 할증
    var night1BaseFare: Int             // 기본요금 (원)
    var night1BaseDistance: Int         // 기본거리 (m)
    var night1DistanceFare: Int         // 거리요금 (원)
    var night1DistanceUnit: Int         // 거리단위 (m)
    var night1TimeFare: Int             // 시간요금 (원)
    var night1TimeUnit: Int             // 시간단위 (초)
    
    // MARK: - 심야2 요금 (23:00 ~ 02:00) - 40% 할증
    var night2BaseFare: Int             // 기본요금 (원)
    var night2BaseDistance: Int         // 기본거리 (m)
    var night2DistanceFare: Int         // 거리요금 (원)
    var night2DistanceUnit: Int         // 거리단위 (m)
    var night2TimeFare: Int             // 시간요금 (원)
    var night2TimeUnit: Int             // 시간단위 (초)
    
    // MARK: - 기타 설정
    var lowSpeedThreshold: Double       // 시간·거리 병산 기준 속도 (km/h)
    var outsideCitySurcharge: Double    // 시계외 할증률 (0.2 = 20%)
    var maxCombinedSurcharge: Double    // 최대 중복할증률 (0.6 = 60%)
    var roundingUnit: Int               // 반올림 단위 (10 = 십원단위)
    
    // MARK: - 삭제 가능 여부
    var canDelete: Bool {
        !isDefault
    }
}
```

### 2. 시간대 구분 Enum

```swift
enum FareTimeZone: String, CaseIterable {
    case day = "day"            // 주간: 04:00 ~ 22:00
    case night1 = "night1"      // 심야1: 22:00 ~ 23:00, 02:00 ~ 04:00
    case night2 = "night2"      // 심야2: 23:00 ~ 02:00
    
    var displayName: String {
        switch self {
        case .day: return "주간"
        case .night1: return "심야 (20%)"
        case .night2: return "심야 (40%)"
        }
    }
    
    var timeRange: String {
        switch self {
        case .day: return "04:00 ~ 22:00"
        case .night1: return "22:00 ~ 23:00, 02:00 ~ 04:00"
        case .night2: return "23:00 ~ 02:00"
        }
    }
    
    var surchargeRate: Double {
        switch self {
        case .day: return 0.0
        case .night1: return 0.2
        case .night2: return 0.4
        }
    }
    
    static func current(from date: Date = Date()) -> FareTimeZone {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 4..<22:
            return .day
        case 22..<23:
            return .night1
        case 23, 0, 1:
            return .night2
        case 2..<4:
            return .night1
        default:
            return .day
        }
    }
}
```

### 3. 기본 제공 데이터 (서울 기준)

```json
{
  "version": "2023.02.01",
  "lastUpdated": "2023-02-01",
  "maxRegions": 3,
  "regions": [
    {
      "code": "seoul",
      "name": "서울",
      "isDefault": true,
      
      "dayBaseFare": 4800,
      "dayBaseDistance": 1600,
      "dayDistanceFare": 100,
      "dayDistanceUnit": 131,
      "dayTimeFare": 100,
      "dayTimeUnit": 30,
      
      "night1BaseFare": 5800,
      "night1BaseDistance": 1600,
      "night1DistanceFare": 120,
      "night1DistanceUnit": 131,
      "night1TimeFare": 120,
      "night1TimeUnit": 30,
      
      "night2BaseFare": 6700,
      "night2BaseDistance": 1600,
      "night2DistanceFare": 140,
      "night2DistanceUnit": 131,
      "night2TimeFare": 140,
      "night2TimeUnit": 30,
      
      "lowSpeedThreshold": 15.72,
      "outsideCitySurcharge": 0.2,
      "maxCombinedSurcharge": 0.6,
      "roundingUnit": 10
    }
  ]
}
```

---

### 4. 지역 목록 화면 (RegionFareListView)

```
┌─────────────────────────────────────────┐
│  ← 설정        지역별 요금         +    │
├─────────────────────────────────────────┤
│                                         │
│  📍 현재 선택: 서울                      │
│  💡 최대 3개 지역까지 등록 가능 (1/3)    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🏙️ 서울 (기본)              ✓   │    │
│  │    주간 4,800원 | 심야 5,800원   │    │
│  │    〉                           │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ ➕ 새 지역 추가 (2개 더 가능)    │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘

* 최대 3개 지역까지만 추가 가능
* 기본 지역(서울)은 삭제 불가, 편집만 가능
* 스와이프하여 사용자 추가 지역 삭제
```

### 5. 지역 요금 편집 화면 (RegionFareEditView)

```
┌─────────────────────────────────────────┐
│  ← 취소       서울 요금 편집      저장   │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 지역명                          │    │
│  │ [서울                        ]  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ☀️ 주간 요금 (04:00 ~ 22:00)          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                         │
│  기본요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 거리           │    │
│  │ [4,800    ] 원 │ [1,600   ] m   │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  거리요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 단위           │    │
│  │ [100      ] 원 │ [131     ] m   │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  시간요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 단위           │    │
│  │ [100      ] 원 │ [30      ] 초  │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  🌙 심야1 요금 (22~23시, 02~04시)       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                         │
│  기본요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 거리           │    │
│  │ [5,800    ] 원 │ [1,600   ] m   │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  거리요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 단위           │    │
│  │ [120      ] 원 │ [131     ] m   │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  시간요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 단위           │    │
│  │ [120      ] 원 │ [30      ] 초  │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  🌑 심야2 요금 (23~02시)                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                         │
│  기본요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 거리           │    │
│  │ [6,700    ] 원 │ [1,600   ] m   │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  거리요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 단위           │    │
│  │ [140      ] 원 │ [131     ] m   │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  시간요금                                │
│  ┌────────────────┬────────────────┐    │
│  │ 금액           │ 단위           │    │
│  │ [140      ] 원 │ [30      ] 초  │    │
│  └────────────────┴────────────────┘    │
│                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│  ⚙️ 기타 설정                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 저속 기준 (병산)                │    │
│  │ [15.72              ] km/h      │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 시계외 할증                     │    │
│  │ [20                  ] %        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 최대 중복할증                   │    │
│  │ [60                  ] %        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 반올림 단위                     │    │
│  │ [10                  ] 원       │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🔄 서울 기본값으로 초기화        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 🗑️ 이 지역 삭제                 │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘

* 기본 지역(서울)은 삭제 버튼 숨김
* 스크롤 가능한 Form 형태
```

---

### 6. 새 지역 추가 화면 (RegionFareAddView)

```
┌─────────────────────────────────────────┐
│  ← 취소       새 지역 추가        추가   │
├─────────────────────────────────────────┤
│                                         │
│  지역 정보                               │
│  ┌─────────────────────────────────┐    │
│  │ 지역명 *                        │    │
│  │ [                            ]  │    │
│  │ 예: 경기, 인천, 부산 등          │    │
│  └─────────────────────────────────┘    │
│                                         │
│  💡 서울 요금을 기준으로 생성됩니다.     │
│     추가 후 편집할 수 있습니다.          │
│                                         │
└─────────────────────────────────────────┘

* 지역명 입력 후 추가 시 서울 요금으로 복사됨
* 추가 후 바로 편집 화면으로 이동
```

---

## 🔧 구현 계획

### 생성할 파일

- [ ] `Domain/Entities/RegionFare.swift` - 지역 요금 Entity (확장)
- [ ] `Domain/Entities/FareTimeZone.swift` - 시간대 구분 Enum
- [ ] `Domain/Validation/FareValidation.swift` - 요금 유효성 검사
- [ ] `Data/DataSources/Static/DefaultFares.json` - 기본 요금 JSON
- [ ] `Presentation/Views/Settings/RegionFare/RegionFareListView.swift` - 지역 목록 화면
- [ ] `Presentation/Views/Settings/RegionFare/RegionFareEditView.swift` - 지역 편집 화면
- [ ] `Presentation/Views/Settings/RegionFare/RegionFareAddView.swift` - 새 지역 추가 화면
- [ ] `Presentation/Views/Settings/RegionFare/Components/FareInputRow.swift` - 요금 입력 행
- [ ] `Presentation/Views/Settings/RegionFare/Components/FareSectionView.swift` - 요금 섹션 뷰
- [ ] `Presentation/ViewModels/RegionFareViewModel.swift` - 지역 요금 ViewModel

### 수정할 파일

- [ ] `Data/Repositories/RegionFareRepository.swift` - CRUD 메서드 추가
- [ ] `Domain/Services/FareCalculator.swift` - 시간대별 요금 계산 로직
- [ ] `Presentation/Views/Settings/SettingsView.swift` - 지역 요금 메뉴 연결

### 의존성

- 선행 Task: TASK-7.2 (설정 화면 기본 구조)
- 필요 라이브러리: 없음

---

## 📝 FareCalculator 수정

```swift
final class FareCalculator {
    
    private let settingsRepository: SettingsRepository
    
    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    /// 현재 시간대에 맞는 요금 계산
    func calculate(
        distance: Double,           // meters
        lowSpeedDuration: TimeInterval,
        regionChanges: Int,
        at date: Date = Date()
    ) -> Int {
        let fare = settingsRepository.currentRegionFare
        let timeZone = FareTimeZone.current(from: date)
        
        // 시간대별 요금 선택
        let (baseFare, baseDistance, distanceFare, distanceUnit, timeFare, timeUnit) = 
            getFareComponents(fare: fare, timeZone: timeZone)
        
        // 기본요금
        var totalFare = baseFare
        
        // 거리요금 (기본거리 초과분)
        let extraDistance = max(0, distance - Double(baseDistance))
        let distanceUnits = Int(extraDistance / Double(distanceUnit))
        totalFare += distanceUnits * distanceFare
        
        // 시간요금 (저속 시간)
        let timeUnits = Int(lowSpeedDuration / Double(timeUnit))
        totalFare += timeUnits * timeFare
        
        // 지역 할증 (시계외)
        if settingsRepository.isRegionSurchargeEnabled {
            let surcharge = Double(totalFare - baseFare) * fare.outsideCitySurcharge
            totalFare += Int(surcharge) * regionChanges
        }
        
        // 반올림
        totalFare = roundToUnit(totalFare, unit: fare.roundingUnit)
        
        return totalFare
    }
    
    private func getFareComponents(
        fare: RegionFare, 
        timeZone: FareTimeZone
    ) -> (Int, Int, Int, Int, Int, Int) {
        switch timeZone {
        case .day:
            return (fare.dayBaseFare, fare.dayBaseDistance, 
                    fare.dayDistanceFare, fare.dayDistanceUnit,
                    fare.dayTimeFare, fare.dayTimeUnit)
        case .night1:
            return (fare.night1BaseFare, fare.night1BaseDistance,
                    fare.night1DistanceFare, fare.night1DistanceUnit,
                    fare.night1TimeFare, fare.night1TimeUnit)
        case .night2:
            return (fare.night2BaseFare, fare.night2BaseDistance,
                    fare.night2DistanceFare, fare.night2DistanceUnit,
                    fare.night2TimeFare, fare.night2TimeUnit)
        }
    }
    
    private func roundToUnit(_ value: Int, unit: Int) -> Int {
        return ((value + unit / 2) / unit) * unit
    }
}
```

---

## ✅ 체크리스트

### Entity & Data

- [ ] RegionFare Entity 확장 (주간/심야1/심야2 분리)
- [ ] FareTimeZone Enum 구현
- [ ] DefaultFares.json 생성 (서울 기준)
- [ ] RegionFareRepository CRUD 구현 (최대 3개 제한)

### ViewModel

- [ ] RegionFareViewModel 구현
- [ ] FareValidation 구현
- [ ] 지역 개수 제한 로직 (최대 3개)

### 지역 목록 화면

- [ ] RegionFareListView 구현
- [ ] 현재 선택 지역 표시 (✓)
- [ ] 지역 개수 표시 (1/3)
- [ ] 스와이프 삭제 (사용자 지역만)
- [ ] 3개 초과 시 추가 버튼 비활성화

### 지역 편집 화면

- [ ] RegionFareEditView 구현
- [ ] 주간 요금 섹션
- [ ] 심야1 요금 섹션 (22~23시, 02~04시)
- [ ] 심야2 요금 섹션 (23~02시)
- [ ] 기타 설정 섹션
- [ ] 유효성 검사
- [ ] 기본값 초기화
- [ ] 저장 기능

### 지역 추가 화면

- [ ] RegionFareAddView 구현
- [ ] 지역명 입력
- [ ] 서울 요금 복사

### FareCalculator

- [ ] 시간대별 요금 계산 로직 수정
- [ ] 반올림 로직 구현

### 연동 & 테스트

- [ ] SettingsView 연결
- [ ] 빌드 성공
- [ ] 시뮬레이터 테스트

---

## 🧪 테스트 시나리오

### 시나리오 1: 시간대별 요금 확인

1. 현재 시간이 오후 2시 (주간)
2. 미터기 시작
3. 기본요금 4,800원으로 시작되는지 확인

### 시나리오 2: 심야1 시간대

1. 현재 시간이 오후 10시 30분 (심야1)
2. 미터기 시작
3. 기본요금 5,800원으로 시작되는지 확인

### 시나리오 3: 심야2 시간대

1. 현재 시간이 오전 0시 30분 (심야2)
2. 미터기 시작
3. 기본요금 6,700원으로 시작되는지 확인

### 시나리오 4: 지역 추가 (최대 3개)

1. 기본 서울 + 사용자 지역 2개 추가
2. 3개가 되면 "추가" 버튼 비활성화
3. 1개 삭제 후 다시 추가 가능

### 시나리오 5: 지역 편집

1. 서울 지역 편집 화면 진입
2. 심야2 기본요금 6700 → 7000 수정
3. 저장
4. 심야2 시간대에 미터기 시작
5. 7,000원으로 시작되는지 확인

### 시나리오 6: 반올림 확인

1. 요금이 4,785원 계산됨
2. 십원단위 반올림 → 4,790원 표시

---

## 📝 구현 노트

(개발 중 기록)

---

## 🐛 발견된 이슈

(개발 중 기록)

---


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

## 📎 참고 자료

- 서울시 택시요금 체계 (2023.02.01 04시~)
- docs/ARCHITECTURE.md - Section 5 Data Models
- docs/PRD.md - FR-3.1
