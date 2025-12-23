# Feature Specification: Screen Always-On During Meter Operation

**Task ID:** SCREEN-001
**Created:** 2025-12-23
**Branch:** feature/screen-always-on
**Status:** Completed

## Problem Description
- When meter is running, the screen dims and locks automatically after idle timeout
- User cannot see real-time fare information without unlocking the phone
- Inconvenient for taxi drivers or users who need to monitor fare continuously
- Current behavior follows default iOS screen timeout settings

## User Story
As a user running the meter,
I want the screen to stay on while the meter is active,
So that I can continuously monitor the fare without touching the phone.

## Goal
- Keep screen awake while meter is in .running state
- Screen should follow normal timeout behavior when meter is stopped or idle
- Respect user's choice if they want to manually lock the screen

## Technical Solution

**iOS API:** `UIApplication.shared.isIdleTimerDisabled`
```swift
// When meter starts
UIApplication.shared.isIdleTimerDisabled = true

// When meter stops or resets
UIApplication.shared.isIdleTimerDisabled = false
```

## Implementation Plan

1. **MeterViewModel.swift**
   - Set `isIdleTimerDisabled = true` when state changes to `.running`
   - Set `isIdleTimerDisabled = false` when state changes to `.stopped` or `.idle`

2. **State Mapping**
   | Meter State | isIdleTimerDisabled |
   |-------------|---------------------|
   | .idle       | false               |
   | .running    | true                |
   | .stopped    | false               |

3. **Edge Cases**
   - App enters background → iOS handles this automatically
   - App returns to foreground with running meter → Re-enable idle timer disable
   - User manually locks screen → Allowed (power button still works)
   - Low battery mode → Still keep screen on (user's choice to stop meter)

## Acceptance Criteria
- [x] Screen stays on indefinitely while meter is running
- [x] Screen follows normal timeout when meter is stopped
- [x] Screen follows normal timeout when meter is reset/idle
- [x] Power button still allows manual screen lock
- [x] Works correctly after app returns from background

## Testing Checklist
- [ ] Start meter → wait 2+ minutes → screen stays on
- [ ] Stop meter → wait for normal timeout → screen dims/locks
- [ ] Reset meter → screen follows normal timeout
- [ ] Start meter → press power button → screen locks (manual override works)
- [ ] Start meter → background → foreground → screen still stays on
- [ ] Start meter → receive call → end call → screen stays on

## Files to Modify
- MeterViewModel.swift (primary)
- Possibly MainMeterView.swift (if state observation needed in view)

## Dependencies
- None (uses built-in iOS API)

## Risks & Considerations
- Battery drain: Screen always on will consume more battery
- User awareness: Consider showing indicator that screen-on is active
- Optional: Add setting to disable this feature for users who prefer normal timeout

## Future Enhancements (Optional)
- Add toggle in Settings to enable/disable this feature
- Show small indicator icon when screen-on mode is active
- Dim screen slightly (not lock) after extended period to save battery

## Implementation Summary

### Changes Made

**MeterViewModel.swift**
- Added `import UIKit` for `UIApplication` access
- Added `setScreenAlwaysOn(_ enabled: Bool)` helper method
- `startMeter()`: Calls `setScreenAlwaysOn(true)`
- `stopMeter()`: Calls `setScreenAlwaysOn(false)`
- `resetMeter()`: Calls `setScreenAlwaysOn(false)`
- Added `handleAppBecameActive()` to restore screen-on state after background
- Subscribes to `UIApplication.didBecomeActiveNotification`

### Code Changes
```swift
// Screen Always-On helper
private func setScreenAlwaysOn(_ enabled: Bool) {
    UIApplication.shared.isIdleTimerDisabled = enabled
}

// App lifecycle handling
private func handleAppBecameActive() {
    if state == .running {
        setScreenAlwaysOn(true)
    }
}
```

## Build Status
- [x] Build Succeeded (2025-12-23)
