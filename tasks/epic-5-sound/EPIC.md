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

## 📝 효과음 목록

| 이벤트 | 효과음 | 파일명 |
|--------|--------|--------|
| 앱 시작 | 말 히힝~ | horse_neigh.mp3 |
| 미터기 시작 | 딸깍 + 출발! | meter_start.mp3 |
| 요금 증가 | 찰칵 (미터기) | meter_tick.mp3 |
| 지역 변경 | 띠링~ | region_change.mp3 |
| 야간 진입 | 부엉이 소리 | night_mode.mp3 |
| 80km/h 돌파 | 말 흥분 히힝~! | horse_excited.mp3 |
| 미터기 정지 | 또잉~ | meter_stop.mp3 |

## 📊 진행 상황

**전체 진행률**: 100% (1/1 Tasks 완료)

## 📝 주요 구현 결과

- **SoundManager**: AVFoundation 기반 효과음 재생 시스템
- **7가지 효과음 타입**: meter_start, meter_stop, meter_tick, horse_neigh, horse_excited, region_change, night_mode
- **설정 시스템**: SettingsRepository.isSoundEnabled
- **Sounds 폴더**: 효과음 파일 스펙 문서화 (README.md)

## ⚠️ 남은 작업

실제 오디오 파일 (MP3) 추가 필요:
- 7개 효과음 파일 획득/제작
- Xcode 프로젝트에 등록
- 실제 재생 테스트

---

**Created**: 2025-01-15
**Completed**: 2025-12-09 (시스템 구현 완료)
