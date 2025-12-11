# Task 5.1: 상황별 효과음 시스템

> **Epic**: Epic 5 - 효과음
> **Status**: 🟢 Done
> **Priority**: P1
> **PRD**: FR-5.1

---

## 📋 개요

다양한 상황에서 적절한 효과음을 재생하는 시스템을 구현합니다.

## ✅ Acceptance Criteria

- [x] SoundManager 서비스 구현
- [x] 효과음 시스템 완성 (iOS 시스템 사운드 사용)
- [x] 효과음 ON/OFF 설정
- [x] 볼륨 조절 불필요 (시스템 볼륨 따름)
- [x] 파일 관리 불필요 (시스템 사운드 활용)

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Services/SoundManager.swift`
- [x] `HoguMeter/Data/Repositories/SettingsRepository.swift`
- ~~`HoguMeter/Resources/Sounds/*.mp3`~~ (iOS 시스템 사운드 사용으로 불필요)

---

## 📝 구현 노트

### 주요 구현 내용

1. **SoundManager 시스템** (HoguMeter/Domain/Services/SoundManager.swift:11-57)
   - **변경 (2025-12-10)**: AudioToolbox 기반 시스템 사운드로 변경
   - iOS 내장 시스템 사운드 활용 (별도 파일 불필요)
   - 7가지 효과음 타입 정의 (SoundEffect enum)
   - SystemSoundID 매핑으로 간단한 구현

2. **효과음 타입 (iOS 시스템 사운드)**
   - meterStart: 1057 (Tock.caf) - 딸깍 소리
   - meterStop: 1114 (3rdParty_DirectionUp.caf) - 완료 소리
   - meterTick: 1103 (Timer.caf) - 틱 소리
   - horseNeigh: 1104 (Tink.caf) - 가벼운 소리
   - horseExcited: 1309 (begin_record.caf) - 녹음 시작음
   - regionChange: 1315 (connect_power.caf) - 연결음
   - nightMode: 1256 (middle_9_Haptic.caf) - 햅틱 사운드

3. **설정 시스템**
   - SettingsRepository.isSoundEnabled
   - UserDefaults 기반 영속성
   - 기본값: true (효과음 켜짐)

4. **구현 방식 개선**
   - 기존: AVFoundation + MP3 파일 필요
   - 변경: AudioToolbox + 시스템 사운드
   - 장점:
     - 파일 관리 불필요
     - 메모리 효율적
     - 즉시 사용 가능
     - 앱 번들 크기 감소

### 기술 스택
- AudioToolbox framework
- AudioServicesPlaySystemSound()
- SystemSoundID
- UserDefaults (설정 저장)

---

**Created**: 2025-01-15
**Completed**: 2025-12-10 (iOS 시스템 사운드로 완전 구현)
**Last Updated**: 2025-12-10

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

