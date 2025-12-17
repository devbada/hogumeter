# 🐴 호구미터 (HoguMeter) - 프로젝트 브리프

> **BMAD Method v6 | Project Brief Document**
> 
> 문서 버전: 1.0.0  
> 작성일: 2025-12-09  
> 상태: Draft

---

## 1. 프로젝트 개요 (Project Overview)

### 1.1 프로젝트명
- **한글**: 호구미터
- **영문**: HoguMeter
- **슬로건**: "내 차 탔으면 내놔"

### 1.2 프로젝트 요약
친구들과 함께하는 드라이브를 더 재미있게 만들어주는 장난스러운 택시미터기 앱. 실제 택시 요금 체계를 기반으로 하되, 달리는 말 애니메이션과 효과음으로 유머러스한 경험을 제공합니다.

### 1.3 프로젝트 유형
- **플랫폼**: iOS (iPhone)
- **카테고리**: Entertainment / Utilities
- **개발 방식**: Native iOS (Swift + SwiftUI)
- **출시 목표**: 5-6주

---

## 2. 비전 및 목표 (Vision & Goals)

### 2.1 제품 비전
> "운전자와 동승자 모두가 즐길 수 있는 드라이브 엔터테인먼트"

### 2.2 비즈니스 목표
| 목표 | 측정 지표 | 목표치 |
|------|----------|--------|
| 앱스토어 출시 | 심사 통과 | 6주 내 |
| 사용자 획득 | 다운로드 수 | 1,000 (3개월 내) |
| 사용자 만족 | 앱스토어 평점 | 4.0+ |
| 바이럴 효과 | 영수증 공유 횟수 | DAU의 30% |

### 2.3 성공 지표 (Success Metrics)
- **핵심 지표**: 주행 완료율 (시작 → 정지 → 공유)
- **참여 지표**: 일일 평균 주행 횟수
- **성장 지표**: 영수증 공유를 통한 신규 유입

---

## 3. 타겟 사용자 (Target Users)

### 3.1 주요 페르소나

#### 페르소나 1: 드라이버 민수 (Driver Minsu)
```yaml
이름: 민수
나이: 28세
직업: 직장인
특징:
  - 운전을 좋아하고 자차 보유
  - 주말에 친구들과 드라이브를 자주 감
  - 장난을 좋아하고 유머러스함
  - SNS에 재미있는 콘텐츠 공유를 즐김
니즈:
  - 친구들과 드라이브할 때 재미 요소
  - 친구들에게 "차비" 청구하는 장난
  - 간편하게 사용할 수 있는 앱
Pain Points:
  - 매번 "야 기름값 좀 보태라" 하기 민망함
  - 장거리 운전 시 지루함
```

#### 페르소나 2: 동승자 지연 (Passenger Jiyeon)
```yaml
이름: 지연
나이: 26세
직업: 디자이너
특징:
  - 차가 없어서 친구 차를 자주 얻어탐
  - 재미있는 앱/콘텐츠에 관심 많음
  - 카카오톡으로 영수증 받으면 웃으며 공유
니즈:
  - 친구와의 재미있는 추억 만들기
  - SNS에 올릴만한 재미있는 콘텐츠
```

### 3.2 사용자 시나리오

#### 시나리오 1: 주말 드라이브
```
1. 민수가 친구들을 태우고 출발
2. "오늘 요금 받을게~" 하며 호구미터 앱 실행
3. 시작 버튼 탭 → 말이 달리기 시작 🐴
4. 친구들이 화면 보며 웃음
5. 속도 올리면 말이 더 빨리 뜀 → "야 천천히 가!"
6. 도착 후 정지 → 요금 27,200원 표시
7. 영수증 캡처해서 단톡방에 공유
8. 모두 웃음 😂
```

---

## 4. 핵심 기능 (Core Features)

### 4.1 기능 우선순위 매트릭스

| 우선순위 | 기능 | MoSCoW |
|---------|------|--------|
| P0 | 실시간 요금 계산 (거리+시간) | Must |
| P0 | GPS 기반 거리 측정 | Must |
| P0 | 미터기 시작/정지/리셋 | Must |
| P0 | 말 애니메이션 (속도 연동) | Must |
| P1 | 지역별 요금 설정 | Should |
| P1 | 야간 할증 자동 적용 | Should |
| P1 | 지역 변경 할증 | Should |
| P1 | 영수증 생성 및 공유 | Should |
| P1 | 효과음 시스템 | Should |
| P2 | 주행 기록 저장 | Could |
| P2 | 다크모드 | Could |
| P3 | 다양한 테마/스킨 | Won't (v1) |

### 4.2 핵심 기능 상세

#### 4.2.1 요금 계산 시스템
```
요금 = 기본요금 
     + 거리요금 (기본거리 초과분)
     + 시간요금 (저속/정차 시)
     + 지역할증 (지역 변경 시 고정 금액)
     + 야간할증 (거리+시간 요금의 배율 적용)
```

#### 4.2.2 말 애니메이션 시스템
| 속도 구간 | 말 상태 | 애니메이션 |
|----------|--------|-----------|
| 0 km/h | 서있음 🐴 | 정지 |
| 1-20 km/h | 걷기 | 느린 걸음 |
| 21-40 km/h | 빠른걸음 | 일반 속도 |
| 41-60 km/h | 달리기 | 빠른 발놀림 |
| 61-80 km/h | 질주 | 매우 빠름 |
| 80+ km/h | 폭주 🔥 | 발 구르기 효과 |

---

## 5. 기술 요구사항 (Technical Requirements)

### 5.1 플랫폼 & 환경
```yaml
Platform: iOS 15.0+
Language: Swift 5.9+
UI Framework: SwiftUI
IDE: Xcode 15+
Target Devices: iPhone (모든 사이즈)
```

### 5.2 필수 프레임워크
| 프레임워크 | 용도 |
|-----------|------|
| Core Location | GPS 위치 추적 |
| MapKit | Reverse Geocoding (지역 감지) |
| AVFoundation | 효과음 재생 |
| Core Data | 주행 기록 저장 |
| UIKit/SwiftUI | UI 구현 |

### 5.3 권한 요구사항
| 권한 | 용도 | 필수 여부 |
|-----|------|----------|
| 위치 정보 (사용 중) | GPS 거리 측정 | 필수 |
| 위치 정보 (백그라운드) | 화면 꺼진 상태 추적 | 선택 |

### 5.4 비기능적 요구사항 (NFRs)
```yaml
Performance:
  - GPS 업데이트: 1초 간격
  - 애니메이션 FPS: 60fps
  - 앱 시작 시간: < 2초

Battery:
  - 1시간 주행 시 배터리 소모: < 15%

Accuracy:
  - 거리 측정 오차: < 5%

Offline:
  - 인터넷 연결 없이 핵심 기능 동작
```

---

## 6. 데이터 모델 (Data Models)

### 6.1 지역별 요금 설정
```swift
struct RegionFare: Codable {
    let regionCode: String      // 예: "seoul", "gyeonggi"
    let regionName: String      // 예: "서울", "경기"
    let baseFare: Int           // 기본요금 (원)
    let baseDistance: Int       // 기본거리 (m)
    let distanceFare: Int       // 거리요금 (원)
    let distanceUnit: Int       // 거리단위 (m)
    let timeFare: Int           // 시간요금 (원)
    let timeUnit: Int           // 시간단위 (초)
    let nightSurchargeRate: Double  // 야간할증 배율
    let nightStartTime: String  // 야간 시작 (HH:mm)
    let nightEndTime: String    // 야간 종료 (HH:mm)
}
```

### 6.2 주행 기록
```swift
struct TripRecord: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let totalFare: Int
    let distance: Double        // km
    let duration: TimeInterval  // 초
    let startRegion: String
    let endRegion: String
    let regionChanges: Int      // 지역 변경 횟수
    let isNightTrip: Bool
    let fareBreakdown: FareBreakdown
}
```

### 6.3 요금 내역
```swift
struct FareBreakdown: Codable {
    let baseFare: Int
    let distanceFare: Int
    let timeFare: Int
    let regionSurcharge: Int
    let nightSurcharge: Int
    var totalFare: Int {
        baseFare + distanceFare + timeFare + regionSurcharge + nightSurcharge
    }
}
```

---

## 7. UI/UX 개요 (UI/UX Overview)

### 7.1 화면 구성
```
┌─────────────────────────────────────┐
│           호구미터 앱               │
├─────────────────────────────────────┤
│                                     │
│  1. 메인 미터기 화면 (Main)         │
│     - 요금 표시                     │
│     - 말 애니메이션                 │
│     - 거리/시간/속도 정보           │
│     - 시작/정지/리셋 버튼           │
│                                     │
│  2. 설정 화면 (Settings)            │
│     - 지역별 요금 설정              │
│     - 야간 할증 설정                │
│     - 지역 할증 설정                │
│     - 효과음 ON/OFF                 │
│     - 다크모드 ON/OFF               │
│                                     │
│  3. 영수증 화면 (Receipt)           │
│     - 요금 상세 내역                │
│     - 공유 버튼                     │
│                                     │
│  4. 주행 기록 화면 (History)        │
│     - 과거 주행 기록 목록           │
│     - 기록 상세 보기                │
│                                     │
└─────────────────────────────────────┘
```

### 7.2 디자인 컨셉
- **톤앤매너**: 장난스럽고 유머러스
- **컬러**: 밝고 재미있는 색상 (노란색, 주황색 계열)
- **아이콘**: 이모지 스타일 활용
- **폰트**: 둥글고 친근한 느낌

---

## 8. 프로젝트 일정 (Timeline)

### 8.1 개발 마일스톤
```
Phase 1: Foundation (Week 1)
├── 프로젝트 셋업
├── 기본 UI 레이아웃
├── 지역별 요금 JSON 설계
└── Core Location 연동

Phase 2: Core Features (Week 2)
├── GPS 거리 계산
├── 실시간 요금 계산
├── 야간 할증 감지
└── 지역 변경 감지

Phase 3: Animation (Week 3)
├── 말 캐릭터 에셋
├── 속도별 애니메이션
├── 80km/h 특수 효과
└── 배경 스크롤

Phase 4: Additional Features (Week 4)
├── 설정 화면
├── 주행 기록 저장
├── 영수증 생성
└── 카카오톡 공유

Phase 5: Polish (Week 5)
├── 효과음 연동
├── 다크모드
├── UI 다듬기
└── 애니메이션 튜닝

Phase 6: Release (Week 6)
├── 실제 주행 테스트
├── 버그 수정
├── 앱스토어 에셋
├── TestFlight 배포
└── 앱스토어 심사 제출
```

### 8.2 예상 출시일
- **TestFlight 베타**: Week 5 말
- **앱스토어 제출**: Week 6
- **앱스토어 출시**: Week 6-7 (심사 기간 포함)

---

## 9. 리스크 & 제약사항 (Risks & Constraints)

### 9.1 기술적 리스크
| 리스크 | 영향도 | 대응 방안 |
|-------|-------|----------|
| GPS 정확도 부족 | 높음 | 칼만 필터 적용, 보정 알고리즘 |
| 배터리 소모 과다 | 중간 | GPS 업데이트 주기 최적화 |
| 백그라운드 제한 | 중간 | 포그라운드 유지 알림 |

### 9.2 비즈니스 리스크
| 리스크 | 영향도 | 대응 방안 |
|-------|-------|----------|
| 앱스토어 심사 반려 | 높음 | 가이드라인 준수 철저히 |
| 낮은 사용자 관심 | 중간 | SNS 바이럴 마케팅 |

### 9.3 제약사항
- iOS만 지원 (Android 미지원)
- 한국 지역만 요금 데이터 제공
- 인터넷 연결 시에만 지역 감지 가능

---

## 10. 예산 & 리소스 (Budget & Resources)

### 10.1 예상 비용
| 항목 | 비용 | 비고 |
|-----|------|-----|
| Apple Developer 계정 | $99/년 | 필수 |
| 디자인 에셋 | 무료~30만원 | 직접 제작 or 구매 |
| 효과음 | 무료~10만원 | 무료 소스 활용 |
| **총합** | **약 13~50만원** | |

### 10.2 필요 리소스
- Mac (개발용)
- iPhone (테스트용)
- Xcode
- Claude CLI (개발 보조)

---

## 11. 용어 정의 (Glossary)

| 용어 | 정의 |
|-----|------|
| 기본요금 | 미터기 시작 시 적용되는 최초 요금 |
| 기본거리 | 기본요금에 포함된 거리 |
| 거리요금 | 기본거리 초과 후 거리에 따른 추가 요금 |
| 시간요금 | 저속 또는 정차 시 시간에 따른 추가 요금 |
| 야간할증 | 야간 시간대에 적용되는 할증 배율 |
| 지역할증 | 지역 경계를 넘을 때 적용되는 고정 추가 요금 |

---

## 12. 부록 (Appendix)

### 12.1 2025년 기준 택시 요금 (서울)
```json
{
  "regionName": "서울",
  "baseFare": 4800,
  "baseDistance": 1600,
  "distanceFare": 100,
  "distanceUnit": 131,
  "timeFare": 100,
  "timeUnit": 30,
  "nightSurchargeRate": 1.2,
  "nightStartTime": "22:00",
  "nightEndTime": "04:00"
}
```

### 12.2 참고 자료
- [서울시 택시 요금 안내](https://www.seoul.go.kr)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Core Location Documentation](https://developer.apple.com/documentation/corelocation)

---

## 문서 변경 이력

| 버전 | 날짜 | 작성자 | 변경 내용 |
|-----|------|-------|----------|
| 1.0.0 | 2025-12-09 | PM Agent | 초안 작성 |

---

> **다음 단계**: PRD (Product Requirements Document) 작성
