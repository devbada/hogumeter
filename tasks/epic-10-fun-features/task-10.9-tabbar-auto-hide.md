# TASK-10.9: 미터 실행 중 탭바 자동 숨김

## Task 정보

| 항목 | 내용 |
|------|------|
| Task ID | TASK-10.9 |
| Epic | EPIC-10 (재미 요소) |
| 난이도 | ⭐ |
| 상태 | ✅ 구현됨 |
| 생성일 | 2025-12-17 |

---

## 목표

미터기 실행 중에 탭바("미터기", "설정", "기록")를 숨겨서 화면 공간을 확보하고, N빵 계산기 등 추가 UI가 표시될 공간 마련.

---

## 구현 스펙

### 동작 조건

| 상태 | 탭바 표시 |
|------|----------|
| idle (대기) | ✅ 표시 |
| running (실행 중) | ❌ 숨김 |
| stopped (정지) | ✅ 표시 |

### 애니메이션

- 전환 애니메이션: `easeInOut(duration: 0.3)`
- 자연스러운 슬라이드 효과

---

## 구현 내용

### ContentView 수정

```swift
// ContentViewInner - MeterViewModel을 @State로 안전하게 관리
private struct ContentViewInner: View {
    @State private var meterViewModel: MeterViewModel?

    private var isMeterRunning: Bool {
        meterViewModel?.state == .running
    }

    var body: some View {
        TabView { ... }
            .toolbar(isMeterRunning ? .hidden : .visible, for: .tabBar)
            .animation(.easeInOut(duration: 0.3), value: isMeterRunning)
    }
}
```

### 주요 변경점

1. **ContentViewInner 분리**: MeterViewModel을 @State로 안전하게 관리하기 위해 내부 뷰 분리
2. **onAppear 초기화**: ViewModel을 onAppear에서 한 번만 생성하여 중복 생성 방지
3. **toolbar modifier**: iOS 16+ `.toolbar(_:for:)` 사용하여 탭바 가시성 제어

---

## 수정 파일

```
HoguMeter/Presentation/Views/ContentView.swift
```

---

## 수락 기준

- [x] 미터 시작 시 탭바 자동 숨김
- [x] 미터 정지/리셋 시 탭바 다시 표시
- [x] 부드러운 전환 애니메이션
- [x] 크래시 없이 정상 작동

---

## 관련 버그

- **BUG-001**: 리셋 버튼 크래시 (ContentView ViewModel 중복 생성 문제) - 함께 수정됨
