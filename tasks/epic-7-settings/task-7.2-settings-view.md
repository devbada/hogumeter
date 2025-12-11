# Task 7.2: 설정 화면

> **Epic**: Epic 7 - 설정/기타
> **Status**: 🟢 Done
> **Priority**: P2
> **PRD**: FR-7.2

---

## 📋 개요

앱의 각종 설정을 관리하는 화면을 구현합니다.

## ✅ Acceptance Criteria

- [x] 기본 설정 UI 구현
- [x] 지역별 요금 설정 (서브화면)
- [x] 야간 할증 설정 (ON/OFF)
- [x] 지역 할증 설정 (ON/OFF, 금액)
- [x] 효과음 ON/OFF
- [x] 다크모드 설정
- [x] 앱 버전 정보
- [x] 개인정보처리방침 링크

## 🔗 관련 파일

- [x] `HoguMeter/Presentation/Views/Settings/SettingsView.swift`
- [x] `HoguMeter/Data/Repositories/SettingsRepository.swift`

---

## 📝 구현 노트

### 주요 구현 내용

1. **SettingsView 확장** (HoguMeter/Presentation/Views/Settings/SettingsView.swift:1-130)
   - SettingsRepository 연동으로 실제 설정 저장/불러오기
   - Form 기반 설정 UI
   - 6개 섹션 구성

2. **요금 설정 섹션**
   - 지역별 요금 설정 (NavigationLink → RegionFareSettingsView)
   - 서브화면에서 서울/경기/인천 선택 가능

3. **할증 설정 섹션**
   - 야간 할증 Toggle (ON/OFF)
   - 지역 할증 Toggle (ON/OFF)
   - 지역 할증 금액 Stepper (1000~5000원, 500원 단위)
   - 조건부 렌더링 (지역 할증 OFF 시 금액 숨김)

4. **앱 설정 섹션**
   - 효과음 Toggle
   - 다크모드 Picker (시스템/라이트/다크)
   - 변경 즉시 NotificationCenter로 전체 앱 업데이트

5. **정보 섹션**
   - 앱 버전 (1.0.0)
   - 개인정보처리방침 Link (외부 URL)

6. **앱 정보 섹션**
   - 앱 로고 (🏇 이모지)
   - 앱 이름 ("호구미터")
   - 슬로건 ("내 차 탔으면 내놔")

7. **RegionFareSettingsView** (HoguMeter/Presentation/Views/Settings/RegionFareSettingsView.swift:1-56)
   - 3개 지역 (서울, 경기, 인천) 선택
   - 각 지역의 기본요금/거리요금 정보 표시
   - 선택된 항목에 체크마크 표시
   - 선택 시 SettingsRepository에 저장

### 기술 스택
- SwiftUI Form + Section
- Toggle, Picker, Stepper
- NavigationLink (서브화면)
- Link (외부 URL)
- NotificationCenter (설정 변경 알림)
- .onChange modifier (즉시 저장)

---

**Created**: 2025-01-15
**Completed**: 2025-12-09

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

