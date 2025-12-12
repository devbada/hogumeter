# 🐴 호구미터 (HoguMeter)

> **"내 차 탔으면 내놔"**
>
> 친구들과 함께하는 드라이브를 더 재미있게 만들어주는 장난스러운 택시미터기 앱

---

## 📚 BMAD Method 문서 구조

이 프로젝트는 **BMAD Method (Breakthrough Method for Agile AI-Driven Development)** 를 따라 개발됩니다.

### 📁 문서 목록

| 문서 | 설명 | 상태 |
|-----|------|------|
| [PROJECT_BRIEF.md](./docs/PROJECT_BRIEF.md) | 프로젝트 개요, 비전, 목표, 페르소나, 기능 개요 | ✅ 완료 |
| [PRD.md](./docs/PRD.md) | 상세 기능 요구사항, User Stories, 화면 흐름 | ✅ 완료 |
| [ARCHITECTURE.md](./docs/ARCHITECTURE.md) | 기술 스택, 아키텍처, 핵심 컴포넌트 설계 | ✅ 완료 |
| [DEVELOPMENT_GUIDE.md](./docs/DEVELOPMENT_GUIDE.md) | 개발 가이드 (통합 버전) | ✅ 완료 |
| [DEVELOPMENT_GUIDE-FOR-AI.md](./docs/DEVELOPMENT_GUIDE-FOR-AI.md) | AI를 위한 개발 가이드 | ✅ 완료 |
| [DEVELOPMENT_GUIDE_FOR_DEVELOPER.md](./docs/DEVELOPMENT_GUIDE_FOR_DEVELOPER.md) | 사람 개발자를 위한 가이드 | ✅ 완료 |
| [tasks/](./tasks/) | Epic별 개발 태스크 | 🚧 진행 중 |

---

## 📖 문서 읽는 순서

### 처음 프로젝트를 파악할 때
1. **PROJECT_BRIEF.md** → 전체 그림 파악
2. **PRD.md** → 상세 기능 이해
3. **ARCHITECTURE.md** → 기술 구현 방향

### 개발 시작 시
1. **DEVELOPMENT_GUIDE.md** → 개발 규칙 및 컨벤션 확인
   - AI 개발자: `DEVELOPMENT_GUIDE-FOR-AI.md` 참고
   - 사람 개발자: `DEVELOPMENT_GUIDE_FOR_DEVELOPER.md` 참고
2. **ARCHITECTURE.md** → 프로젝트 구조 확인
3. **PRD.md** → 구현할 기능의 수락 기준 확인
4. **tasks/epic-X/** → 개별 태스크 수행

---

## 🎯 프로젝트 개요

### 앱 정보
- **앱 이름**: 호구미터 (HoguMeter)
- **플랫폼**: iOS (iPhone)
- **최소 지원 버전**: iOS 17.0+
- **개발 기간**: 6주
- **기술 스택**: Swift 5.9+, SwiftUI, Core Location

### 핵심 기능
1. **실시간 택시 미터기** - GPS 기반 거리/시간 요금 계산
2. **🐴 달리는 말 애니메이션** - 속도에 따라 변하는 재미있는 애니메이션
3. **시간대별 요금 설정** - 주간/심야1/심야2 시간대별 정확한 요금 계산
4. **지역별 요금 설정** - 서울시 택시 요금 기준 (사용자 지정 가능)
5. **야간/지역 할증** - 자동 할증 적용
6. **영수증 공유** - 카카오톡으로 재미있는 영수증 공유

---

## ✅ 구현 현황

### Epic 0: 앱 초기 설정 ✅ 완료
- [x] Task 0.1: 면책 동의 다이얼로그
- [x] Task 0.2: 주행 기록 통합
- [x] Task 0.3: 앱 아이콘
- [x] Task 0.4: 런치 스크린 및 로딩 애니메이션

### Epic 1: 미터기 핵심 기능 🚧 진행 중
- [x] Task 1.1: 실시간 거리 계산
- [x] Task 1.2: 실시간 요금 계산
- [ ] Task 1.3: 미터기 UI 개선
- [ ] Task 1.4: 컨트롤 버튼 (시작/정지/리셋)

### Epic 2: 말 애니메이션 🔜 예정
- [ ] Task 2.1: 말 캐릭터 에셋
- [ ] Task 2.2: 속도별 애니메이션 (걷기/달리기/질주)
- [ ] Task 2.3: 80km/h 특수 효과

### Epic 3: 요금 설정 ✅ 완료
- [x] Task 3.1: 지역별 요금 추가 및 편집
  - 서울시 택시요금 체계 (2023.02.01 기준)
  - 주간 요금 (04:00 ~ 22:00)
  - 심야1 요금 (22:00 ~ 23:00, 02:00 ~ 04:00) - 20% 할증
  - 심야2 요금 (23:00 ~ 02:00) - 40% 할증

### Epic 4: 영수증 공유 🔜 예정
- [ ] Task 4.1: 영수증 디자인
- [ ] Task 4.2: 카카오톡 공유
- [ ] Task 4.3: 이미지 저장

### Epic 5: 사운드 🔜 예정
- [ ] Task 5.1: 효과음 연동
- [ ] Task 5.2: 배경음악 (선택)

### Epic 6: 주행 기록 🔜 예정
- [ ] Task 6.1: 기록 저장
- [ ] Task 6.2: 기록 목록 보기
- [ ] Task 6.3: 기록 상세 보기

### Epic 7: 설정 🔜 예정
- [ ] Task 7.1: 다크모드
- [ ] Task 7.2: 앱 정보
- [ ] Task 7.3: 설정 UI 통합

---

## 🏗️ 프로젝트 구조

```
HoguMeter/
├── HoguMeter/
│   ├── App/                    # 앱 진입점
│   ├── Core/                   # 코어 유틸리티
│   ├── Data/                   # 데이터 레이어
│   │   └── Repositories/       # Repository 구현
│   ├── Domain/                 # 도메인 레이어
│   │   ├── Entities/           # 도메인 엔티티
│   │   ├── Services/           # 도메인 서비스
│   │   └── UseCases/           # 유즈케이스
│   ├── Presentation/           # 프레젠테이션 레이어
│   │   ├── ViewModels/         # ViewModel
│   │   └── Views/              # SwiftUI View
│   └── Resources/              # 리소스 파일
│       └── Assets.xcassets/    # 에셋 카탈로그
├── docs/                       # 프로젝트 문서
│   ├── PROJECT_BRIEF.md
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   └── DEVELOPMENT_GUIDE*.md
└── tasks/                      # Epic별 개발 태스크
    ├── epic-0-app-setup/
    ├── epic-1-meter-core/
    ├── epic-2-horse-animation/
    ├── epic-3-fare-settings/
    ├── epic-4-receipt-share/
    ├── epic-5-sound/
    ├── epic-6-history/
    └── epic-7-settings/
```

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

### Claude CLI로 개발하기

```bash
# Claude CLI 실행
claude

# AI와 대화하며 개발
> tasks/epic-1-meter-core/task-1.3.md를 읽고 미터기 UI를 개선해줘.
> 말 애니메이션 컴포넌트를 만들어줘. 속도에 따라 다르게 움직여야 해.
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
| 오디오 | AVFoundation |
| 상태 관리 | @Observable (iOS 17+) |
| IDE | Xcode 15+ |

---

## 🎨 주요 특징

### 1. 시간대별 정확한 요금 계산
서울시 택시요금 체계 (2023.02.01 기준)를 정확히 반영:
- **주간** (04:00 ~ 22:00): 기본 4,800원
- **심야1** (22:00 ~ 23:00, 02:00 ~ 04:00): 기본 5,800원 (20% 할증)
- **심야2** (23:00 ~ 02:00): 기본 6,700원 (40% 할증)

### 2. Clean Architecture
- Domain, Data, Presentation 레이어 분리
- 테스트 가능한 구조
- 의존성 역전 원칙 적용

### 3. SwiftUI + iOS 17
- 최신 SwiftUI 기능 활용
- @Observable 매크로로 간결한 상태 관리
- 선언적 UI

---

## 📱 지원 기기

- **iPhone**: iPhone 12 이상 권장
- **iOS**: 17.0 이상
- **화면**: 모든 iPhone 크기 지원

---

## 🧪 테스트

```bash
# 단위 테스트 실행
⌘ + U

# UI 테스트 실행
⌘ + U (UI Test 타겟 선택)
```

---

## 📦 빌드 및 배포

### 개발 빌드
```bash
# Simulator용 빌드
xcodebuild -project HoguMeter.xcodeproj \
  -scheme HoguMeter \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### 배포 준비
1. App Store Connect에 앱 등록
2. 버전 및 빌드 번호 업데이트
3. Archive 생성 (⌘ + B → Product → Archive)
4. TestFlight 배포 또는 App Store 제출

---

## 📄 라이선스

MIT License - All Rights Reserved

---

## 👥 기여하기

이 프로젝트는 학습 및 포트폴리오 목적으로 개발되었습니다.

---

## 📞 연락처

프로젝트 관련 문의: imdevbada@gmail.com

---

## 🗺️ 로드맵

### Phase 1: Foundation ✅ 완료
- [x] 프로젝트 셋업
- [x] 기본 UI 레이아웃
- [x] Core Location 연동
- [x] 앱 아이콘 및 런치 스크린

### Phase 2: Core Features 🚧 진행 중
- [x] GPS 거리 계산
- [x] 실시간 요금 계산
- [x] 시간대별 요금 시스템
- [ ] 미터기 UI 개선

### Phase 3: Animation 🔜 예정
- [ ] 말 캐릭터 에셋
- [ ] 속도별 애니메이션
- [ ] 80km/h 특수 효과

### Phase 4: Additional Features 🔜 예정
- [ ] 설정 화면 통합
- [ ] 주행 기록 저장
- [ ] 영수증 공유

### Phase 5: Polish 🔜 예정
- [ ] 효과음 연동
- [ ] 다크모드 완성
- [ ] UI 다듬기

### Phase 6: Release 🔜 예정
- [ ] 테스트
- [ ] 앱스토어 준비
- [ ] 심사 제출

---

> 🐴 **"호구미터와 함께라면, 모든 드라이브가 즐거워집니다!"**
