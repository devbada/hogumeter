#!/usr/bin/env python3
"""
플레이스홀더 앱 아이콘 생성 스크립트
간단한 그라데이션 배경 + 이모지/텍스트로 임시 아이콘을 만듭니다.
"""

from PIL import Image, ImageDraw, ImageFont
import os
import sys

def create_gradient_background(size=1024):
    """
    오렌지-레드 그라데이션 배경 생성
    """
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)

    # 그라데이션 색상 (오렌지 -> 빨강)
    start_color = (255, 149, 0)   # 오렌지
    end_color = (255, 59, 48)     # 레드

    for y in range(size):
        ratio = y / size
        r = int(start_color[0] + (end_color[0] - start_color[0]) * ratio)
        g = int(start_color[1] + (end_color[1] - start_color[1]) * ratio)
        b = int(start_color[2] + (end_color[2] - start_color[2]) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    return img

def add_text_to_icon(img, text, font_size=400):
    """
    아이콘에 텍스트/이모지 추가
    """
    draw = ImageDraw.Draw(img)

    try:
        # macOS 시스템 폰트 사용 (이모지 지원)
        font = ImageFont.truetype("/System/Library/Fonts/Apple Color Emoji.ttc", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", font_size)
        except:
            # 폰트를 찾을 수 없으면 기본 폰트 사용
            font = ImageFont.load_default()

    # 텍스트 크기 계산
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # 중앙 정렬
    x = (img.size[0] - text_width) // 2
    y = (img.size[1] - text_height) // 2 - 50  # 약간 위로

    # 그림자 효과
    shadow_offset = 5
    draw.text((x + shadow_offset, y + shadow_offset), text, font=font, fill=(0, 0, 0, 128))

    # 메인 텍스트 (흰색)
    draw.text((x, y), text, font=font, fill=(255, 255, 255))

    return img

def create_simple_icon(output_path, text="🐴"):
    """
    간단한 플레이스홀더 아이콘 생성

    Args:
        output_path: 출력 파일 경로
        text: 표시할 이모지 또는 텍스트
    """
    print(f"🎨 플레이스홀더 아이콘 생성 중...")
    print(f"   이모지/텍스트: {text}")

    # 그라데이션 배경 생성
    img = create_gradient_background(1024)
    print(f"   ✅ 그라데이션 배경 생성 (1024x1024)")

    # 텍스트 추가
    img = add_text_to_icon(img, text, font_size=500)
    print(f"   ✅ 텍스트 추가")

    # 저장
    img.save(output_path, 'PNG')
    print(f"   ✅ 저장 완료: {output_path}")

    return output_path

def create_icon_with_circle(output_path, emoji="🐴"):
    """
    원형 배경 + 이모지 아이콘 생성
    """
    print(f"🎨 원형 아이콘 생성 중...")

    size = 1024
    img = Image.new('RGB', (size, size), (255, 255, 255))
    draw = ImageDraw.Draw(img)

    # 원형 배경 (오렌지)
    circle_color = (255, 149, 0)
    margin = 100
    draw.ellipse([margin, margin, size-margin, size-margin], fill=circle_color)
    print(f"   ✅ 원형 배경 생성")

    # 이모지 추가
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Apple Color Emoji.ttc", 500)
        bbox = draw.textbbox((0, 0), emoji, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (size - text_width) // 2
        y = (size - text_height) // 2 - 50

        # 그림자
        draw.text((x + 5, y + 5), emoji, font=font, fill=(0, 0, 0, 50))
        # 메인
        draw.text((x, y), emoji, font=font, fill=(255, 255, 255))
        print(f"   ✅ 이모지 추가: {emoji}")
    except Exception as e:
        print(f"   ⚠️  이모지 추가 실패: {e}")

    img.save(output_path, 'PNG')
    print(f"   ✅ 저장 완료: {output_path}")

    return output_path

if __name__ == "__main__":
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    print("=" * 60)
    print("🎨 플레이스홀더 앱 아이콘 생성")
    print("=" * 60)
    print("\n옵션을 선택하세요:")
    print("1. 그라데이션 + 말 이모지 🐴")
    print("2. 원형 배경 + 말 이모지 🐴")
    print("3. 그라데이션 + 택시 이모지 🚖")
    print("4. 사용자 정의 이모지 입력")

    choice = input("\n선택 (1-4, 기본값=1): ").strip() or "1"

    output_path = os.path.join(project_root, "app_icon_source.png")

    if choice == "1":
        create_simple_icon(output_path, "🐴")
    elif choice == "2":
        create_icon_with_circle(output_path, "🐴")
    elif choice == "3":
        create_simple_icon(output_path, "🚖")
    elif choice == "4":
        emoji = input("이모지를 입력하세요: ").strip()
        create_simple_icon(output_path, emoji)
    else:
        print("잘못된 선택입니다. 기본값(1)을 사용합니다.")
        create_simple_icon(output_path, "🐴")

    print("\n" + "=" * 60)
    print("✅ 플레이스홀더 아이콘 생성 완료!")
    print("=" * 60)
    print(f"\n📁 출력 파일: {output_path}")
    print("\n다음 단계:")
    print("1. 생성된 이미지 확인")
    print("2. resize_app_icon.py를 실행하여 모든 크기로 리사이징")
    print(f"   python3 scripts/resize_app_icon.py {output_path}")
    print("=" * 60)
