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

### Issue 5: Dead Reckoning Blocking Idle Detection (Critical)
**Location**: `IdleDetectionService.swift:453-455`

**Problem**: When GPS signal is lost, the Dead Reckoning feature activates and completely blocks idle detection:
```swift
private func checkIdleState() {
    // Dead Reckoning 중이면 체크하지 않음
    guard !isDeadReckoningActive else { return }  // <-- THIS BLOCKS IDLE DETECTION!
    // ...
}
```

**Flow that causes the bug (Simulator scenario)**:
1. Start meter on simulator with "None" or no GPS location
2. After 5 seconds of no GPS updates, `LocationService.checkForSignalLoss()` triggers
3. `gpsSignalState = .lost`
4. `MeterViewModel` receives this and calls `idleDetectionService.setDeadReckoningActive(true)`
5. `checkIdleState()` returns early due to Dead Reckoning guard
6. **Idle alert NEVER appears**, even after 10+ minutes

**Why the original guard was added**: The intention was to pause idle detection during temporary GPS outages (like tunnels) where the user is still moving.

**Why it's wrong**: If the user is genuinely stationary (no GPS because they're indoors and not moving), idle detection should still work. The idle timer continues counting based on `lastMovementTime`, regardless of GPS signal state.

**Fix**: Remove the Dead Reckoning guard from `checkIdleState()`:
```swift
private func checkIdleState() {
    // 모니터링 중일 때만 체크
    // Note: Dead Reckoning 중에도 idle 체크 수행
    // GPS 신호가 없어도 사용자가 정지해 있으면 알림 필요
    guard state == .monitoring else { return }
    // ...
}
```

Also updated `setDeadReckoningActive()` to not reset `lastMovementTime` when Dead Reckoning is deactivated:
```swift
func setDeadReckoningActive(_ active: Bool) {
    isDeadReckoningActive = active
    if active {
        Logger.gps.debug("[IdleDetection] Dead Reckoning 활성화 - 무이동 감지는 계속됨")
    } else {
        // Dead Reckoning 해제 시에도 타이머 리셋 안 함
        // GPS 복구 후 실제 이동이 감지되면 updateLocation()에서 리셋됨
        Logger.gps.debug("[IdleDetection] Dead Reckoning 해제")
    }
}
```

### Issue 6: Background Notification Permission Check (Critical)
**Location**: `IdleDetectionService.swift:scheduleBackgroundNotification()`

**Problem**: Background notifications were not appearing because the `hasNotificationPermission` flag was checked synchronously but set asynchronously:
```swift
private func scheduleBackgroundNotification() {
    guard hasNotificationPermission else {  // <-- May be false even if permission granted!
        return
    }
    // ...
}
```

**Flow that causes the bug**:
1. User grants notification permission when starting meter
2. `requestNotificationPermission()` is called, callback updates `hasNotificationPermission` asynchronously
3. User backgrounds the app before callback completes
4. `scheduleBackgroundNotification()` checks `hasNotificationPermission` which is still `false`
5. **Notification never scheduled**

**Fix**: Check notification permission in real-time instead of using cached value:
```swift
private func scheduleBackgroundNotification() {
    guard let lastMovement = lastMovementTime else { return }

    let elapsed = Date().timeIntervalSince(lastMovement)
    let remaining = IdleDetectionConfig.idleThreshold - elapsed

    guard remaining > 0 else {
        sendIdleNotificationDirectly()
        return
    }

    // Check permission in real-time
    UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
        guard let self = self else { return }
        guard settings.authorizationStatus == .authorized else { return }

        // Schedule notification...
    }
}
```

### Issue 7: GPS Auto-Start on App Launch
**Location**: `LocationService.swift:locationManagerDidChangeAuthorization()`

**Problem**: GPS was automatically activated when the app launched, even without starting the meter:
```swift
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways:
        manager.startUpdatingLocation()  // <-- STARTS GPS IMMEDIATELY!
    case .authorizedWhenInUse:
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()  // <-- STARTS GPS IMMEDIATELY!
    // ...
    }
}
```

**Why it's wrong**: GPS should only be active when the meter is running to conserve battery.

**Fix**: Remove `startUpdatingLocation()` from authorization callback:
```swift
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways:
        // Only check permission, don't start tracking
        Logger.gps.info("[GPS] 위치 권한 승인됨 (Always)")
    case .authorizedWhenInUse:
        manager.requestAlwaysAuthorization()
        Logger.gps.info("[GPS] 위치 권한 승인됨 (When In Use)")
    // ...
    }
}
```

GPS is now only started when `startTracking()` is explicitly called (when user taps "Start").

## Implementation Details

### Files Modified
1. **IdleDetectionService.swift**
   - Add `markAlerted()` method for proper state transition
   - Add `minGPSAccuracyForMovement` and `maxRealisticSpeedKmh` config values
   - Add `shouldRecordMovement()` method with GPS accuracy and jump filtering
   - Add `isAccuracyGoodForMovement()` helper method
   - Add `isLikelyGPSJump()` helper method
   - Update `updateLocation()` to use new validation methods
   - Remove Dead Reckoning guard from `checkIdleState()` (Issue 5)
   - Update `setDeadReckoningActive()` to not reset timer on deactivation
   - Remove Dead Reckoning guard from `handleAppBecameActive()`
   - Add `sendIdleNotificationDirectly()` method with real-time permission check (Issue 6)
   - Update `scheduleBackgroundNotification()` to check permission in real-time (Issue 6)

2. **MeterViewModel.swift**
   - Add `showIdleAlertBinding` computed property for proper SwiftUI binding
   - Call `markAlerted()` when showing alert

3. **MainMeterView.swift**
   - Use `viewModel.showIdleAlertBinding` instead of manual Binding

4. **LocationService.swift**
   - Remove `startUpdatingLocation()` from `locationManagerDidChangeAuthorization()` (Issue 7)
   - GPS now only starts when `startTracking()` is explicitly called

5. **IdleDetectionServiceTests.swift**
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
10. **Simulator (No GPS)**: Start meter with no GPS location -> Dead Reckoning activates -> Alert should still appear after 10 min
11. **GPS signal loss while stationary**: Start meter -> GPS signal lost -> Alert should still appear after 10 min

## v1.1.1 Additional Fix: Background Alert Re-scheduling

### Issue 8: Background Notification Not Re-scheduled After Dismiss
**Location**: `IdleDetectionService.swift:dismissAlert()`

**Problem**: When user selects "Continue" from idle alert while app is in background, the 10-minute timer restarts but no new background notification is scheduled:
```
Scenario:
1. Start meter
2. 10 minutes → Idle notification appears
3. User taps "Continue"
4. dismissAlert() called
   - lastMovementTime reset ✅
   - But no background notification re-scheduled ❌
5. 10 minutes later (screen off) → No notification ❌
```

**Root Cause**: `dismissAlert()` resets the idle timer but doesn't check if app is in background to re-schedule the notification.

**Fix**: Add background notification re-scheduling in `dismissAlert()`:
```swift
func dismissAlert() {
    guard state == .idle || state == .alerted else { return }

    cancelScheduledNotification()
    notificationSent = false
    stateSubject.send(.dismissed)
    lastMovementTime = Date()
    idleDuration = 0

    stateSubject.send(.monitoring)

    // 🆕 Re-schedule notification if in background
    if isInBackground {
        scheduleBackgroundNotification()
        Logger.gps.info("[IdleDetection] 알림 해제 - 백그라운드 알림 재예약됨")
    }

    Logger.gps.info("[IdleDetection] 알림 해제 - 모니터링 재개")
}
```

**Test Scenarios Added**:
- Foreground: "Continue" → 10 min → Alert reappears ✅
- Background: "Continue" → 10 min → Notification reappears ✅
- Indoor (poor GPS): "Continue" → 10 min → Alert/Notification reappears ✅

---

## Risks and Considerations
- The fix maintains backward compatibility with existing saved trips
- No changes to the fare calculation or location tracking logic
- Background notification functionality now includes re-scheduling after dismiss

## References
- Original implementation: `IdleDetectionService.swift`
- Integration: `MeterViewModel.swift`
- UI: `MainMeterView.swift`
- Tests: `IdleDetectionServiceTests.swift`
