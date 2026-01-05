# HoguMeter App Store Screenshots

App Store 제출용 스크린샷 생성 가이드입니다.

## 필요한 스크린샷

### iPhone (필수)
- **크기**: 1284 x 2778 픽셀 (iPhone 14 Pro Max / 15 Pro Max)
- **개수**: 최소 3개, 최대 10개
- **형식**: PNG 또는 JPEG (투명도 불가)

### 권장 스크린샷 구성 (6개)
1. **메인 화면 (대기)** - 기본요금 표시, 시작 버튼
2. **주행 중** - 요금 계산 중, 말 애니메이션
3. **영수증** - 상세 요금 내역
4. **설정** - 할증 설정, 다크 모드
5. **지역별 요금** - 7개 도시 요금 목록
6. **주행 기록** - 기록 목록

---

## 방법 1: Xcode Preview 사용 (권장)

### 1단계: Preview 파일 열기
```
Xcode에서 열기:
HoguMeter/Presentation/Views/AppStoreScreenshots.swift
```

### 2단계: Preview Canvas 설정
1. Xcode 우측 상단의 "Canvas" 버튼 클릭하여 Preview 활성화
2. Preview에서 "iPhone 15 Pro Max" 디바이스 선택
3. 각 Preview 탭 선택:
   - "1. 메인 화면 (대기)"
   - "2. 주행 중"
   - "3. 영수증"
   - "4. 설정"
   - "5. 지역별 요금"
   - "6. 주행 기록"

### 3단계: 스크린샷 캡처
각 Preview에서:
1. Preview Canvas 우클릭
2. "Copy" 선택 또는 Cmd+C
3. Preview 앱에서 붙여넣기하여 저장
4. 또는 Cmd+Shift+4 후 Space로 창 캡처

### 4단계: 이미지 크기 조정 (필요시)
```bash
# 정확한 크기로 조정
sips -z 2778 1284 screenshot.png --out resized.png
```

---

## 방법 2: 시뮬레이터에서 직접 캡처

### 1단계: 스크립트 실행
```bash
cd /path/to/hogumeter
./AppStoreScreenshots/capture_screenshots.sh
```

### 2단계: 앱 빌드 및 실행
```bash
# 시뮬레이터에 앱 빌드 및 설치
xcodebuild -scheme HoguMeter \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' \
    -derivedDataPath build \
    build

# 앱 실행
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/HoguMeter.app
xcrun simctl launch booted com.devbada.HoguMeter
```

### 3단계: 각 화면으로 이동 후 캡처
```bash
# 현재 화면 캡처
xcrun simctl io booted screenshot AppStoreScreenshots/iPhone/01_main.png
```

---

## 방법 3: fastlane snapshot (고급)

자동화된 스크린샷 생성을 위해 fastlane을 사용할 수 있습니다.

### 설치
```bash
gem install fastlane
fastlane init
```

### Snapfile 설정
```ruby
# fastlane/Snapfile
devices([
  "iPhone 15 Pro Max"
])

languages([
  "ko-KR"
])

scheme("HoguMeter")
output_directory("./AppStoreScreenshots")
clear_previous_screenshots(true)
```

---

## 프로모션 텍스트

각 스크린샷에 포함된 한글 프로모션 문구:

| 화면 | 프로모션 텍스트 |
|------|----------------|
| 메인 (대기) | 실시간 택시 요금 미터기 |
| 주행 중 | 정확한 거리 기반 요금 계산 |
| 영수증 | 상세한 영수증으로 요금 확인 |
| 설정 | 전국 7대 도시 요금 지원 |
| 지역별 요금 | 서울, 부산, 대구, 인천, 광주, 대전, 경기 |
| 주행 기록 | 모든 주행 기록을 한눈에 |

---

## 출력 폴더 구조

```
AppStoreScreenshots/
├── README.md              # 이 파일
├── capture_screenshots.sh # 캡처 스크립트
└── iPhone/
    ├── 01_main_idle.png
    ├── 02_main_running.png
    ├── 03_receipt.png
    ├── 04_settings.png
    ├── 05_region_fares.png
    └── 06_history.png
```

---

## 체크리스트

스크린샷 제출 전 확인사항:

- [ ] 모든 이미지가 정확히 1284 x 2778 픽셀인가?
- [ ] PNG/JPEG 형식인가? (투명도 없음)
- [ ] 텍스트가 잘려있지 않은가?
- [ ] 앱 UI가 명확하게 보이는가?
- [ ] 모든 스크린샷이 일관된 스타일인가?
- [ ] 한글 텍스트가 올바르게 표시되는가?

---

## App Store Connect 업로드

1. [App Store Connect](https://appstoreconnect.apple.com) 로그인
2. 앱 선택 → App 정보 → 스크린샷
3. "6.7인치 디스플레이" 섹션에 업로드
4. 순서대로 드래그하여 배열

---

## 참고

- App Store 스크린샷 가이드라인: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- 이미지에 투명도가 있으면 App Store에서 거부됩니다
- 스크린샷 순서가 앱 소개에서 중요합니다 (첫 번째가 가장 잘 보임)
