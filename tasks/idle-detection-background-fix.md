# Feature Specification: Idle Detection Background Fix

**Task ID:** IDLE-002
**Created:** 2025-12-23
**Branch:** fix/idle-detection-background
**Status:** Completed

## Problem Description
- Idle detection does not work when screen is off or app is in background
- Timer is suspended when app enters background (iOS limitation)
- User does not receive notification when idle threshold is reached while screen is off

## Root Cause Analysis
1. `Timer.scheduledTimer` is suspended by iOS when app enters background
2. No local notification scheduled when idle state detected
3. No app lifecycle handling to recalculate idle time on foreground

## Goal
- Idle detection should work even when screen is off
- User should receive local notification when idle threshold reached in background
- User can respond to notification and choose to continue or stop meter

## Technical Analysis
- [x] Identify why idle detection fails in background
- [x] Check Timer behavior in background mode
- [x] Determine solution: Local Notification + Foreground recalculation

## Implementation Plan

### 1. Add Local Notification Support
- Request notification permission on first meter start
- Schedule local notification when idle state detected
- Handle notification response (continue/stop)

### 2. Add App Lifecycle Handling
- Track `lastMovementTime` persistently
- On app becomes active: recalculate idle duration
- If threshold exceeded, trigger idle alert immediately

### 3. Notification Categories
```swift
- Category: "IDLE_ALERT"
- Actions:
  - "CONTINUE" (계속) - Dismiss alert, continue monitoring
  - "STOP" (종료) - Stop meter, show receipt
```

## Files to Modify

1. **IdleDetectionService.swift**
   - Add notification scheduling
   - Add `handleAppBecameActive()` method
   - Persist `lastMovementTime` for background calculation

2. **HoguMeterApp.swift**
   - Setup notification categories on launch
   - Handle notification responses
   - Pass scene phase to IdleDetectionService

3. **MeterViewModel.swift**
   - Request notification permission on meter start
   - Handle notification responses

## State Flow (Updated)
```
App Active + No Movement 10min → Show In-App Alert
                                    ↓
                              User responds

App Background + No Movement 10min → Send Local Notification
                                         ↓
                                   User taps notification
                                         ↓
                                   App opens + Handle response

App Returns to Foreground → Recalculate elapsed time
                               ↓
                         If > threshold → Show alert immediately
```

## Testing Checklist
- [ ] App active, wait 10+ minutes → in-app alert shown
- [ ] Screen off, wait 10+ minutes → notification received
- [ ] Tap "계속" in notification → meter continues
- [ ] Tap "종료" in notification → meter stops, receipt shown
- [ ] App returns from background → idle time recalculated
- [ ] Notification permission denied → graceful fallback (in-app only)

## Acceptance Criteria
- [x] Local notification sent when idle detected in background
- [x] Notification has "계속" and "종료" action buttons
- [x] Tapping notification opens app and handles response
- [x] Idle time recalculated when app returns to foreground
- [x] Build succeeds, all tests pass

## Implementation Summary

### Files Modified

1. **IdleDetectionService.swift** (Major Update)
   - Added `UserNotifications` import
   - Added notification configuration constants to `IdleDetectionConfig`:
     - `notificationCategoryIdentifier = "IDLE_ALERT"`
     - `notificationIdentifier = "idle-detection-alert"`
     - `continueActionIdentifier = "CONTINUE"`
     - `stopActionIdentifier = "STOP"`
   - Added properties: `isInBackground`, `hasNotificationPermission`, `notificationSent`
   - Added protocol methods: `handleAppBecameActive()`, `handleAppEnteredBackground()`, `requestNotificationPermission()`, `setupNotificationCategories()`
   - Added implementation for background notification scheduling and sending

2. **HoguMeterApp.swift** (Major Update)
   - Added `@UIApplicationDelegateAdaptor` for `AppDelegate`
   - Added `@Environment(\.scenePhase)` for lifecycle tracking
   - Added `init()` to call `IdleDetectionService.setupNotificationCategories()`
   - Added `handleScenePhaseChange()` to post app lifecycle notifications
   - Created `AppDelegate` class implementing `UNUserNotificationCenterDelegate`
   - Added `Notification.Name` extensions for inter-component communication

3. **MeterViewModel.swift**
   - Added `setupAppLifecycleBindings()` method
   - Subscribes to `.appBecameActive` and `.appEnteredBackground` notifications
   - Subscribes to `.idleDetectionContinue` and `.idleDetectionStop` notifications
   - Calls `idleDetectionService.requestNotificationPermission()` on meter start

## Build Status
- [x] Build Succeeded (2025-12-23)
