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
- [x] 효과음 파일 스펙 정의 (7개)
- [x] 효과음 ON/OFF 설정
- [x] 볼륨 조절 불필요 (시스템 볼륨 따름)
- [x] 다른 오디오와 동시 재생 가능 (.ambient 모드)

## 🔗 관련 파일

- [x] `HoguMeter/Domain/Services/SoundManager.swift`
- [ ] `HoguMeter/Resources/Sounds/*.mp3`
- [x] `HoguMeter/Data/Repositories/SettingsRepository.swift`

## 📝 TODO

- [ ] 효과음 파일 획득/제작
- [ ] Resources/Sounds 폴더에 추가
- [ ] Xcode 프로젝트에 리소스 등록
- [ ] 실제 재생 테스트

---

## 📝 구현 노트

### 주요 구현 내용

1. **SoundManager 시스템** (HoguMeter/Domain/Services/SoundManager.swift:1-75)
   - AVFoundation 기반 오디오 재생 시스템
   - 7가지 효과음 타입 정의 (SoundEffect enum)
   - AVAudioPlayer 캐싱으로 성능 최적화
   - .ambient 오디오 세션으로 다른 앱 오디오와 병행 재생

2. **효과음 타입**
   - meter_start: 미터기 시작
   - meter_stop: 미터기 정지
   - meter_tick: 요금 증가 틱
   - horse_neigh: 일반 말 울음소리
   - horse_excited: sprint 모드 흥분한 말
   - region_change: 지역 변경 알림
   - night_mode: 야간 모드 진입

3. **설정 시스템**
   - SettingsRepository.isSoundEnabled (이미 구현됨)
   - UserDefaults 기반 영속성
   - 기본값: true (효과음 켜짐)

4. **오디오 세션 설정**
   - AVAudioSession.Category.ambient
   - 다른 오디오 앱과 동시 재생 가능
   - 시스템 볼륨 따름

5. **Sounds 리소스 폴더**
   - HoguMeter/Resources/Sounds/ 생성
   - README.md로 필요한 파일 스펙 문서화
   - 7개 MP3 파일 필요 (각 1-2초)

### 남은 작업

⚠️ **실제 효과음 파일 추가 필요**
- 현재 시스템 구현은 완료됨
- Sounds/README.md에 명시된 7개 MP3 파일 필요
- 무료 사운드 라이브러리나 자체 제작 필요
- 파일 추가 후 Xcode 프로젝트에 등록

### 기술 스택
- AVFoundation framework
- AVAudioPlayer (캐싱)
- AVAudioSession (.ambient)
- UserDefaults (설정 저장)

---

**Created**: 2025-01-15
**Completed**: 2025-12-09 (시스템 구현 완료, 오디오 파일은 추후 추가)
