# Phase 0 Week 1-2 Execution Board

Status: Complete (Approved May 25, 2026)
Model: Hybrid Development Model
Reference: [HYBRID_DEV_MODEL.md](HYBRID_DEV_MODEL.md)

## Week 1: Foundation Lock

### Day 1 (Planning Lock)

Objectives:
1. Confirm scope boundaries and acceptance criteria.
2. Confirm identity/package consistency (Android/iOS/Firebase/Appwrite).

Checklist:
- [x] Validate all package and bundle identifiers.
- [x] Confirm Firebase app registrations.
- [x] Confirm Appwrite project ids and table naming strategy.

### Day 2 (Architecture and Tooling)

Objectives:
1. Lock router/theme/startup architecture baseline.
2. Enforce quality gate commands.

Checklist:
- [x] Verify app boots with router and theme abstractions.
- [x] Validate analyze/test baseline in CI.
- [x] Confirm env verification script behavior.

### Day 3 (Appwrite Baseline)

Objectives:
1. Seed baseline data and availability.
2. Validate booking flow read/write against dev schema.

Checklist:
- [x] Run `tool/appwrite/bootstrap_phase0.dart` with server key.
- [x] Verify service rows include `audience` metadata.
- [x] Verify booking write path and required columns.

### Day 4 (Firebase Baseline)

Objectives:
1. Finalize platform config files and FlutterFire options.
2. Validate Firebase initialization paths.

Checklist:
- [x] Replace Android and iOS Firebase config files with real values.
- [x] Run `flutterfire configure`.
- [x] Validate push initialization logs in development mode.

### Day 5 (Gate Review)

Objectives:
1. Run Gate 1 and Gate 2 readiness checks.
2. Produce carryover list for Week 2.

Checklist:
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `dart run tool/verify_env.dart`
- [x] `dart run tool/store_readiness_audit.dart`

## Week 2: Reliability and Operational Readiness

### Day 6 (Branch and Release Discipline)

Objectives:
1. Formalize branch strategy and release conventions.
2. Align PR templates/checklists with gates.

Checklist:
- [x] Document branch policy and PR gate policy.
- [x] Define merge rules for main/develop.

### Day 7 (Secrets and Setup Reproducibility)

Objectives:
1. Ensure setup can be repeated by a fresh developer.
2. Harden secrets hygiene pathways.

Checklist:
- [x] Fresh machine setup dry-run.
- [x] Confirm no server secrets in bundled env files.
- [x] Verify setup docs against actual commands.

Evidence (May 25, 2026):
- `flutter clean && flutter pub get && flutter test test/widget_test.dart` completed successfully.

### Day 8 (Runtime Hardening)

Objectives:
1. Validate runtime guard behavior for missing config.
2. Validate graceful error paths.

Checklist:
- [x] Negative tests for missing Appwrite/Firebase config.
- [x] Verify user-visible fallback/error messaging.

Evidence (May 25, 2026):
- Added `test/core/appwrite/runtime_guard_test.dart` to validate missing Appwrite keys fail fast.
- Added startup fallback coverage in `test/widget_test.dart` to assert visible startup error rendering.

### Day 9 (Integration Confidence)

Objectives:
1. Validate booking baseline flow with seeded data.
2. Confirm event and log quality.

Checklist:
- [x] Complete one full booking from service to confirmation.
- [x] Confirm role/audience fields persist correctly.

### Day 10 (Phase 0 Exit)

Objectives:
1. Run Gate 3 readiness review.
2. Approve or reject Phase 0 exit.

Checklist:
- [x] All Phase 0 exit criteria reviewed.
- [x] Remaining risks assigned with owners and due dates.
- [x] Phase 1 handoff notes published.

Exit review summary (May 25, 2026):
- Gate checks passed: `flutter analyze`, `flutter test`, `dart run tool/verify_env.dart`, `dart run tool/store_readiness_audit.dart`.
- Open setup-path risk status: no unowned P1 risks as of this review.
- Handoff published: `docs/phases/PHASE_1_HANDOFF_FROM_PHASE_0.md`.

## Definition of Week Success

1. CI health remains green across baseline checks.
2. Firebase and Appwrite dev baselines are operational.
3. Setup is reproducible and documented.
4. No open P0 defects and no unowned P1 issues.
