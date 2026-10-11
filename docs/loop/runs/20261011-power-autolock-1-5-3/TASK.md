# Task: foreground screen policy and background power profile

## User value

Long-running use must not keep the iPhone display awake after a trip is reset or
when the app leaves the foreground, while active-trip location tracking remains
reliable. Reduce unnecessary background wake-ups without restoring the removed
HoguNavigation feature.

## Acceptance criteria

- **AC-01**: Resetting a trip stops location tracking and permits iOS auto-lock.
- **AC-02**: Inactive/background transitions immediately permit auto-lock.
- **AC-03**: Location updates remain high-accuracy during an active foreground
  trip, but background operation allows automatic pausing and uses a 15-second
  signal-loss check cadence.
- **AC-04**: Idle-detection polling does not run in the background; its local
  notification behavior is retained.
- **AC-05**: Release version is 1.5.3 in both the Xcode project and generator
  configuration.
- **AC-06**: HoguNavigation remains removed.

## Scope and non-goals

Changes are limited to lifecycle/power policy, reset cleanup, release version,
and supporting evidence. No navigation feature, background-location entitlement,
or App Store submission is included.

## Risk and rollback

The principal risk is an unintended GPS behavior change during a background trip.
Rollback is the PR revert; no feature flag is required. The user owns final
device/GPS/thermal QA.

## Validation plan

Run a generic iOS Simulator build, `plutil -lint`, and `git diff --check`.
Manually verify reset auto-lock, foreground/background lock behavior, a live trip,
and background-trip GPS continuity on a device.
