# 🐴 HoguMeter Tasks

> **BMAD Method v6 | Task Management**

이 폴더는 HoguMeter 프로젝트의 개발 태스크를 Epic 단위로 관리합니다.

## 📁 폴더 구조

```
tasks/
├── README.md                    # Task 관리 가이드 (이 파일)
├── _templates/                  # Task 작성 템플릿
├── epic-1-meter-core/          # Epic 1: 미터기 핵심 기능
├── epic-2-horse-animation/     # Epic 2: 말 애니메이션 시스템
├── epic-3-fare-settings/       # Epic 3: 요금 설정 시스템
├── epic-4-receipt-share/       # Epic 4: 영수증 및 공유
├── epic-5-sound/               # Epic 5: 효과음 시스템
├── epic-6-history/             # Epic 6: 주행 기록
└── epic-7-settings/            # Epic 7: 설정 및 기타
```

## 🎯 Epic 우선순위

| Priority | Epic | Status | Progress | Target |
|----------|------|--------|----------|--------|
| P0 | Epic 1: 미터기 핵심 | 🟢 Done | 5/5 Tasks | Week 1-2 |
| P0 | Epic 2: 말 애니메이션 | 🟢 Done (간소화) | 1/3 Tasks | Week 3 |
| P1 | Epic 3: 요금 설정 | 🟢 Done | 3/3 Tasks | Week 2 |
| P1 | Epic 4: 영수증/공유 | 🟢 Done | 2/2 Tasks | Week 4 |
| P1 | Epic 5: 효과음 | 🟢 Done | 1/1 Tasks | Week 5 |
| P2 | Epic 6: 주행 기록 | 🟢 Done | 2/2 Tasks | Week 4 |
| P2 | Epic 7: 설정/기타 | 🟢 Done | 2/2 Tasks | Week 5 |

**전체 완료율**: 100% (모든 핵심 기능 완료)

## 📝 Task 작성 가이드

### Task 파일명 규칙
```
task-{epic번호}.{task번호}-{task명}.md
```

예: `task-1.1-meter-controls.md`

### Task 상태
- 🔵 **Ready**: 작업 준비 완료
- 🟡 **In Progress**: 작업 진행 중
- 🟢 **Done**: 작업 완료
- 🔴 **Blocked**: 작업 블로킹

### 새 Task 생성 방법

1. `_templates/TASK_TEMPLATE.md` 복사
2. 해당 Epic 폴더에 붙여넣기
3. 파일명 규칙에 맞게 이름 변경
4. Task 내용 작성

## 🚀 개발 워크플로우

### 1. Epic 선택
```bash
# Epic 폴더로 이동
cd tasks/epic-1-meter-core/
```

### 2. Task 확인
```bash
# EPIC.md에서 전체 개요 확인
cat EPIC.md

# 개별 Task 확인
cat task-1.1-meter-controls.md
```

### 3. 작업 시작
- Task 파일의 Status를 🟡 In Progress로 변경
- Acceptance Criteria 확인
- 구현 시작

### 4. 작업 완료
- [ ] 모든 Acceptance Criteria 충족
- [ ] 코드 리뷰 완료
- [ ] 테스트 작성 및 통과
- [ ] Status를 🟢 Done으로 변경

## 📊 진행 상황 추적

### Epic별 진행률 확인
```bash
# 각 Epic 폴더의 EPIC.md에서 Task 완료율 확인
grep -r "Status:" tasks/epic-1-meter-core/
```

### 전체 프로젝트 진행률
```bash
# 완료된 Task 수 확인
find tasks -name "task-*.md" -exec grep "Status: 🟢" {} \; | wc -l
```

## 🔗 관련 문서

- [PROJECT_BRIEF.md](../docs/PROJECT_BRIEF.md) - 프로젝트 개요
- [PRD.md](../docs/PRD.md) - 상세 요구사항
- [ARCHITECTURE.md](../docs/ARCHITECTURE.md) - 기술 아키텍처

## 💡 Tips

### Claude Code와 함께 사용하기

```bash
# Claude에게 특정 Epic 작업 요청
> tasks/epic-1-meter-core/task-1.1-meter-controls.md 파일을 읽고 구현해줘

# Task 생성 요청
> tasks/_templates/TASK_TEMPLATE.md를 사용해서
> "Core Data 연동" task를 생성해줘

# 진행 상황 업데이트
> task-1.1의 상태를 Done으로 변경해줘
```

### Task 분할 전략

하나의 Task가 너무 크다면:
1. Sub-task로 분할
2. 별도 Task 파일로 생성
3. 원래 Task에서 Sub-task 참조

## 📌 Convention

### Commit 메시지
```
[Epic-{번호}] Task {번호}: {작업 내용}

예: [Epic-1] Task 1.1: Implement meter start/stop controls
```

### Branch 네이밍
```
epic-{번호}/task-{번호}-{task명}

예: epic-1/task-1.1-meter-controls
```

## 🎓 BMAD Method 참고

이 Task 관리 방식은 **BMAD Method v6**를 따릅니다:
- **B**reakdown: Epic을 Task로 분해
- **M**easure: Acceptance Criteria로 측정
- **A**gile: 점진적 개발
- **D**ocument: 문서화된 진행 상황

---

## 📊 최신 업데이트 (2025-12-10)

### ✅ 완료된 작업
- **Epic 1**: 모든 Task 완료 (Info.plist 위치 권한 설정 포함)
- **Epic 2**: 복잡한 애니메이션 삭제, 이모지 기반 간소화
- **Epic 3**: 모든 Task 완료, 상태 업데이트
- **Epic 4-7**: 모든 기능 구현 완료
- **RegionDetector**: 상세 주소 표시로 개선 ("서울특별시 영등포구")
- **SoundManager**: iOS 시스템 사운드로 변경 (파일 관리 불필요)

### 📝 주요 변경사항
- 2025-12-10: Epic 1 완료 (Info.plist 권한 설정)
- 2025-12-10: SoundManager를 iOS 시스템 사운드로 변경
- 2025-12-10: RegionDetector 상세 주소 표시 개선
- 2025-12-09: Epic 2 애니메이션 간소화 (SprintEffectView, BackgroundScrollView 삭제)
- 2025-12-09: Epic 2-7 모든 Task 구현 완료

### 🎉 프로젝트 완료
**모든 Epic 완료!** 7개 Epic, 15개 Task 모두 구현 완료되었습니다.

---

**Created**: 2025-01-15
**Last Updated**: 2025-12-10
