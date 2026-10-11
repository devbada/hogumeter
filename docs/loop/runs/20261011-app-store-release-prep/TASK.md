# Task: App Store 1.5.3 release preparation

## Value and scope

Prepare a signed 1.5.3 IPA and a handoff checklist for the user to upload from a
PC. Do not upload to App Store Connect, distribute through TestFlight, or submit
for App Review.

## Acceptance criteria

- **AC-01**: A Release iPhoneOS archive succeeds for `com.hogumeter.app` 1.5.3 (1).
- **AC-02**: An App Store Connect export succeeds with Apple Distribution signing.
- **AC-03**: The IPA bundle version and signature are verified locally.
- **AC-04**: The handoff identifies the App Store Connect and device-only checks.
- **AC-05**: HoguNavigation remains absent.

## Risks and non-goals

Build-number uniqueness, App Store Connect metadata, privacy questionnaire,
screenshots, TestFlight, and review submission require the user’s account action.
No source feature changes, upload, or review submission are included.
