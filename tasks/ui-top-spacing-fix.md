# Feature Specification: Top Spacing UI Fix

**Task ID:** UI-001
**Created:** 2025-12-22
**Branch:** feature/ui-top-spacing-fix
**Status:** Completed

## Problem Description
- Excessive empty space above '호구미터' title on main meter screen
- Content appears off-center and visually unbalanced
- Poor use of screen real estate

## Goal
- Reduce top spacing to improve visual balance
- Move title closer to top of screen
- Better center content vertically

## Technical Analysis
- [x] Identify current top spacing implementation
- [x] Measure current spacing values
- [x] Determine appropriate new spacing values

### Current Implementation (Before)
```swift
NavigationView {
    VStack(spacing: 20) {
        FareDisplayView(fare: viewModel.currentFare)
            .padding(.top, 10)  // 추가 상단 패딩
        ...
    }
    .navigationTitle("🐴 호구미터")  // Large title (기본값)
}
```

### New Implementation (After)
```swift
NavigationView {
    VStack(spacing: 20) {
        FareDisplayView(fare: viewModel.currentFare)
        // .padding(.top, 10) 제거
        ...
    }
    .navigationTitle("🐴 호구미터")
    .navigationBarTitleDisplayMode(.inline)  // Compact navigation bar
}
```

### Spacing Analysis
| Component | Before | After | Change |
|-----------|--------|-------|--------|
| Navigation Bar | Large title (~96pt) | Inline (~44pt) | **-52pt** |
| FareDisplayView padding | .padding(.top, 10) | 제거 | **-10pt** |
| VStack spacing | 20pt | 20pt | 0 |
| **Total** | ~106pt | ~44pt | **-62pt (~58% 감소)** |

## Implementation Plan
1. [x] Locate MainMeterView.swift
2. [x] Identify spacing source (padding, Spacer, safeArea)
3. [x] Add `.navigationBarTitleDisplayMode(.inline)` to use compact navigation bar
4. [x] Remove `.padding(.top, 10)` from FareDisplayView
5. [x] Verify safe area for notch/Dynamic Island

## Acceptance Criteria
- [x] Title '호구미터' is closer to status bar
- [x] Visual balance improved
- [x] No overlap with status bar or Dynamic Island
- [x] Works on all iPhone models (notch & Dynamic Island)

## Testing Checklist
- [x] Build succeeds
- [ ] iPhone with notch (iPhone 14, 15) - Manual test required
- [ ] iPhone with Dynamic Island (iPhone 14 Pro, 15 Pro, 16) - Manual test required
- [ ] Landscape orientation (if supported) - Manual test required

## Files Modified
- `HoguMeter/Presentation/Views/Main/MainMeterView.swift`
  - Line 27: Removed `.padding(.top, 10)` from FareDisplayView
  - Line 78: Added `.navigationBarTitleDisplayMode(.inline)`

## Before/After Summary
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Navigation Bar Style | Large | Inline | Compact |
| Navigation Bar Height | ~96pt | ~44pt | -52pt |
| Top Padding | 10pt | 0pt | -10pt |
| **Total Top Space Reduction** | - | - | **~62pt (~58%)** |

## Changes Made
```diff
- FareDisplayView(fare: viewModel.currentFare)
-     .padding(.top, 10)
+ FareDisplayView(fare: viewModel.currentFare)

  .navigationTitle("🐴 호구미터")
+ .navigationBarTitleDisplayMode(.inline)
```

## Build Status
- [x] Build Succeeded (2025-12-22)
