#!/usr/bin/env python3
"""
앱 아이콘 리사이징 스크립트
1024x1024 원본 이미지를 모든 필요한 크기로 자동 리사이징합니다.
"""

from PIL import Image
import os
import sys

# iOS 앱 아이콘 필수 크기
ICON_SIZES = [
    ("icon_20x20@2x.png", 40),      # iPhone Notification
    ("icon_20x20@3x.png", 60),      # iPhone Notification
    ("icon_29x29@2x.png", 58),      # iPhone Settings
    ("icon_29x29@3x.png", 87),      # iPhone Settings
    ("icon_40x40@2x.png", 80),      # iPhone Spotlight
    ("icon_40x40@3x.png", 120),     # iPhone Spotlight
    ("icon_60x60@2x.png", 120),     # iPhone App
    ("icon_60x60@3x.png", 180),     # iPhone App
    ("icon_1024x1024.png", 1024),   # App Store
]

def resize_icon(source_path, output_dir):
    """
    1024x1024 원본 이미지를 여러 크기로 리사이징

    Args:
        source_path: 원본 이미지 경로 (1024x1024 PNG)
        output_dir: 출력 디렉토리 (AppIcon.appiconset)
    """
    if not os.path.exists(source_path):
        print(f"❌ 오류: 원본 파일을 찾을 수 없습니다: {source_path}")
        print(f"\n1024x1024 PNG 파일을 준비하고 다시 실행하세요.")
        sys.exit(1)

    # 원본 이미지 열기
    try:
        img = Image.open(source_path)
        print(f"✅ 원본 이미지 로드: {source_path}")
        print(f"   크기: {img.size}, 모드: {img.mode}")

        # 1024x1024 확인
        if img.size != (1024, 1024):
            print(f"⚠️  경고: 원본 크기가 1024x1024가 아닙니다. 자동으로 리사이징합니다.")
            img = img.resize((1024, 1024), Image.Resampling.LANCZOS)

        # 투명도 확인
        if img.mode == 'RGBA':
            print(f"⚠️  경고: 이미지에 투명도가 있습니다. 흰색 배경으로 변환합니다.")
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[3] if len(img.split()) == 4 else None)
            img = background

    except Exception as e:
        print(f"❌ 오류: 이미지를 열 수 없습니다: {e}")
        sys.exit(1)

    # 출력 디렉토리 생성
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"📁 출력 디렉토리 생성: {output_dir}")

    print(f"\n🔄 아이콘 리사이징 시작...\n")

    # 모든 크기로 리사이징
    for filename, size in ICON_SIZES:
        try:
            resized = img.resize((size, size), Image.Resampling.LANCZOS)
            output_path = os.path.join(output_dir, filename)
            resized.save(output_path, 'PNG')
            print(f"✅ {filename} ({size}x{size})")
        except Exception as e:
            print(f"❌ {filename} 생성 실패: {e}")

    print(f"\n🎉 모든 아이콘 생성 완료!")
    print(f"📂 출력 위치: {output_dir}")

def update_contents_json(output_dir):
    """
    Contents.json 파일에 filename 추가
    """
    contents_path = os.path.join(output_dir, "Contents.json")

    contents = {
        "images": [
            {"filename": "icon_20x20@2x.png", "idiom": "iphone", "scale": "2x", "size": "20x20"},
            {"filename": "icon_20x20@3x.png", "idiom": "iphone", "scale": "3x", "size": "20x20"},
            {"filename": "icon_29x29@2x.png", "idiom": "iphone", "scale": "2x", "size": "29x29"},
            {"filename": "icon_29x29@3x.png", "idiom": "iphone", "scale": "3x", "size": "29x29"},
            {"filename": "icon_40x40@2x.png", "idiom": "iphone", "scale": "2x", "size": "40x40"},
            {"filename": "icon_40x40@3x.png", "idiom": "iphone", "scale": "3x", "size": "40x40"},
            {"filename": "icon_60x60@2x.png", "idiom": "iphone", "scale": "2x", "size": "60x60"},
            {"filename": "icon_60x60@3x.png", "idiom": "iphone", "scale": "3x", "size": "60x60"},
            {"filename": "icon_1024x1024.png", "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"}
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    import json
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"\n✅ Contents.json 업데이트 완료")

if __name__ == "__main__":
    # 기본 경로 설정
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    default_source = os.path.join(project_root, "app_icon_source.png")
    default_output = os.path.join(project_root, "HoguMeter/Resources/Assets.xcassets/AppIcon.appiconset")

    # 커맨드 라인 인자 처리
    if len(sys.argv) > 1:
        source_path = sys.argv[1]
    else:
        source_path = default_source

    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    else:
        output_dir = default_output

    print("=" * 60)
    print("📱 iOS 앱 아이콘 리사이징 스크립트")
    print("=" * 60)
    print(f"원본: {source_path}")
    print(f"출력: {output_dir}")
    print("=" * 60 + "\n")

    # 리사이징 실행
    resize_icon(source_path, output_dir)

    # Contents.json 업데이트
    update_contents_json(output_dir)

    print("\n" + "=" * 60)
    print("✅ 작업 완료!")
    print("=" * 60)
    print("\n다음 단계:")
    print("1. Xcode를 열고 Assets.xcassets/AppIcon을 확인하세요")
    print("2. 빌드하고 시뮬레이터에서 아이콘을 확인하세요")
    print("=" * 60)
