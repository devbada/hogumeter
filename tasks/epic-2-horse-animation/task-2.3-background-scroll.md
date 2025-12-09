# Task 2.3: 배경 스크롤

> **Epic**: Epic 2 - 말 애니메이션
> **Status**: 🟢 Done
> **Priority**: P1
> **Estimate**: 4시간
> **PRD**: FR-2.3

---

## 📋 개요

말이 달리는 배경이 속도에 맞춰 스크롤되는 효과를 구현합니다.

## ✅ Acceptance Criteria

- [x] 도로/풍경 배경 무한 스크롤
- [x] 속도에 비례한 스크롤 속도
- [x] 낮/밤 배경 전환 (시간대별)

---

## 📝 구현 노트

### 주요 구현 내용

1. **BackgroundScrollView 컴포넌트 생성** (HoguMeter/Presentation/Views/Main/Components/BackgroundScrollView.swift:1-154)
   - 속도에 연동된 무한 스크롤 배경 시스템
   - 시간대별 낮/밤 자동 전환

2. **하늘 그라데이션**
   - 낮: 파란색 → 청록색 → 흰색 그라데이션
   - 밤: 검정 → 파란색 → 보라색 그라데이션
   - 시간 감지: 오후 6시 ~ 오전 6시는 야간 모드

3. **도로 스크롤 시스템**
   - 3개 세그먼트 반복 렌더링
   - 각 세그먼트 높이 400pt
   - 중앙선 10개 반복 (흰색 점선)
   - 도로 테두리 (노란색 선)
   - 낮/밤 투명도 차별화

4. **무한 스크롤 구현**
   - scrollOffset State로 Y축 오프셋 관리
   - linear 애니메이션으로 부드러운 스크롤
   - 세그먼트 높이만큼 이동 후 리셋
   - DispatchQueue로 재귀 호출하여 무한 반복

5. **속도별 스크롤 속도**
   - idle: 정지 (0초)
   - walk: 느림 (4.0초)
   - trot: 보통 (3.0초)
   - run: 빠름 (2.0초)
   - gallop: 매우 빠름 (1.5초)
   - sprint: 초고속 (0.8초)

6. **HorseAnimationView 통합**
   - ZStack 최하단 레이어로 배경 배치
   - clipShape(RoundedRectangle)으로 깔끔한 모서리

### 기술 스택
- SwiftUI VStack + ForEach 무한 반복
- LinearGradient 하늘 표현
- @State + withAnimation 스크롤
- Calendar API 시간대 감지
- DispatchQueue 재귀 애니메이션

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
