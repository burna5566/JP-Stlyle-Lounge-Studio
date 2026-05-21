# JP Style Lounge Studio ✂️

> **Solo Barber Booking App — Paps James, Accra**  
> Mobile-first • 24/7 Self-Service • Multi-Tenant SaaS Foundation

---

## What is JP Style Lounge Studio?

JP Style Lounge Studio is a mobile booking platform built for Accra-based barbers, starting with **Paps James**. Clients book, pay, and receive automated reminders — all without a phone call. Built on a multi-tenant foundation ready to scale into a full barber marketplace.

---

## Quick Links

| Document | Description |
|----------|-------------|
| [ROADMAP.md](ROADMAP.md) | Phase-by-phase project roadmap with milestones |
| [docs/PRD.md](docs/PRD.md) | Full Product Requirements Document |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Tech stack & system architecture |
| [docs/SPRINTS.md](docs/SPRINTS.md) | Sprint-by-sprint task breakdown |
| [TODO.md](TODO.md) | Active task checklist |

---

## Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (iOS + Android) |
| Backend | Appwrite Cloud (Auth + Databases + Storage + Functions) |
| Payments | Paystack (GH₵ / Mobile Money / Cards) |
| Notifications | Firebase Cloud Messaging + Africa's Talking SMS |
| Maps | Google Maps Flutter |
| Storage | Appwrite Storage |

---

## Key Success Metrics

| Metric | Target |
|--------|--------|
| Booking completion rate | 90%+ |
| No-show rate | <5% |
| Monthly bookings (3 months post-launch) | 50+ |
| Average client rating | 4.5+ |
| Double-bookings | Zero |

---

## Phase Overview

```
Phase 0  →  Foundation & Setup              (Week 1–2)
Phase 1  →  MVP Launch                      (Week 3–12)
Phase 2  →  Growth Features                 (Month 4–6)
Phase 3  →  Multi-Barber Platform           (Month 7–12)
Phase 4  →  Marketplace & Monetisation      (Month 12+)
```

See [ROADMAP.md](ROADMAP.md) for full detail.

## Current Mode

- `APP_ENV=production`
- `FREE_MODE=false`
- `ENABLE_PAYMENTS=true`
- `ENABLE_PUSH_NOTIFICATIONS=true`
- `ENABLE_SMS_NOTIFICATIONS=true`
- `ENABLE_MAPS=true`

Use `.env.example` as the default production profile.

Environment files bundled into Flutter must contain client-safe values only.
Do not place Appwrite API keys, Paystack secret keys, webhook secrets, or SMS
provider secrets in `.env.development` or `.env.production`.

Run this check before commits to catch leaks or missing keys:

```bash
dart run tool/verify_env.dart
```

Run this readiness check before release work:

```bash
dart run tool/store_readiness_audit.dart
```

Android release signing setup:

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Fill real keystore values in `android/key.properties`.
3. Keep `android/key.properties` and keystore files out of git.

---

## Project Structure

```
JPStyleLoungeStudio/
├── README.md               # This file
├── ROADMAP.md              # Project phases & milestones
├── TODO.md                 # Active task checklist
├── docs/
│   ├── PRD.md              # Full product requirements
│   ├── ARCHITECTURE.md     # Tech stack & architecture
│   ├── SPRINTS.md          # Sprint breakdown
│   └── APPWRITE_BACKEND.md # Backend data model plan
├── lib/core/appwrite/
│   ├── appwrite_config.dart       # Runtime config contract + validation
│   ├── appwrite_client_factory.dart # Appwrite SDK client factory
│   └── runtime_guard.dart         # Boot-time config verification
└── tool/
    └── verify_env.dart     # Local environment safety checks
```
