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
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Payments | Paystack (GH₵ / Mobile Money / Cards) |
| Notifications | Firebase Cloud Messaging + Africa's Talking SMS |
| Maps | Google Maps Flutter |
| Storage | Supabase Storage |

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
│   └── SPRINTS.md          # Sprint breakdown
└── supabase/
    └── migrations/         # Database migrations
```
