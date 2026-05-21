# JP Style Lounge Studio - Store Readiness Deep Dive

Date: 2026-04-30  
Scope: Flutter app repo review + current Google Play and Apple App Store standards.

---

## Executive Assessment

The project is not yet ready for Google Play or Apple App Store submission.

Current state appears to be an early foundation/shell build with policy and release configuration gaps that are likely to block review.

Since the initial review, foundational hardening has been applied (env verification, startup config guard, CI checks), store-compliance artifacts now exist under `docs/store/`, and Android release signing now uses keystore-based release config. The app is still pre-submission primarily due to policy URL completion and final release-artifact validation.

---

## What Was Reviewed

- App/runtime entry and behavior: `lib/main.dart`
- Environment and feature toggles: `lib/core/env/env.dart`, `.env.example`
- Notification setup: `lib/core/notifications/notification_service.dart`, `lib/firebase_options.dart`
- Android config: `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- iOS config: `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`
- Project docs and setup guidance: `README.md`, `SETUP.md`, `docs/ARCHITECTURE.md`, `ROADMAP.md`, `docs/APPWRITE_BACKEND.md`
- Basic tests: `test/widget_test.dart`

---

## Key Findings

### 1) App Completeness Risk (Medium)

- The app boots into an MVP booking flow (service, slot, details, review) and now attempts to read services and submit bookings via Appwrite collections.
- Functional depth is still MVP-level and requires full production hardening (domain validation, auth/session enforcement, and failure-state UX).

Evidence:
- `lib/main.dart` (routes to `MvpBookingFlow`)
- `lib/features/booking/mvp_booking_flow.dart`
- `test/widget_test.dart` (asserts booking flow shell)

Impact:
- Materially improved from placeholder-shell risk; still requires production-grade booking reliability and backend hardening before broad release.

### 2) Android Release Signing Risk (Resolved)

- Release build uses a dedicated `release` signing config loaded from `android/key.properties`.
- Build fails fast when signing properties are missing.

Evidence:
- `android/app/build.gradle.kts`:
  - `signingConfig = signingConfigs.getByName("release")`
  - `Missing android/key.properties for release signing` guard

Impact:
- Signing posture is now aligned with production release practices.

### 3) iOS Permission Metadata Gaps (High)

- `Info.plist` now includes baseline usage description keys and background remote notification mode.
- Final validation against merged plugin manifests and runtime prompts is still required.

Evidence:
- `ios/Runner/Info.plist` contains:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
  - `UIBackgroundModes` with `remote-notification`

Impact:
- Potential runtime permission issues and App Review rejection risk if functionality requests protected resources without clear purpose strings.

### 4) iOS Privacy Manifest Gap (High)

- `PrivacyInfo.xcprivacy` has been added at `ios/Runner/PrivacyInfo.xcprivacy` as a baseline.

Evidence:
- `ios/Runner/PrivacyInfo.xcprivacy`

Impact:
- Baseline file now exists; still requires final archive-level validation against SDK/runtime access.

### 5) Policy Disclosure Readiness Gaps (High)

- Draft compliance pack now exists:
  - `docs/store/PLAY_DATA_SAFETY_MATRIX.md`
  - `docs/store/APP_STORE_PRIVACY_MATRIX.md`
  - `docs/store/PRIVACY_AND_DELETION.md`
- Privacy policy and deletion URLs are still TODO and remain submission blockers.

Impact:
- High likelihood of submission friction, delays, and inconsistent declarations.

### 6) Documentation Drift / Consistency Issues (Low)

- Active docs now use Appwrite terminology consistently.
- Historical planning files may still reference prior backend direction and should remain clearly labeled as historical context.

Impact:
- Lower operational risk; maintainers should keep historical snapshots clearly marked to avoid onboarding confusion.

---

## Standards Cross-Check (Current Official References)

### Google Play

- Target API requirement: new apps and updates must target a recent API (Android 15 / API 35 threshold in current guidance cycle).
- Data Safety form mandatory for published apps/tracks (except limited internal-only scenarios).
- Privacy policy required and must align with app behavior and declarations.
- Sensitive data/permission usage must be clear, justified, and disclosed.

Primary references:
- https://developer.android.com/google/play/requirements/target-sdk
- https://support.google.com/googleplay/android-developer/answer/11926878
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://support.google.com/googleplay/android-developer/answer/10144311

### Apple App Store

- App Review requires functional completeness and accurate metadata.
- Privacy policy URL is required in App Store Connect and should be accessible in-app.
- App privacy details (nutrition label) must include first- and third-party SDK data handling.
- Required reason API/privacy manifest expectations apply to modern submissions.

Primary references:
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api

---

## Priority Risk Register

### P0 - Blockers

- Privacy policy and deletion URLs still TODO in `docs/store/PRIVACY_AND_DELETION.md`
- Final iOS permission metadata validation against actual prompts and merged manifests
- Final privacy manifest validation in archived iOS build

### P1 - Critical Readiness Gaps

- Finalize Google Play Data Safety mapping from release artifact behavior
- Finalize App Store privacy label mapping from release artifact behavior
- Publish privacy policy + account/data deletion URLs and wire in-app access path

### P2 - Important Quality Gaps

- End-to-end booking reliability tests against Appwrite-backed flows
- Minimal test coverage for business-critical flows (booking/payment/notifications)

---

## Recommended Action Plan

### Phase A - Submission Blocker Fixes

1. Publish final privacy policy and account/data deletion URLs.
2. Validate all required iOS `NS...UsageDescription` keys against actual runtime prompts and plugin manifest merge.
3. Validate `PrivacyInfo.xcprivacy` content in release archive.
4. Confirm target API and platform deployment settings before release build.
5. Validate Android release signing on CI using secure secret-injection workflow.

### Phase B - Compliance Artifacts

1. Create Google Play Data Safety declaration matrix from actual runtime behavior and SDKs.
2. Create App Store privacy nutrition label matrix from first- and third-party data handling.
3. Publish privacy policy (public URL) and add in-app access path.
4. Define and document account/data deletion process and retention policy.
5. Ensure disclosures match behavior exactly across:
   - app prompts
   - privacy policy
   - Play Console
   - App Store Connect

### Phase C - Hardening

1. Expand tests for booking, payment, notifications, and error states.
2. Run release builds on clean CI for Android and iOS.
3. Prepare reviewer notes, test account/demo mode, and backend availability plan.
4. Keep architecture and setup docs synchronized with release behavior.
5. Enforce `dart run tool/store_readiness_audit.dart --fail-on-warning` in CI and pre-release checks.

---

## Practical Submission Checklist

Use this as a pre-submit gate:

- [ ] Booking flow validated with production Appwrite project data and auth/session rules
- [ ] Android release signing validated in CI/CD release job
- [ ] Target API level validated against current Play requirements
- [ ] Permission requests and rationale screens aligned with actual use
- [ ] Google Play Data Safety form completed and verified (draft: `docs/store/PLAY_DATA_SAFETY_MATRIX.md`)
- [ ] Privacy policy URL available and accurate (draft tracker: `docs/store/PRIVACY_AND_DELETION.md`)
- [ ] iOS `Info.plist` usage descriptions complete and runtime-validated
- [ ] `PrivacyInfo.xcprivacy` present and valid in final archive
- [ ] App Store privacy details completed and accurate (draft: `docs/store/APP_STORE_PRIVACY_MATRIX.md`)
- [ ] Data deletion/account deletion flow documented and usable (draft: `docs/store/PRIVACY_AND_DELETION.md`)
- [ ] Reviewer/test credentials and notes prepared
- [ ] Store metadata/screenshots match real app behavior

---

## Notes and Assumptions

- This assessment is repository-state based and does not include runtime binary scanning of generated APK/AAB/IPA artifacts.
- Some permissions may be added through plugin manifest merge at build time; final release artifact verification is still required.
- Policy pages evolve; re-check requirements right before submission.

