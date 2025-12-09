# Task 7.1: 다크모드 지원

> **Epic**: Epic 7 - 설정/기타
> **Status**: 🟢 Done
> **Priority**: P2
> **PRD**: FR-7.1

---

## 📋 개요

앱 전체에 다크모드를 지원합니다.

## ✅ Acceptance Criteria

- [x] 시스템 설정 자동 감지
- [x] 앱 내 수동 전환 옵션
- [x] 모든 화면에서 다크모드 적용
- [x] 말 애니메이션 배경도 변경

---

## 📝 구현 노트

### 주요 구현 내용

1. **SettingsRepository 확장** (HoguMeter/Data/Repositories/SettingsRepository.swift:22-100)
   - ColorSchemePreference enum 추가 (system, light, dark)
   - colorSchemePreference 프로퍼티 추가
   - UserDefaults 기반 영속성

2. **ContentView 다크모드 적용** (HoguMeter/Presentation/Views/ContentView.swift:10-57)
   - preferredColorScheme modifier 사용
   - SettingsRepository에서 설정 읽기
   - NotificationCenter로 실시간 변경 감지
   - 시스템/라이트/다크 3가지 모드 지원

3. **Notification Extension** (HoguMeter/Core/Extensions/Notification+Extensions.swift:1-12)
   - colorSchemeChanged notification 정의
   - 설정 변경 시 앱 전체 업데이트

4. **자동 다크모드**
   - SwiftUI 기본 다크모드 지원 활용
   - 모든 시스템 컬러 자동 적응
   - BackgroundScrollView의 낮/밤 색상 변경 포함

### 기술 스택
- SwiftUI preferredColorScheme
- NotificationCenter
- UserDefaults (설정 저장)
- Environment(@colorScheme)

---

**Created**: 2025-01-15
**Completed**: 2025-12-09
