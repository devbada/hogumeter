# 앱 아이콘 생성 가이드

## 📱 개요

이 디렉토리에는 호구미터 앱 아이콘을 생성하기 위한 스크립트들이 있습니다.

## 🔧 필수 요구사항

```bash
# Pillow 라이브러리 설치
pip3 install Pillow
```

## 🎨 방법 1: 플레이스홀더 아이콘 생성 (빠른 테스트용)

간단한 그라데이션 + 이모지로 임시 아이콘을 만듭니다.

```bash
# 대화형 모드로 실행
python3 scripts/create_placeholder_icon.py

# 또는 직접 생성
python3 -c "
from scripts.create_placeholder_icon import create_simple_icon
create_simple_icon('app_icon_source.png', '🐴')
"
```

생성된 `app_icon_source.png` (1024x1024) 파일을 확인하세요.

## 📐 방법 2: AI 도구로 고품질 아이콘 생성 (권장)

### AI 이미지 생성 도구 사용

**추천 도구:**
- DALL-E 3 (ChatGPT Plus)
- Midjourney
- Stable Diffusion
- Adobe Firefly

**프롬프트 예시:**

```
영어 프롬프트:
"A cute cartoon horse character with excited expression, holding a taxi meter
showing increasing numbers, gradient orange to red background, app icon style,
flat design, simple and clean, vibrant colors, no text, 1024x1024px,
professional app icon design"

한글 프롬프트 (번역):
"흥분한 표정의 귀여운 만화 말 캐릭터가 숫자가 올라가는 택시 미터기를 들고 있는 모습,
오렌지에서 빨강으로 그라데이션 배경, 앱 아이콘 스타일, 플랫 디자인, 단순하고 깔끔함,
생동감 있는 색상, 텍스트 없음, 1024x1024px, 전문적인 앱 아이콘 디자인"
```

**다른 컨셉 프롬프트:**

```
컨셉 1 - 말 얼굴 클로즈업:
"Cute horse face close-up with surprised expression, eyes with spark effect,
circular orange background, app icon style, simple and memorable, 1024x1024px"

컨셉 2 - 택시 + 말:
"Yellow taxi cab with horse silhouette inside, city skyline background,
minimalist app icon design, orange and yellow colors, 1024x1024px"

컨셉 3 - 미터기 중심:
"Taxi meter showing numbers with small horse icon, orange gradient background,
modern flat design, app icon style, clean and simple, 1024x1024px"
```

### 온라인 디자인 도구

**무료 도구:**
- Canva (무료 플랜)
- Figma (무료)
- GIMP (무료, 오픈소스)

**유료 도구:**
- Adobe Illustrator
- Sketch
- Affinity Designer

## 🔄 방법 3: 아이콘 리사이징

1024x1024 원본 이미지를 준비한 후:

```bash
# 기본 경로 사용 (app_icon_source.png)
python3 scripts/resize_app_icon.py

# 또는 사용자 정의 경로
python3 scripts/resize_app_icon.py /path/to/your/icon_1024.png
```

이 스크립트는 자동으로:
- 모든 필요한 iOS 아이콘 크기 생성 (40px ~ 1024px)
- `HoguMeter/Resources/Assets.xcassets/AppIcon.appiconset/`에 저장
- `Contents.json` 업데이트

## 📋 완전한 워크플로우

### 옵션 A: 빠른 테스트 (플레이스홀더)

```bash
# 1. 플레이스홀더 아이콘 생성
python3 scripts/create_placeholder_icon.py

# 2. 모든 크기로 리사이징
python3 scripts/resize_app_icon.py

# 3. Xcode에서 빌드 및 확인
```

### 옵션 B: 고품질 아이콘 (권장)

```bash
# 1. AI 도구로 1024x1024 아이콘 생성
# 2. app_icon_source.png로 저장

# 3. 리사이징
python3 scripts/resize_app_icon.py app_icon_source.png

# 4. Xcode에서 빌드 및 확인
```

## ✅ 확인사항

### 생성된 파일 확인

```bash
ls -l HoguMeter/Resources/Assets.xcassets/AppIcon.appiconset/
```

다음 파일들이 있어야 합니다:
- `icon_20x20@2x.png` (40x40)
- `icon_20x20@3x.png` (60x60)
- `icon_29x29@2x.png` (58x58)
- `icon_29x29@3x.png` (87x87)
- `icon_40x40@2x.png` (80x80)
- `icon_40x40@3x.png` (120x120)
- `icon_60x60@2x.png` (120x120)
- `icon_60x60@3x.png` (180x180)
- `icon_1024x1024.png` (1024x1024)
- `Contents.json`

### Xcode에서 확인

1. Xcode 열기
2. `HoguMeter/Resources/Assets.xcassets/AppIcon` 클릭
3. 모든 슬롯이 채워졌는지 확인
4. 빌드 및 시뮬레이터 실행
5. 홈 스크린에서 아이콘 확인

## 🎨 디자인 가이드라인

### 필수 사항

- ✅ 크기: 1024x1024px (원본)
- ✅ 포맷: PNG
- ✅ 투명도: 없음 (불투명 배경)
- ✅ 색상 모드: RGB
- ✅ 텍스트: 최소화 또는 없음

### 권장 사항

- ✨ 단순하고 명확한 디자인
- ✨ 강한 색상 대비
- ✨ 작은 크기에서도 인식 가능
- ✨ 앱의 정체성 반영
- ✨ iOS 디자인 가이드라인 준수

### 피해야 할 것

- ❌ 너무 복잡한 디테일
- ❌ 읽기 어려운 작은 텍스트
- ❌ 투명 배경
- ❌ 손으로 그린 듯한 라운드 코너 (시스템이 자동 처리)

## 🔗 참고 자료

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App Icon Generator](https://www.appicon.co/) - 온라인 리사이징 도구
- [Icon Slate](https://www.kodlian.com/apps/icon-slate) - macOS 아이콘 생성 앱

## 🐛 문제 해결

### "ModuleNotFoundError: No module named 'PIL'"

```bash
pip3 install Pillow
```

### 아이콘이 흐릿하게 보임

- 고해상도 원본 (1024x1024) 사용
- LANCZOS 리샘플링 사용 (스크립트에 포함됨)

### "AppIcon has unassigned children" 경고

- 모든 필수 크기가 생성되었는지 확인
- Contents.json이 올바른지 확인

### 투명 배경 경고

- 원본 이미지를 불투명 배경으로 변경
- 스크립트가 자동으로 흰색 배경 추가

## 📞 도움말

문제가 있거나 질문이 있으면 task-0.3-app-icon.md를 참고하세요.
