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
| [PROJECT_BRIEF.md](./PROJECT_BRIEF.md) | 프로젝트 개요, 비전, 목표, 페르소나, 기능 개요 | ✅ 완료 |
| [PRD.md](./PRD.md) | 상세 기능 요구사항, User Stories, 화면 흐름 | ✅ 완료 |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 기술 스택, 아키텍처, 핵심 컴포넌트 설계 | ✅ 완료 |
| STORIES/ | Epic별 개발 스토리 (추후 생성) | 🔜 예정 |

---

## 🎯 프로젝트 개요

### 앱 정보
- **앱 이름**: 호구미터 (HoguMeter)
- **플랫폼**: iOS (iPhone)
- **개발 기간**: 5-6주
- **기술 스택**: Swift 5.9+, SwiftUI, Core Location

### 핵심 기능
1. **실시간 택시 미터기** - GPS 기반 거리/시간 요금 계산
2. **🐴 달리는 말 애니메이션** - 속도에 따라 변하는 재미있는 애니메이션
3. **지역별 요금 설정** - 한국 주요 도시 택시 요금 기준
4. **야간/지역 할증** - 자동 할증 적용
5. **영수증 공유** - 카카오톡으로 재미있는 영수증 공유

---

## 🏃 개발 로드맵

```
Week 1: Foundation
├── 프로젝트 셋업
├── 기본 UI 레이아웃
└── Core Location 연동

Week 2: Core Features
├── GPS 거리 계산
├── 실시간 요금 계산
└── 야간/지역 할증

Week 3: Animation 🐴
├── 말 캐릭터 에셋
├── 속도별 애니메이션
└── 80km/h 특수 효과

Week 4: Additional Features
├── 설정 화면
├── 주행 기록 저장
└── 영수증 공유

Week 5: Polish
├── 효과음 연동
├── 다크모드
└── UI 다듬기

Week 6: Release
├── 테스트
├── 앱스토어 준비
└── 심사 제출
```

---

## 🚀 시작하기 (Claude CLI 사용)

### 1. 프로젝트 셋업
```bash
# 프로젝트 폴더로 이동
cd HoguMeter

# Claude CLI 실행
claude
```

### 2. Claude CLI에서 개발 시작
```
> 이 문서들을 읽고 HoguMeter iOS 프로젝트를 생성해줘.
  먼저 Xcode 프로젝트 구조부터 만들어줘.

> PRD.md의 FR-1.1 (미터기 시작/정지/리셋) 기능을 구현해줘.

> 말 애니메이션 컴포넌트를 만들어줘. 
  속도에 따라 다르게 움직여야 해.
```

---

## 📋 BMAD Method 워크플로우

### Phase 1: Planning (완료 ✅)
1. **Project Brief** - 프로젝트 개요 및 비전 정의
2. **PRD** - 상세 기능 요구사항 정의
3. **Architecture** - 기술 아키텍처 설계

### Phase 2: Development (예정 🔜)
1. **Story Creation** - Epic별 개발 스토리 생성
2. **Implementation** - 스토리 기반 개발
3. **Testing** - 단위/통합/UI 테스트

### Phase 3: Release (예정 🔜)
1. **Beta Testing** - TestFlight 배포
2. **App Store Submission** - 심사 제출
3. **Launch** - 출시

---

## 📖 문서 읽는 순서

처음 프로젝트를 파악할 때:
1. **PROJECT_BRIEF.md** → 전체 그림 파악
2. **PRD.md** → 상세 기능 이해
3. **ARCHITECTURE.md** → 기술 구현 방향

개발 시작 시:
1. **ARCHITECTURE.md** → 프로젝트 구조 확인
2. **PRD.md** → 구현할 기능의 수락 기준 확인
3. **STORIES/** → 개별 스토리 태스크 수행

---

## 🛠️ 기술 스택

| 카테고리 | 기술 |
|---------|------|
| Language | Swift 5.9+ |
| UI | SwiftUI (iOS 15+) |
| 위치 | Core Location |
| 저장 | Core Data |
| 오디오 | AVFoundation |
| IDE | Xcode 15+ |

---

## 📱 지원 기기

- iPhone SE (2nd gen) 이상
- iOS 15.0 이상

---

## 📄 라이선스

MIT - All Rights Reserved

---

## 👤 연락처

프로젝트 관련 문의: [imdevbada@gmail.com]

---

> 🐴 **"호구미터와 함께라면, 모든 드라이브가 즐거워집니다!"**
