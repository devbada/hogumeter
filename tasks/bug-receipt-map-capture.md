---

### Bug Report: Receipt Map Capture Misalignment

**Bug ID:** BUG-MAP-001
**Created:** 2025-01-14
**Branch:** fix/receipt-map-capture
**Severity:** High
**Status:** Fixed

---

#### Bug Description

When saving/sharing the receipt as an image, the route marking on the map is displayed incorrectly - the route line appears misaligned or skewed compared to how it looks in the app.

#### Steps to Reproduce

1. Start meter and travel a route
2. Stop meter and view receipt (영수증)
3. Observe: Route displays correctly in the app ✅
4. Tap capture/save button (캡쳐저장) or share button (영수증 공유)
5. View saved image in Photos app
6. Observe: Route line is misaligned/skewed ❌

#### Expected Behavior

- Saved image should look identical to what is displayed in the app
- Route line should be correctly aligned on the map

#### Actual Behavior

- Route line appears misaligned or skewed in saved image
- The spacing/positioning is offset from the actual map

#### Screenshots

- In-app display: Route looks correct
- Saved image: Route is misaligned/skewed

---

## Root Cause Analysis

### Investigation Findings

The bug is caused by **two different coordinate conversion systems** being used:

#### Live View (Correct ✅)
In `generateMapSnapshotWithRoute()` + `drawRouteOnSnapshot()`:
- Uses `MKMapSnapshotter` to generate map
- Uses `snapshot.point(for: coordinate)` for coordinate conversion
- This correctly converts geo coordinates to screen points using MapKit's internal projection

#### Saved Image (Incorrect ❌)
In `generateMapSnapshot()` + `ReceiptImageGenerator.drawRouteMap()`:
- `generateMapSnapshot()` returns ONLY `snapshot.image` WITHOUT the route drawn
- `ReceiptImageGenerator.drawRouteMap()` uses a **custom coordinate conversion function** (`toScreenPoint`)
- This custom math doesn't match MKMapSnapshotter's coordinate projection

### Code Comparison

**Live View (correct):**
```swift
// drawRouteOnSnapshot() - line 503
let firstPoint = snapshot.point(for: firstCoord)  // ✅ Uses MapKit's conversion
```

**Saved Image (incorrect):**
```swift
// ReceiptImageGenerator.drawRouteMap() - lines 714-717
func toScreenPoint(lat: Double, lon: Double) -> CGPoint {
    let x = padding + 10 + ((lon - (centerLon - lonRange / 2)) / lonRange) * (mapWidth - 20)
    let y_coord = y + mapHeight - 10 - ((lat - (centerLat - latRange / 2)) / latRange) * (mapHeight - 20)
    return CGPoint(x: x, y: y_coord)  // ❌ Custom conversion doesn't match MKMapSnapshotter
}
```

The custom `toScreenPoint` function uses simple linear interpolation which:
1. Doesn't account for map projection (Mercator)
2. Uses different padding/margin calculations
3. Doesn't match the actual map tile positions

---

## Fix Implementation

### Solution
Modify `generateMapSnapshot()` to include route drawing using `drawRouteOnSnapshot()`, and update `ReceiptImageGenerator.drawRouteMap()` to skip manual route drawing when a map snapshot with route is provided.

### Changes Required

1. **ReceiptView.swift - `generateMapSnapshot()`**
   - Draw route on snapshot using `snapshot.point(for:)` before returning
   - Match the approach used in `generateMapSnapshotWithRoute()`

2. **ReceiptView.swift - `ReceiptImageGenerator.drawRouteMap()`**
   - When mapSnapshot is provided, only draw the image and border
   - Skip the custom route/marker drawing since it's already in the snapshot

---

## Fix Applied

### Changes Made (2025-01-14)

**File:** `HoguMeter/Presentation/Views/Receipt/ReceiptView.swift`

1. **Modified `generateMapSnapshot()` (lines 400-438)**
   - Now calls `drawRouteOnSnapshot(snapshot)` before returning
   - Uses `snapshot.point(for: coordinate)` for proper coordinate conversion
   - Updated padding values to match `generateMapSnapshotWithRoute()`

2. **Modified `ReceiptImageGenerator.drawRouteMap()` (lines 674-768)**
   - When mapSnapshot is provided, only draws the image and border (no route drawing)
   - Skips the custom `toScreenPoint` conversion since route is already in snapshot
   - Retains fallback manual route drawing for cases without map snapshot

### Build Status
✅ BUILD SUCCEEDED (verified on iPhone 15 simulator)

---

## Testing Checklist

After fix:
- [ ] Capture receipt → route aligned correctly in saved image
- [ ] Share receipt → route aligned correctly in shared image
- [ ] Test on different devices (different screen scales)
- [ ] Test with various route lengths/shapes
- [ ] Compare in-app display vs saved image - should be identical

## Verification Checklist

- [ ] Route line position matches in-app display
- [ ] Start marker (green) correctly positioned
- [ ] End marker (red) correctly positioned
- [ ] Route line width looks correct
- [ ] No offset/skew in saved image
- [ ] Works on all device sizes
- [ ] Build succeeds
- [ ] All tests pass
