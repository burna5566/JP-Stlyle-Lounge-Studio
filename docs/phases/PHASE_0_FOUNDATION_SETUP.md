# Phase 0 Playbook: Foundation and Setup

Timeline: Week 1 to Week 2
Primary Goal: Establish reliable engineering and platform foundations for accelerated MVP execution.

Execution board:
- [PHASE_0_WEEK_1_2_EXECUTION.md](PHASE_0_WEEK_1_2_EXECUTION.md)

Appwrite bootstrap toolkit:
- [../../tool/appwrite/README.md](../../tool/appwrite/README.md)

## Business Outcomes

1. Team can deliver features with predictable quality.
2. Core platform integrations are configured and testable.
3. Environment and release safety controls are active.

## Scope

In scope:
- app scaffold and base architecture
- environment management
- Firebase and notification baseline
- Appwrite connectivity baseline
- CI checks and code quality baseline
- branch strategy and delivery workflow

Out of scope:
- full production feature set
- advanced analytics
- monetization and growth features

## Hybrid Model Execution

### Discovery Track

Tasks:
- define baseline architecture boundaries
- define environment variable contracts
- define release and compliance baseline

Deliverables:
- architecture baseline in docs
- environment key matrix
- Phase 0 risk register

### Delivery Track

Tasks:
- wire app bootstrap, theme, and router
- wire Firebase setup and options
- wire Appwrite runtime validation
- implement CI quality checks

Deliverables:
- runnable app on emulator/device
- passing analyze and test baseline
- reproducible setup instructions

## Workstreams

### Workstream A: App Architecture Baseline

Checklist:
- core, features, and shared folder conventions
- app router shell and route map baseline
- app theme abstraction
- startup bootstrap flow

Definition of done:
- architecture modules are wired and documented

### Workstream B: Configuration and Secrets Hygiene

Checklist:
- APP_ENV-based env loading
- client-safe env policy enforced
- forbidden server keys blocked from bundled env

Definition of done:
- env verification script passes for all active env files

### Workstream C: Firebase Baseline

Checklist:
- Android and iOS app registration aligned with package/bundle ids
- real platform config files placed in repo (except secrets)
- flutterfire options regenerated

Definition of done:
- Firebase initializes successfully on supported targets

### Workstream D: Appwrite Baseline

Checklist:
- runtime Appwrite config validation
- client factory available for account/database/storage/tables
- booking flow can read/write against dev schema

Definition of done:
- app can read service data and submit booking rows in dev

### Workstream E: Engineering Operations

Checklist:
- CI workflow for lint/test/readiness checks
- branch strategy documented (main, develop, feature/*)
- release-signing prerequisites documented

Definition of done:
- pull request quality gates run on all critical branches

## Technical Acceptance Criteria

1. App boots and navigates without runtime crashes.
2. `flutter analyze` returns no issues.
3. baseline test suite passes.
4. env verifier passes for development and production files.
5. store readiness audit runs in CI.

## KPI and Gate Thresholds

1. Build health: 100 percent successful CI on active branch.
2. Setup reproducibility: fresh setup under 30 minutes.
3. Blocking defects: zero P0 and zero unresolved P1 in setup pathways.

## Risks and Mitigations

1. Misconfigured app ids across Firebase and mobile targets.
Mitigation: enforce one identity source in setup docs and verify via configure command.

2. Secret leakage into Flutter env assets.
Mitigation: enforce verify_env in CI and pre-commit workflow.

3. Inconsistent local developer setup.
Mitigation: keep setup commands deterministic and scripted.

## Exit Criteria

Phase 0 exits when:
1. foundation architecture is wired and stable.
2. Firebase and Appwrite baselines are operational in dev.
3. CI gates are active and passing.
4. setup and recovery docs are complete and current.
