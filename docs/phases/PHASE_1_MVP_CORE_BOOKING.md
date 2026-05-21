# Phase 1 Playbook: MVP Core Booking Engine

Timeline: Week 3 to Week 12
Primary Goal: Deliver a reliable, monetizable booking journey for JP Style Lounge Studio.

## Business Outcomes

1. Customers can discover services and book appointments end-to-end.
2. Payments and confirmations work reliably.
3. Barber operations can manage schedule, bookings, and updates.

## Scope

In scope:
- auth and identity flows
- service catalog and barber profile
- availability and booking wizard
- payments and confirmation
- notification and cancellation handling
- dashboard and core analytics

Out of scope:
- marketplace onboarding for multiple external barbers
- loyalty/referral economics

## Hybrid Model Execution

### Discovery Track

Tasks:
- validate booking funnel UX with real users
- validate male/female/unisex service segmentation and role mapping
- define policy and pricing edge cases

Deliverables:
- approved service taxonomy and booking states
- final acceptance criteria per sprint

### Delivery Track

Tasks:
- build vertical slices from auth to booking completion
- add observability around funnel drop-off and failures
- harden reliability with automated tests

Deliverables:
- release candidate MVP build
- operational runbook for support and rollback

## MVP Capability Map

### Capability 1: Identity and Access

Includes:
- customer sign-in pathways
- role mapping (customer, barber, admin)
- session persistence and renewal

Quality gates:
- no unauthorized data access
- reliable session restoration after restart

### Capability 2: Service Discovery

Includes:
- profile and catalog views
- service details and add-ons
- audience segmentation (male, female, unisex)
- professional role capture (barber, hairdresser)

Quality gates:
- service metadata consistency
- graceful fallback for missing media/data

### Capability 3: Booking and Availability

Includes:
- slot generation and locking
- booking wizard with validation
- booking state machine

Quality gates:
- no double-booking under concurrency scenarios
- deterministic booking validation rules

### Capability 4: Payments and Confirmations

Includes:
- checkout initiation
- payment status reconciliation
- confirmation and receipt pathways

Quality gates:
- idempotent payment handling
- zero silent payment failures

### Capability 5: Notifications and Policy Events

Includes:
- push and SMS fallbacks
- reminder jobs
- cancellation/no-show policy execution

Quality gates:
- event delivery retries
- clear user-visible error messaging

### Capability 6: Barber Operations

Includes:
- day schedule and booking management
- state overrides with audit trail
- core business dashboards

Quality gates:
- data consistency between customer and barber views
- role-based authorization enforced

## Engineering Standards

1. every feature behind test coverage appropriate to risk.
2. all booking and payment writes are traceable.
3. all critical backend operations are idempotent.
4. all user-visible failures have actionable recovery guidance.

## Test Strategy

1. Unit tests for mapping, validation, and state transitions.
2. Widget tests for booking wizard and role/audience UX.
3. Integration tests for booking, payment callback, and notification triggers.
4. Regression suite required before release candidate promotion.

## KPI Targets

1. booking completion rate >= 85 percent in pilot.
2. payment success rate >= 95 percent for valid attempts.
3. no-show reduction >= 20 percent after reminder flows activate.
4. crash-free sessions >= 99.5 percent.

## Exit Criteria

Phase 1 exits when:
1. booking from service selection to confirmation is production-stable.
2. payment and policy flows are verified and auditable.
3. notification pathways are reliable with fallback behavior.
4. P0 defects are zero and P1 defects are triaged with owners and dates.
