# Task 2.2: 80km/h 특수 효과

> **Epic**: Epic 2 - 말 애니메이션
> **Status**: ⚪ 삭제됨
> **Priority**: P0
> **Estimate**: 4시간
> **PRD**: FR-2.2

---

## ⚠️ 삭제 알림

이 Task는 **2025-12-09**에 복잡도 문제로 삭제되었습니다.

**삭제 사유**:
- 애니메이션이 너무 복잡함
- 유지보수 어려움
- 간단한 이모지 기반 구현으로 충분

**대체 구현**:
- 80km/h 이상: 🏇💨🔥 이모지 + "폭주!" 텍스트로 표시

---

## 📝 이전 구현 기록 (참고용)

---

## 📋 개요

80km/h 이상 속도에서 표시되는 만화적 특수 효과를 구현합니다.

## ✅ Acceptance Criteria

- [x] 말의 다리가 원형으로 빠르게 회전 (만화 효과)
- [x] 속도선 이펙트 추가
- [x] 먼지 구름 파티클
- [x] 말 표정 변화 (흥분)
- [ ] 특수 효과음 (히힝~!) - Epic 5에서 구현 예정

---

## 📝 구현 노트

### 주요 구현 내용

1. **SprintEffectView 컴포넌트 생성** (HoguMeter/Presentation/Views/Main/Components/SprintEffectView.swift:1-113)
   - 80km/h 이상 sprint 모드 전용 특수 효과 컴포넌트
   - ZStack 기반 멀티 레이어 효과 구성

2. **속도선 이펙트**
   - 5개 평행선이 연속적으로 흐르는 효과
   - LinearGradient로 투명도 처리 (오렌지 → 투명)
   - 0.3초 주기 linear 애니메이션
   - 각도 -5도 회전으로 역동적 표현

3. **먼지 구름 파티클**
   - 3개 Circle로 구성된 파티클 시스템
   - 크기 점진 증가 (20 → 40)
   - 0.5초 주기 easeInOut opacity 애니메이션
   - blur(radius: 3)로 자연스러운 먼지 표현

4. **말 다리 회전 효과 (만화 스타일)**
   - 원형 stroke로 회전하는 다리 표현
   - 갈색 그라데이션 (위→아래 투명)
   - 0.15초 초고속 회전 (360도)
   - 말 하단에 위치 (offset y: 30)

5. **HorseAnimationView 통합**
   - sprint 속도일 때만 SprintEffectView 렌더링
   - 조건부 렌더링으로 성능 최적화
   - 기존 말 애니메이션과 레이어 합성

### 기술 스택
- SwiftUI ZStack 레이어링
- LinearGradient 효과
- @State + withAnimation 조합
- 조건부 뷰 렌더링

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
