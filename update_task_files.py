#!/usr/bin/env python3
import os
import glob

# Find all task markdown files (excluding EPIC.md)
task_files = []
for pattern in ['tasks/epic-*/task-*.md']:
    task_files.extend(glob.glob(pattern))

task_files.sort()

print(f"Found {len(task_files)} task files to update:\n")

development_guide_reference = """
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
"""

updated_count = 0
skipped_count = 0

for file_path in task_files:
    print(f"Processing: {file_path}")

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Check if already has the reference
        if 'DEVELOPMENT_GUIDE-FOR-AI.md' in content:
            print(f"  ⏭️  Already updated, skipping...")
            skipped_count += 1
            continue

        # Check if has "참고 자료" section
        if '## 📎 참고 자료' in content:
            # Insert before the existing 참고 자료 section
            parts = content.split('## 📎 참고 자료')
            updated_content = parts[0] + development_guide_reference + '\n## 📎 참고 자료' + parts[1]
        else:
            # Append at the end
            # Remove trailing whitespace first
            content = content.rstrip()
            updated_content = content + '\n' + development_guide_reference + '\n'

        # Write updated content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)

        print(f"  ✅ Updated successfully")
        updated_count += 1

    except Exception as e:
        print(f"  ❌ Error: {e}")

print(f"\n" + "="*50)
print(f"Summary:")
print(f"  Updated: {updated_count}")
print(f"  Skipped: {skipped_count}")
print(f"  Total:   {len(task_files)}")
print("="*50)
