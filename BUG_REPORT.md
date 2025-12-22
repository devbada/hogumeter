# Bug Report: Fare Meter Calculation Issue

## Summary
The fare meter was calculating fare on GPS location updates even before the 'Start' button was clicked, and displayed `0` instead of the base fare in idle state.

## Environment
- **App**: HoguMeter
- **Component**: MeterViewModel
- **Files Affected**:
  - `HoguMeter/Presentation/ViewModels/MeterViewModel.swift`

## Bug Description

### Root Causes Identified

**1. Automatic Location Tracking (LocationService.swift:129-139)**
```swift
func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
        manager.startUpdatingLocation()  // Starts tracking without Start button!
    // ...
    }
}
```
When the app already has location permission, `locationManagerDidChangeAuthorization` is called automatically, which triggers `startUpdatingLocation()` without the user clicking 'Start'.

**2. Unconditional Fare Calculation (MeterViewModel.swift:152-193)**
```swift
private func handleLocationUpdate(_ location: CLLocation) {
    // No state check - fare calculated on every location update!
    currentFare = fareCalculator.calculate(...)
}
```
The `handleLocationUpdate()` method was calculating fare on every GPS location update without checking if `state == .running`.

**3. Zero Initial Fare**
```swift
private(set) var currentFare: Int = 0  // Should be base fare
```
The initial fare was set to `0` instead of the base fare.

## Expected Behavior

| State | Expected Display |
|-------|------------------|
| Before Start (idle) | Base fare (e.g., 4,800 won) |
| After Start (running) | Calculated fare based on distance/time |
| After Stop (stopped) | Final calculated fare |
| After Reset (idle) | Base fare again |

## Solution Implemented

### Fix 1: Guard Condition in handleLocationUpdate()
Added early return when meter is not running:
```swift
private func handleLocationUpdate(_ location: CLLocation) {
    // Only process location updates when meter is running
    guard state == .running else { return }

    // ... rest of the fare calculation logic
}
```

### Fix 2: Initialize with Base Fare
```swift
init(...) {
    // ...
    currentFare = getBaseFare()  // Set initial base fare
}

private func getBaseFare() -> Int {
    let fare = settingsRepository.currentRegionFare
    let timeZone = FareTimeZone.current()
    return fare.getFare(for: timeZone).baseFare
}
```

### Fix 3: Reset to Base Fare
```swift
func resetMeter() {
    state = .idle
    currentFare = getBaseFare()  // Reset to base fare, not 0
    // ...
}
```

## Files Changed

1. **MeterViewModel.swift**
   - Added `settingsRepository` dependency
   - Added `getBaseFare()` helper method
   - Added `guard state == .running else { return }` in `handleLocationUpdate()`
   - Set initial `currentFare` to base fare in `init()`
   - Changed `resetMeter()` to reset fare to base fare

2. **ContentView.swift**
   - Updated `createMeterViewModel()` to pass `settingsRepository`

3. **MainMeterView.swift**
   - Updated Preview to include `settingsRepository` parameter

## Behavior After Fix

| State | Before Fix | After Fix |
|-------|------------|-----------|
| App launch | `0 won` + fare calculating | Base fare (e.g., `4,800 won`) |
| GPS updates (idle) | Fare keeps changing | Base fare remains stable |
| After Start | Fare calculating | Fare calculating (correct) |
| After Reset | `0 won` | Base fare |

## Testing Checklist

- [ ] App launches with base fare displayed
- [ ] GPS permission granted does not trigger fare calculation
- [ ] Fare only starts calculating after 'Start' button click
- [ ] 'Stop' button stops fare calculation
- [ ] 'Reset' button returns fare to base fare (not 0)
- [ ] Time zone changes update base fare correctly (day/night)
