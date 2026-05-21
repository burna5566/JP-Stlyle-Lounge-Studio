# Hybrid Development Model Playbook

Status: Active execution model
Owner: Product + Engineering + QA
Scope: All phases (0 through 4)

## Why Hybrid Model

This project uses a hybrid model to balance planning discipline with sprint adaptability:
- Stage gates protect quality and business readiness.
- Agile sprints accelerate delivery and feedback.
- Discovery and delivery run in parallel to reduce waste.

## Operating Principles

1. Product intent first, implementation second.
2. Every feature maps to measurable business value.
3. Architecture evolves through controlled increments.
4. Each phase has explicit entry/exit criteria.
5. No phase exits with unresolved P0 defects.

## Core Framework

### Track A: Discovery and Validation

Activities:
- problem framing
- UX flows and wireframes
- acceptance criteria and edge-case mapping
- technical spikes and feasibility checks
- compliance and store policy checks

Outputs:
- refined backlog
- validated user flows
- implementation brief for sprint execution

### Track B: Delivery and Hardening

Activities:
- implementation in vertical slices
- automated tests and regression coverage
- telemetry and observability
- CI quality gates and release artifacts

Outputs:
- production-ready increments
- release notes and deployment runbooks

## Stage Gates (By the Book)

### Gate 0: Plan Approved
Required:
- PRD slice defined
- architecture impact reviewed
- risks logged
- dependencies identified

### Gate 1: Build Complete
Required:
- code merged with review
- tests implemented
- feature flags and fallback behavior in place where needed

### Gate 2: Quality Validated
Required:
- lint and static checks clean
- unit/widget/integration tests pass
- performance sanity checks pass
- security checks pass for touched areas

### Gate 3: Release Ready
Required:
- documentation updated
- telemetry dashboards updated
- rollback strategy prepared
- stakeholder sign-off complete

## Sprint Cadence

Weekly cadence:
- Day 1: planning and design lock
- Day 2-4: development and QA pairing
- Day 5: demo, retro, and next sprint pre-brief

Daily cadence:
- standup with blockers and risk update
- PR review SLA: same day

## Work Item Standard

Every ticket must include:
- user story
- acceptance criteria
- test strategy
- observability requirement
- rollout and fallback plan

## Quality Baseline

Mandatory checks before merge:
- flutter analyze
- dart format
- test suite pass
- env safety check
- store readiness audit (strict on release branches)

## Governance

Roles:
- Product Owner: backlog priority and acceptance
- Tech Lead: architecture and code quality ownership
- QA Lead: test strategy and risk sign-off
- Release Owner: deployment and rollback control

## Change Management

Major scope changes require:
- impact summary
- updated timeline
- updated risk register
- approval from Product and Tech leads

## Definition of Phase Success

A phase succeeds only when:
- all phase exit criteria are met
- KPIs hit minimum thresholds
- unresolved risks are accepted with owners and due dates
