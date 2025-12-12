# Task 4.3: 영수증 공유 성능 개선

> **Epic**: Epic 4 - 영수증/공유
> **Status**: 🟢 Done
> **Priority**: P1
> **PRD**: FR-4.3

---

## 📋 개요

영수증 공유 기능의 성능을 개선합니다. 현재 SwiftUI View를 UIImage로 변환하는 과정이 느려서 사용자 경험이 좋지 않습니다.

## 🐛 현재 문제점

### 1. 느린 이미지 생성
- UIHostingController를 윈도우에 추가/제거하는 과정이 느림
- 공유 버튼 클릭 후 1-2초 대기 필요

### 2. 시도한 방법들
- [x] `intrinsicContentSize` 사용 → 빈 이미지 생성 (실패)
- [x] `drawHierarchy` 사용 → 빈 이미지 생성 (실패)
- [x] 윈도우에 추가 후 `layer.render` → 작동하지만 느림
- [x] iOS 16+ `ImageRenderer` → 빈 이미지 생성 (실패)
- [x] 비동기 처리 + 딜레이 → 작동하지만 느림
- [x] 이미지 미리 생성 (onAppear) → 부분적 개선

## ✅ Acceptance Criteria

- [ ] 공유 버튼 클릭 시 0.5초 이내에 공유 시트 표시
- [ ] 영수증 이미지 품질 유지 (Retina 지원)
- [ ] 메모리 누수 없음
- [ ] iOS 17+ 호환성 유지

## 📝 개선 방안

### 방안 1: 이미지 캐싱 최적화
```swift
// 영수증 화면 진입 시 백그라운드에서 미리 생성
// 공유 시점에는 캐싱된 이미지 사용
```

### 방안 2: 더 가벼운 뷰 구조
```swift
// 공유용 뷰를 별도로 최적화
// 불필요한 modifier 제거
// 단순한 레이아웃 사용
```

### 방안 3: Core Graphics 직접 사용
```swift
// UIKit/Core Graphics로 직접 이미지 생성
// SwiftUI 변환 과정 제거
// 가장 빠르지만 구현 복잡도 높음
```

### 방안 4: 렌더링 파이프라인 최적화
```swift
// CALayer.shouldRasterize 활용
// 렌더링 품질 조절 (scale 조정)
// 비동기 렌더링 개선
```

## 🔧 기술 조사 필요 항목

1. **ImageRenderer 실패 원인 분석**
   - iOS 17에서 ImageRenderer가 특정 뷰에서 실패하는 이유
   - workaround 존재 여부

2. **UIHostingController 성능 분석**
   - 윈도우 추가 없이 렌더링하는 방법
   - 레이아웃 pass 최소화 방법

3. **대안 라이브러리 조사**
   - SwiftUI-Introspect
   - SnapshotTesting (Point-Free)

## 📁 관련 파일

- `HoguMeter/Core/Extensions/View+Snapshot.swift`
- `HoguMeter/Presentation/Views/Receipt/ReceiptView.swift`
- `HoguMeter/Presentation/Views/Receipt/ShareSheet.swift`

## ✅ 구현 완료 (2025-12-12)

### 해결 방법: ImageRenderer + 최적화된 뷰

1. **ReceiptImageView 생성** (ReceiptView.swift 내부)
   - 공유 전용 경량화된 뷰
   - 단순한 레이아웃 (VStack + 기본 컴포넌트)
   - 320px 폭으로 축소

2. **ImageRenderer 사용**
   - iOS 16+ 네이티브 SwiftUI → UIImage 변환
   - UIHostingController 없이 직접 렌더링
   - scale = 2.0 (Retina)

3. **Fallback 유지**
   - ImageRenderer 실패 시 기존 View+Snapshot 사용

### 코드 변경

```swift
// ReceiptView.swift
@MainActor
private func generateReceiptImage() -> UIImage {
    let receiptImageView = ReceiptImageView(trip: trip)
    if let image = receiptImageView.toImage() {
        return image  // ImageRenderer (빠름)
    }
    return receiptImageView.snapshot(...)  // Fallback
}

// ReceiptImageView (private struct)
@MainActor
func toImage() -> UIImage? {
    let renderer = ImageRenderer(content: self)
    renderer.scale = 2.0
    return renderer.uiImage
}
```

## 📊 성능 목표

| 항목 | 현재 | 목표 |
|-----|------|------|
| 이미지 생성 시간 | ~1-2초 | < 0.5초 |
| 메모리 사용량 | 측정 필요 | 최소화 |
| 이미지 크기 | 350x600 @2x | 유지 |

---

**Created**: 2025-12-12
**Assigned**: -

---

## 📘 개발 가이드

**중요:** 이 Task를 구현하기 전에 반드시 아래 문서를 먼저 읽고 가이드를 준수해야 합니다.

- [DEVELOPMENT_GUIDE-FOR-AI.md](../../docs/DEVELOPMENT_GUIDE-FOR-AI.md)
