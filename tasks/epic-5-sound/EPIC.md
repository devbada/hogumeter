# Epic 5: 효과음 시스템 (Sound Effects)

> **Priority**: P1 (Should Have)
> **Status**: 🟢 Done
> **Target**: Week 5
> **PRD Reference**: Epic 5 (FR-5.1)

---

## 📋 Epic 개요

다양한 상황에서 적절한 효과음을 재생하여 사용자 경험을 향상시킵니다.

## 🎯 Epic 목표

- [x] SoundManager 서비스 구현
- [x] 효과음 시스템 완성 (리소스 스펙 정의)
- [x] 상황별 효과음 재생 로직

## 📊 Task 목록

| Task | Title | Status | Priority | PRD |
|------|-------|--------|----------|-----|
| 5.1 | 상황별 효과음 시스템 | 🟢 Done | P1 | FR-5.1 |

## 📝 효과음 목록 (iOS 시스템 사운드)

| 이벤트 | iOS 시스템 사운드 | Sound ID | 설명 |
|--------|------------------|----------|------|
| 미터기 시작 | Tock.caf | 1057 | 딸깍 소리 |
| 미터기 정지 | 3rdParty_DirectionUp.caf | 1114 | 완료 소리 |
| 요금 증가 | Timer.caf | 1103 | 틱 소리 |
| 말 기본 | Tink.caf | 1104 | 가벼운 소리 |
| 말 흥분 (80km/h+) | begin_record.caf | 1309 | 녹음 시작음 |
| 지역 변경 | connect_power.caf | 1315 | 연결음 |
| 야간 모드 | middle_9_Haptic.caf | 1256 | 햅틱 사운드 |

## 📊 진행 상황

**전체 진행률**: 100% (1/1 Tasks 완료)

## 📝 주요 구현 결과

1. **SoundManager 시스템** (HoguMeter/Domain/Services/SoundManager.swift:11-57)
   - AudioToolbox 프레임워크 사용
   - iOS 기본 시스템 사운드 활용
   - 별도 오디오 파일 불필요
   - 메모리 효율적

2. **7가지 효과음 타입**
   - meterStart, meterStop, meterTick
   - horseNeigh, horseExcited
   - regionChange, nightMode

3. **설정 시스템**
   - SettingsRepository.isSoundEnabled
   - 사운드 on/off 토글 기능

4. **구현 방식 변경** (2025-12-10)
   - 기존: AVFoundation + MP3 파일
   - 변경: AudioToolbox + iOS 시스템 사운드
   - 장점: 파일 관리 불필요, 즉시 사용 가능, 가벼움

---

**Created**: 2025-01-15
**Completed**: 2025-12-10 (iOS 시스템 사운드로 완성)
**Last Updated**: 2025-12-10
