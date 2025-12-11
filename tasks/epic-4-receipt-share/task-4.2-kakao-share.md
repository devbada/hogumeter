# Task 4.2: 카카오톡 공유

> **Epic**: Epic 4 - 영수증/공유
> **Status**: 🟢 Done
> **Priority**: P1
> **PRD**: FR-4.2

---

## 📋 개요

영수증을 카카오톡으로 공유할 수 있는 기능을 구현합니다.

## ✅ Acceptance Criteria

- [x] 영수증 화면을 이미지로 캡처
- [x] iOS 공유 시트 연동
- [x] 카카오톡 직접 공유 옵션 (iOS Share Sheet 통해 가능)
- [x] 이미지 저장 옵션 (iOS Share Sheet 통해 가능)

## 📝 구현 사항

### 1. 이미지 캡처
```swift
// UIGraphicsImageRenderer로 이미지 생성
```

### 2. 공유 시트
```swift
// UIActivityViewController 사용
```

---

## 📝 구현 노트

### 주요 구현 내용

1. **View+Snapshot Extension** (HoguMeter/Core/Extensions/View+Snapshot.swift:1-27)
   - SwiftUI View를 UIImage로 캡처하는 유틸리티
   - UIHostingController + UIGraphicsImageRenderer 사용
   - @MainActor 안전성 보장

2. **ShareSheet 컴포넌트** (HoguMeter/Presentation/Views/Receipt/ShareSheet.swift:1-25)
   - UIActivityViewController를 SwiftUI에서 사용 가능하게 래핑
   - UIViewControllerRepresentable 프로토콜 구현
   - 이미지 공유 지원

3. **ReceiptView 공유 기능 통합**
   - 공유 버튼 연결 (ToolbarItem)
   - shareReceipt() 메서드 구현
   - 영수증 내용만 캡처 (NavigationView 제외)
   - @State로 showShareSheet, receiptImage 관리
   - .sheet modifier로 ShareSheet 표시

4. **이미지 캡처 프로세스**
   - 영수증 내용을 375x800 고정 크기로 렌더링
   - 흰색 배경 적용
   - snapshot() extension 호출하여 UIImage 생성

5. **공유 옵션 (iOS 기본 제공)**
   - 카카오톡 공유
   - 메시지, 메일, AirDrop 공유
   - 사진 앱에 저장
   - 기타 연동된 앱 공유

### 기술 스택
- UIKit + SwiftUI 브리징
- UIHostingController
- UIGraphicsImageRenderer
- UIActivityViewController
- UIViewControllerRepresentable

---

**Created**: 2025-01-15
**Completed**: 2025-12-09

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

