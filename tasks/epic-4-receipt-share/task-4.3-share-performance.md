# Task 4.3: 영수증 캡쳐 성능 개선

> **Epic**: Epic 4 - 영수증/공유
> **Status**: 🟢 Done
> **Priority**: P1
> **PRD**: FR-4.3

---

## 📋 개요

영수증 이미지 생성 성능을 개선하고, 공유 기능을 사진첩 캡쳐 기능으로 변경합니다.

## 🐛 해결한 문제점

### 1. 느린 이미지 생성 (해결)
- UIHostingController를 윈도우에 추가/제거하는 과정이 느림
- 공유 버튼 클릭 후 1-2초 대기 필요

### 2. 시도한 방법들
- [x] `intrinsicContentSize` 사용 → 빈 이미지 생성 (실패)
- [x] `drawHierarchy` 사용 → 빈 이미지 생성 (실패)
- [x] 윈도우에 추가 후 `layer.render` → 작동하지만 느림
- [x] iOS 16+ `ImageRenderer` → 빈 이미지 생성 (실패)
- [x] 비동기 처리 + 딜레이 → 작동하지만 느림
- [x] 이미지 미리 생성 (onAppear) → 부분적 개선
- [x] **Core Graphics 직접 그리기 → 성공! (최종 채택)**

## ✅ Acceptance Criteria

- [x] 캡쳐 버튼 클릭 시 즉시 이미지 생성 (<0.1초)
- [x] 영수증 이미지 품질 유지 (Retina 지원, scale=2.0)
- [x] 메모리 누수 없음
- [x] iOS 17+ 호환성 유지
- [x] 사진첩에 바로 저장

## ✅ 구현 완료 (2025-12-12)

### 최종 해결 방법: Core Graphics 직접 그리기

SwiftUI 렌더링 파이프라인을 완전히 우회하고, Core Graphics로 직접 이미지를 그립니다.

```swift
// ReceiptImageGenerator (ReceiptView.swift 내부 private enum)
private enum ReceiptImageGenerator {
    static func generate(from trip: Trip) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 320, height: 520),
            format: format
        )

        return renderer.image { context in
            // Core Graphics로 직접 그리기
            // NSString.draw(at:withAttributes:) 사용
            // CGContext로 선, 도형 그리기
        }
    }
}
```

### 공유 → 캡쳐로 변경

| 항목 | 이전 | 이후 |
|-----|------|------|
| 버튼 아이콘 | `square.and.arrow.up` | `camera` |
| 동작 | ShareSheet 표시 | 사진첩에 바로 저장 |
| 피드백 | 없음 | Alert로 저장 완료 알림 |
| 필요 권한 | 없음 | `NSPhotoLibraryAddUsageDescription` |

### 성능 비교

| 방식 | 이미지 생성 시간 | 비고 |
|-----|----------------|------|
| UIHostingController + layer.render | ~1-2초 | 느림, 앱 멈춤 현상 |
| ImageRenderer (iOS 16+) | N/A | 빈 이미지 생성 (실패) |
| **Core Graphics 직접 그리기** | **<0.1초** | **최종 채택** |

## 📁 변경된 파일

- `HoguMeter/Presentation/Views/Receipt/ReceiptView.swift`
  - `ReceiptImageGenerator` enum 추가 (Core Graphics 기반)
  - `captureReceipt()` 메서드 추가 (사진첩 저장)
  - ShareSheet 관련 코드 제거
- `HoguMeter/Info.plist`
  - `NSPhotoLibraryAddUsageDescription` 추가
- `HoguMeter/Presentation/Views/Receipt/ShareSheet.swift` - **삭제**

## 📊 결과

| 항목 | 이전 | 이후 |
|-----|------|------|
| 이미지 생성 시간 | ~1-2초 | <0.1초 |
| 이미지 크기 | 350x600 @2x | 320x520 @2x |
| UX | 공유 시트 → 사진 선택 | 버튼 한번으로 저장 완료 |

---

**Created**: 2025-12-12
**Completed**: 2025-12-12

---

## 📘 개발 가이드

**중요:** 이 Task를 구현하기 전에 반드시 아래 문서를 먼저 읽고 가이드를 준수해야 합니다.

- [DEVELOPMENT_GUIDE-FOR-AI.md](../../docs/DEVELOPMENT_GUIDE-FOR-AI.md)
