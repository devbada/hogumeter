# Sound Effects

이 폴더에는 HoguMeter 앱에서 사용할 효과음 파일들이 위치해야 합니다.

## 필요한 효과음 파일 (MP3 형식)

### 1. meter_start.mp3
- **용도**: 미터기 시작 시
- **설명**: 경쾌한 시작 사운드
- **권장 길이**: 1-2초

### 2. meter_stop.mp3
- **용도**: 미터기 정지 시
- **설명**: 마무리 사운드
- **권장 길이**: 1-2초

### 3. meter_tick.mp3
- **용도**: 요금 증가 시 (틱 사운드)
- **설명**: 짧은 틱 소리
- **권장 길이**: 0.5초 이하

### 4. horse_neigh.mp3
- **용도**: 일반 속도 변화 시
- **설명**: 말 울음소리 (히힝~)
- **권장 길이**: 1-2초

### 5. horse_excited.mp3
- **용도**: 80km/h 이상 sprint 모드 진입 시
- **설명**: 흥분한 말 울음소리 (히히힝!)
- **권장 길이**: 1-2초

### 6. region_change.mp3
- **용도**: 지역 변경 감지 시
- **설명**: 알림 사운드
- **권장 길이**: 1초

### 7. night_mode.mp3
- **용도**: 야간 모드 진입 시
- **설명**: 차분한 알림 사운드
- **권장 길이**: 1-2초

## 사운드 획득 방법

### 1. 무료 사운드 라이브러리
- **Freesound.org**: https://freesound.org/
- **Zapsplat**: https://www.zapsplat.com/
- **BBC Sound Effects**: https://sound-effects.bbcrewind.co.uk/

### 2. 자체 제작
- GarageBand, Audacity 등 오디오 편집 툴 활용
- 음성 녹음 및 편집

### 3. AI 생성
- ElevenLabs, Mubert 등의 AI 사운드 생성 서비스 활용

## 주의사항

- 모든 파일은 **MP3 형식**이어야 합니다
- 파일명은 위에 명시된 정확한 이름을 사용해야 합니다
- 파일은 Xcode 프로젝트에 추가되어야 합니다
- 라이선스를 확인하여 상업적 사용이 가능한지 확인하세요

## 시스템 사운드 대안 (임시)

실제 효과음 파일이 준비되기 전까지는 iOS 시스템 사운드를 사용할 수 있습니다:
- AudioServicesPlaySystemSound() 활용
- SystemSoundID 사용

## 구현 상태

- ✅ SoundManager 구현 완료
- ✅ SettingsRepository에 효과음 ON/OFF 설정 추가 완료
- ⏳ 실제 효과음 파일 추가 대기 중
