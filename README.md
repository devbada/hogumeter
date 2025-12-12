# 🐴 호구미터 (HoguMeter)

> **"내 차 탔으면 내놔"**
>
> 친구들과 함께하는 드라이브를 더 재미있게 만들어주는 장난스러운 택시미터기 앱

<p align="center">
  <img src="resource_images/app_screenshot.png" alt="미터기" width="200">
  <img src="resource_images/screenshot_settings.png" alt="설정" width="200">
  <img src="resource_images/screenshot_history.png" alt="기록" width="200">
  <img src="resource_images/screenshot_disclaimer.png" alt="면책 동의" width="200">
</p>

---

## 📱 앱 소개

| 항목 | 내용 |
|-----|------|
| **앱 이름** | 호구미터 (HoguMeter) |
| **플랫폼** | iOS (iPhone) |
| **최소 지원 버전** | iOS 17.0+ |
| **기술 스택** | Swift 5.9+, SwiftUI, Core Location |
| **개발 상태** | ✅ MVP 완료 |

---

## ✨ 주요 기능

### 1. 실시간 택시 미터기
- GPS 기반 거리/시간 요금 계산
- 시작/정지/리셋 컨트롤

### 2. 병산제 요금 계산
실제 택시 미터기와 동일한 **병산제** 적용:
- **고속** (15.72km/h 이상): 거리로 계산 (131m당 100원)
- **저속/정차**: 시간으로 계산 (30초당 100원)
- **기본요금에 약 12유닛 포함** (1.6km 또는 6분)

### 3. 시간대별 요금
서울시 택시요금 체계 (2024년 기준):
- **주간** (04:00 ~ 22:00): 기본 4,800원
- **심야1** (22:00 ~ 23:00, 02:00 ~ 04:00): 20% 할증
- **심야2** (23:00 ~ 02:00): 40% 할증

### 4. 지역별 요금 설정
- 기본 서울시 택시요금 제공
- 사용자 지정 요금 추가/수정/삭제
- 지역 변경 시 자동 할증

### 5. 말 애니메이션
- 속도에 따라 변하는 이모지 애니메이션
- 고속 주행 시 스피드 효과

### 6. 영수증 캡쳐
- 상세 요금 내역 영수증 생성
- 사진첩에 바로 저장 (Core Graphics 고속 렌더링)

### 7. 주행 기록
- 모든 주행 기록 자동 저장
- 기록 상세 보기 및 삭제

### 8. 효과음
- iOS 시스템 사운드 연동
- 시작/정지/요금 변경 알림

---

## ✅ 구현 현황

**전체 진행률**: 100% (16/16 Tasks 완료)

| Epic | 설명 | 상태 |
|------|------|------|
| Epic 0 | 앱 초기 설정 | 🟢 Done |
| Epic 1 | 미터기 핵심 기능 | 🟢 Done |
| Epic 2 | 말 애니메이션 | 🟢 Done |
| Epic 3 | 요금 설정 | 🟢 Done |
| Epic 4 | 영수증/캡쳐 | 🟢 Done |
| Epic 5 | 효과음 | 🟢 Done |
| Epic 6 | 주행 기록 | 🟢 Done |
| Epic 7 | 설정 | 🟢 Done |

---

## 🏗️ 프로젝트 구조

```
HoguMeter/
├── HoguMeter/
│   ├── App/                    # 앱 진입점
│   ├── Core/                   # 코어 유틸리티
│   │   ├── Extensions/         # Swift 확장
│   │   └── Utils/              # 유틸리티 클래스
│   ├── Data/                   # 데이터 레이어
│   │   └── Repositories/       # Repository 구현
│   ├── Domain/                 # 도메인 레이어
│   │   ├── Entities/           # 도메인 엔티티
│   │   └── Services/           # 도메인 서비스
│   ├── Presentation/           # 프레젠테이션 레이어
│   │   ├── ViewModels/         # ViewModel
│   │   └── Views/              # SwiftUI View
│   └── Resources/              # 리소스 파일
├── HoguMeterTests/             # 단위 테스트
│   ├── FareCalculatorTests.swift
│   └── FareTimeZoneTests.swift
├── docs/                       # 프로젝트 문서
└── tasks/                      # Epic별 개발 태스크
```

---

## 📚 문서

| 문서 | 설명 |
|-----|------|
| [PROJECT_BRIEF.md](./docs/PROJECT_BRIEF.md) | 프로젝트 개요, 비전, 목표 |
| [PRD.md](./docs/PRD.md) | 상세 기능 요구사항 |
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | 기술 아키텍처 |
| [DEVELOPMENT_GUIDE.md](./docs/DEVELOPMENT_GUIDE.md) | 개발 가이드 |
| [DEVELOPMENT_GUIDE-FOR-AI.md](./docs/DEVELOPMENT_GUIDE-FOR-AI.md) | AI 개발 가이드 |
| [PRIVACY_POLICY.md](./docs/PRIVACY_POLICY.md) | 개인정보 처리방침 (한글) |
| [PRIVACY_POLICY_EN.md](./docs/PRIVACY_POLICY_EN.md) | Privacy Policy (English) |
| [tasks/README.md](./tasks/README.md) | 태스크 관리 |

---

## 🚀 시작하기

### 개발 환경 요구사항
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **iOS Deployment Target**: 17.0+
- **macOS**: 14.0+ (Sonoma)

### 프로젝트 실행

```bash
# 1. 저장소 클론
git clone [repository-url]
cd hogumeter

# 2. Xcode에서 프로젝트 열기
open HoguMeter.xcodeproj

# 3. 시뮬레이터 선택 후 실행 (⌘ + R)
```

### Claude Code로 개발하기

```bash
# Claude Code 실행
claude

# AI와 대화하며 개발
> tasks/epic-1-meter-core/ 폴더를 읽고 미터기 기능을 확인해줘
> 영수증 캡쳐 기능을 개선해줘
```

---

## 🛠️ 기술 스택

| 카테고리 | 기술 |
|---------|------|
| Language | Swift 5.9+ |
| UI | SwiftUI (iOS 17+) |
| 아키텍처 | Clean Architecture + MVVM |
| 위치 | Core Location |
| 저장 | UserDefaults, Codable |
| 이미지 생성 | Core Graphics |
| 상태 관리 | @Observable (iOS 17+) |

---

## 📱 지원 기기

- **iPhone**: iPhone 12 이상 권장
- **iOS**: 17.0 이상
- **화면**: 모든 iPhone 크기 지원

---

## 🔧 최근 업데이트 (2025-12-12)

### 🆕 병산제 요금 계산 구현
실제 택시 미터기와 동일한 병산제 적용:
- 고속(15.72km/h 이상)일 때는 **거리만** 계산
- 저속/정차일 때는 **시간만** 계산
- 기본요금에 약 12유닛 포함 (1.6km 또는 약 6분)
- 기본유닛 이내에서는 추가요금 없음

### 🎨 온보딩 애니메이션 개선
- 말 이모지 좌우 반전 (이동 방향과 일치)
- 미터기 위치 조정 (겹침 문제 해결)

### 🧪 테스트 코드 추가
- FareCalculatorTests: 33개 테스트 케이스
- FareTimeZoneTests: 18개 테스트 케이스
- 병산제 로직 검증 완료

### 성능 개선
- 영수증 이미지 생성: Core Graphics 직접 렌더링 (1-2초 → <0.1초)

### 기능 변경
- 영수증 공유 → 캡쳐로 변경 (사진첩 바로 저장)

---

## 📦 빌드

```bash
# Simulator용 빌드
xcodebuild -project HoguMeter.xcodeproj \
  -scheme HoguMeter \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

---

## 📄 라이선스

MIT License

---

## 📞 연락처

프로젝트 관련 문의: imdevbada@gmail.com

---

> 🐴 **"호구미터와 함께라면, 모든 드라이브가 즐거워집니다!"**
