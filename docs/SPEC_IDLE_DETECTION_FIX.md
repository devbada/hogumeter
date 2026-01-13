# SPEC: Idle Detection Feature Fix

## Overview
This document describes the investigation and fix for the idle detection feature that was not working correctly.

## Feature Background
The idle detection feature is designed to:
1. Detect when user stays in the same location for 10 minutes (no significant GPS movement > 50m)
2. Show an alert asking user to continue or stop the meter
3. Work both when app is active and in background (via local notification)

## Configuration Values
```swift
idleThreshold: 600 seconds (10 minutes)
movementThreshold: 50 meters
checkInterval: 30 seconds
minGPSAccuracyForMovement: 30 meters (GPS accuracy threshold)
maxRealisticSpeedKmh: 200 km/h (GPS jump detection threshold)
```

## Root Cause Analysis

### Issue 1: Alert Binding Pattern (Critical)
**Location**: `MainMeterView.swift:153-156`

**Problem**: The alert was using a manual `Binding(get:set:)` with an empty setter:
```swift
.alert("...", isPresented: Binding(
    get: { viewModel.showIdleAlert },
    set: { _ in }  // Empty setter!
)) {
```

**Why it fails**:
- SwiftUI's `@Observable` tracking may not properly detect changes through manual bindings
- The empty setter prevents SwiftUI from properly managing the alert dismissal state
- This can cause the alert to not appear even when `showIdleAlert` is `true`

**Fix**: Create a proper binding by exposing a binding accessor in the ViewModel:
```swift
// In MeterViewModel
var showIdleAlertBinding: Binding<Bool> {
    Binding(
        get: { self.showIdleAlert },
        set: { newValue in
            if !newValue {
                self.continueFromIdleAlert()
            }
        }
    )
}

// In MainMeterView
.alert("...", isPresented: viewModel.showIdleAlertBinding)
```

### Issue 2: Missing `.alerted` State Transition
**Location**: `IdleDetectionService.swift:376`

**Problem**: The `.alerted` state is defined in the enum but never used:
```swift
enum IdleDetectionState: Equatable {
    case monitoring
    case idle
    case alerted    // <- Never set!
    case dismissed
    case inactive
}
```

When idle is detected, state changes to `.idle`, but if the UI shows an alert, the state should transition to `.alerted` to indicate the user has been notified. Without this, the state machine doesn't properly track the alert lifecycle.

**Fix**: Add proper state transition when the UI receives the `.idle` state:
```swift
// In IdleDetectionService - Add new method
func markAlerted() {
    guard state == .idle else { return }
    stateSubject.send(.alerted)
}

// In MeterViewModel
private func handleIdleDetectionState(_ state: IdleDetectionState) {
    switch state {
    case .idle:
        showIdleAlert = true
        idleDetectionService.markAlerted()  // Transition to alerted
    // ...
    }
}
```

### Issue 3: GPS Jump/Drift Not Filtered (Indoor GPS Problem)
**Location**: `IdleDetectionService.swift:195-230` (original `updateLocation()`)

**Problem**: When user is stationary indoors:
- GPS signals often "jump" or "drift" due to poor accuracy
- Indoor GPS typically has horizontalAccuracy > 30-50 meters
- Position may jump 10-100+ meters between updates
- These false movements were resetting the idle timer incorrectly

**Original Code**:
```swift
// Only checked distance, not GPS accuracy or speed!
if distance >= 50.0 {
    lastMovementTime = Date()  // INCORRECTLY RESET IDLE TIMER
}
```

**Fix**: Added comprehensive movement validation in `shouldRecordMovement()`:
1. **GPS Accuracy Check**: Only count as movement if `horizontalAccuracy < 30m`
2. **GPS Jump Detection**: Calculate implied speed, ignore if > 200 km/h
3. **Both Locations Validated**: Check accuracy of both previous and current location

**New Code**:
```swift
private func shouldRecordMovement(from lastLocation: CLLocation, to newLocation: CLLocation, distance: Double) -> Bool {
    // 1. Distance threshold check
    guard distance >= 50.0 else { return false }

    // 2. GPS accuracy check (both locations)
    guard newLocation.horizontalAccuracy >= 0 &&
          newLocation.horizontalAccuracy < 30.0 &&
          lastLocation.horizontalAccuracy >= 0 &&
          lastLocation.horizontalAccuracy < 30.0 else {
        return false  // Poor GPS accuracy - ignore movement
    }

    // 3. GPS jump detection (unrealistic speed)
    let timeDelta = newLocation.timestamp.timeIntervalSince(lastLocation.timestamp)
    if timeDelta >= 0.1 {
        let speedKmh = (distance / timeDelta) * 3.6
        if speedKmh > 200 {
            return false  // GPS jump - impossible speed
        }
    }

    return true
}
```

### Issue 4: Timer Behavior in Background
**Location**: `IdleDetectionService.swift:346-355`

**Problem**: `Timer.scheduledTimer` runs on the main run loop, which doesn't fire when the app is in the background.

**Current Mitigation**: The code already handles this by scheduling a local notification when entering background (`handleAppEnteredBackground`). This is actually working correctly.

**Verification Needed**: Ensure background notification logic is properly triggered.

## Implementation Details

### Files Modified
1. **IdleDetectionService.swift**
   - Add `markAlerted()` method for proper state transition
   - Add `minGPSAccuracyForMovement` and `maxRealisticSpeedKmh` config values
   - Add `shouldRecordMovement()` method with GPS accuracy and jump filtering
   - Add `isAccuracyGoodForMovement()` helper method
   - Add `isLikelyGPSJump()` helper method
   - Update `updateLocation()` to use new validation methods

2. **MeterViewModel.swift**
   - Add `showIdleAlertBinding` computed property for proper SwiftUI binding
   - Call `markAlerted()` when showing alert

3. **MainMeterView.swift**
   - Use `viewModel.showIdleAlertBinding` instead of manual Binding

4. **IdleDetectionServiceTests.swift**
   - Add tests for `minGPSAccuracyForMovement` config
   - Add tests for `maxRealisticSpeedKmh` config
   - Add tests for GPS accuracy filtering
   - Add tests for GPS jump detection
   - Add tests for indoor GPS jump scenarios

### State Flow (After Fix)
```
[inactive] --startMonitoring()--> [monitoring]
                                      |
                                      | (timer detects 10min idle)
                                      v
                                   [idle]
                                      |
                                      | (UI shows alert)
                                      v
                                  [alerted]
                                   /     \
    (user taps "continue")        /       \  (user taps "stop")
                                 v         v
                          [dismissed]  --> stopMeter() --> [inactive]
                                 |
                                 | (immediately)
                                 v
                           [monitoring]
```

### Test Scenarios
1. **Foreground - Stay still**: Start meter -> Stay still for 10+ min -> Alert should appear
2. **Foreground - Move around**: Start meter -> Move > 50m -> No alert, timer resets
3. **Foreground - Move then stop**: Start meter -> Move -> Stop for 10 min -> Alert should appear
4. **Background - Stay still**: Start meter -> Background app -> Stay still 10 min -> Notification should appear
5. **Alert dismiss - Continue**: Alert appears -> Tap "Continue" -> Alert dismisses, monitoring continues
6. **Alert dismiss - Stop**: Alert appears -> Tap "Stop" -> Meter stops
7. **Indoor GPS jumping**: Stationary indoors with GPS jumping -> GPS jumps ignored -> Alert appears after 10 min
8. **Poor GPS accuracy**: Location updates with accuracy > 30m -> Movement not recorded
9. **GPS jump detection**: Unrealistic speed (> 200 km/h) -> Movement ignored as GPS jump

## Risks and Considerations
- The fix maintains backward compatibility with existing saved trips
- No changes to the fare calculation or location tracking logic
- Background notification functionality is unchanged

## References
- Original implementation: `IdleDetectionService.swift`
- Integration: `MeterViewModel.swift`
- UI: `MainMeterView.swift`
- Tests: `IdleDetectionServiceTests.swift`
