# Task 2.1: 속도 연동 애니메이션

> **Epic**: Epic 2 - 말 애니메이션
> **Status**: 🟢 Done
> **Priority**: P0
> **Estimate**: 6시간
> **PRD**: FR-2.1

---

## 📋 개요

차량 속도에 따라 말의 애니메이션이 자동으로 변경되는 시스템을 구현합니다.

## 🎯 목표

속도 변화 시 0.3초 이내에 부드럽게 애니메이션이 전환되며, 60fps를 유지합니다.

## ✅ Acceptance Criteria

- [x] 6단계 속도 구간별 애니메이션 구현
- [x] 속도 변화 시 0.3초 내 애니메이션 전환
- [x] 부드러운 전환 애니메이션
- [x] 60fps 유지
- [x] HorseSpeed enum 정의 완료

## 📝 구현 사항

### 1. 애니메이션 리소스 추가
- [ ] 말 idle 이미지/애니메이션
- [ ] 말 walk 이미지/애니메이션
- [ ] 말 trot 이미지/애니메이션
- [ ] 말 run 이미지/애니메이션
- [ ] 말 gallop 이미지/애니메이션
- [ ] 말 sprint 이미지/애니메이션

### 2. HorseAnimationView 확장
```swift
// 현재: 임시 이모지 사용
// 목표: 실제 애니메이션 리소스 연동
```

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Entities/MeterState.swift` - HorseSpeed enum
- [x] `HoguMeter/Presentation/Views/Main/Components/HorseAnimationView.swift`
- [x] `HoguMeter/Presentation/ViewModels/MeterViewModel.swift`

---

## 📝 구현 노트

### 주요 구현 내용

1. **속도별 애니메이션 시스템** (HoguMeter/Presentation/Views/Main/Components/HorseAnimationView.swift:13-158)
   - 6단계 속도 구간별 차별화된 애니메이션
   - `@State` 기반 애니메이션 상태 관리 (animationPhase, rotationAngle)
   - 속도 변화 감지 및 자동 애니메이션 전환

2. **바운싱 효과**
   - 속도에 비례한 바운싱 강도 (idle: 0 ~ sprint: 10)
   - sin 함수 기반 자연스러운 상하 움직임
   - 스케일 변화와 오프셋 조합

3. **부드러운 전환**
   - easeInOut 애니메이션 (0.3초 duration)
   - 속도별 애니메이션 주기 최적화 (walk: 1.0s ~ sprint: 0.2s)
   - 미세한 회전 효과로 역동성 추가

4. **성능 최적화**
   - SwiftUI 네이티브 애니메이션 사용 (60fps 보장)
   - linear + repeatForever로 효율적인 루프
   - 조건부 애니메이션 (idle 시 애니메이션 중지)

### 기술 스택
- SwiftUI Animation API
- @State property wrapper
- withAnimation + repeatForever

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
