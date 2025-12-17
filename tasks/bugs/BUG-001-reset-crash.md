# BUG-001: 리셋 버튼 누르면 앱 크래시

## 버그 정보

| 항목 | 내용 |
|------|------|
| Bug ID | BUG-001 |
| 심각도 | Critical |
| 상태 | ✅ 수정됨 |
| 발견일 | 2025-12-17 |
| 수정일 | 2025-12-17 |

---

## 재현 단계

1. 앱 실행
2. 미터 시작 버튼 클릭
3. 정지 버튼 클릭
4. 리셋 버튼 클릭
5. **앱 크래시 발생**

---

## 원인 분석

### 문제 코드 (ContentView.swift)

```swift
// 문제가 있던 코드
private func getOrCreateMeterViewModel() -> MeterViewModel {
    if let viewModel = meterViewModel {
        return viewModel
    }
    let viewModel = MeterViewModel(...)
    // ❌ Task로 비동기 설정 - 타이밍 이슈 발생
    Task { @MainActor in
        meterViewModel = viewModel
    }
    return viewModel
}
```

### 근본 원인

1. **ViewModel 중복 생성**: `getOrCreateMeterViewModel()`이 body 렌더링 시마다 호출됨
2. **비동기 설정 타이밍 문제**: Task로 `meterViewModel`을 설정하는 사이에 다음 렌더링이 발생
3. **다른 ViewModel 인스턴스**: MainMeterView와 ContentView가 서로 다른 ViewModel 인스턴스를 참조
4. **상태 불일치**: 리셋 시 한쪽 ViewModel만 업데이트되어 크래시 발생

---

## 수정 내용

### 해결 방법

ContentView를 두 개의 뷰로 분리하여 ViewModel 초기화를 안전하게 처리:

```swift
// 수정된 코드
private struct ContentViewInner: View {
    @State private var meterViewModel: MeterViewModel?

    var body: some View {
        Group {
            if let viewModel = meterViewModel {
                TabView { ... }
            } else {
                ProgressView("로딩 중...")
            }
        }
        .onAppear {
            // ✅ onAppear에서 한 번만 생성
            if meterViewModel == nil {
                meterViewModel = MeterViewModel(...)
            }
        }
    }
}
```

### 주요 변경점

1. `ContentViewInner` 구조체 분리
2. `@State private var meterViewModel: MeterViewModel?` 로 선언
3. `onAppear`에서 nil 체크 후 한 번만 생성
4. Optional binding으로 안전하게 TabView에 전달

---

## 수정 파일

```
HoguMeter/Presentation/Views/ContentView.swift
```

---

## 테스트 확인

- [x] 미터 시작 → 정지 → 리셋 반복해도 크래시 없음
- [x] 탭 전환 후 돌아와도 정상 동작
- [x] 앱 백그라운드 전환 후에도 정상 동작
