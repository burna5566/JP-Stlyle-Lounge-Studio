# JP Style Lounge Studio — Product Requirements Document

**Version:** 1.0  
**Date:** March 2026  
**Author:** Paps James  
**Status:** Active — Phase 1 MVP

---

## 1. Executive Summary

JP Style Lounge Studio is a mobile-first barber booking platform, launching for **Paps James** in Accra, Ghana. It replaces phone-based scheduling with 24/7 self-service booking, Paystack payments, automated reminders, and a real-time availability calendar. The database schema is designed multi-tenant from day one, enabling a future SaaS marketplace of barbers across Ghana.

---

## 2. Problem Statement

| Pain Point | Current Reality | JP Style Lounge Studio Solution |
|-----------|----------------|------------------|
| Scheduling friction | Phone calls/WhatsApp DMs | 24/7 self-service app booking |
| No-shows | No deposit enforcement | Paystack deposit + auto-charge |
| Double-booking | Manual calendar (error-prone) | Real-time slot locking |
| Payment collection | Cash only / informal | Paystack: MoMo, cards, bank |
| Reminder failures | Manual WhatsApp reminders | Automated FCM + SMS |
| Social proof | No centralised reviews | In-app star ratings + photos |

---

## 3. Goals & Success Metrics

### Business Goals
- Eliminate phone-based scheduling for Paps James entirely
- Generate consistent revenue through Paystack-secured deposits
- Build a client base for future multi-barber expansion

### Key Performance Indicators

| KPI | Target | Timeframe |
|-----|--------|-----------|
| Booking completion rate | ≥ 90% | Ongoing |
| No-show rate | ≤ 5% | 3 months post-launch |
| Monthly bookings | 50+ | 3 months post-launch |
| Average client rating | ≥ 4.5 stars | Ongoing |
| Double-bookings | 0 | At all times |
| Push notification open rate | ≥ 40% | 3 months post-launch |

---

## 4. User Roles & Personas

### 4.1 Customer

**Profile:** Accra resident, 18–45 years old, mobile-first, predominantly Android, uses MTN/Vodafone Mobile Money.

**Goals:**
- Book a slot at a time that suits them without calling
- Know exactly what they're paying before they arrive
- Receive a reminder so they don't forget
- Rate their experience easily

**Key Actions:**
1. Browse services and prices
2. Pick available date/time
3. Pay deposit via Mobile Money
4. Receive confirmation + reminders
5. Rate appointment post-visit

---

### 4.2 Barber (Paps James)

**Profile:** Solo operator, Accra. Manages his own schedule. Needs full visibility into upcoming bookings, revenue, and client notes.

**Goals:**
- See today's and upcoming appointments at a glance
- Block time off easily (sick days, holidays)
- Receive instant alerts for new bookings and cancellations
- Track revenue without a spreadsheet

**Key Actions:**
1. View daily/weekly schedule
2. Block availability
3. View client details and special notes before appointment
4. Mark bookings completed / no-show
5. Review earnings and payouts

---

### 4.3 Platform Admin (Future)

**Profile:** Paps James or a business partner overseeing multiple barbers on the platform.

**Key Actions:**
1. Onboard/approve new barbers
2. Monitor platform-wide bookings and revenue
3. Configure commission rates
4. Handle escalated disputes

---

## 5. Functional Requirements

### 5.1 Authentication & Onboarding

| Requirement | Priority | Notes |
|------------|---------|-------|
| Phone OTP login (+233 format) | Must Have | Primary Ghana-friendly method |
| Email + password login | Must Have | Secondary method |
| Google Sign-In | Should Have | One-tap convenience |
| Apple Sign-In | Should Have | Required for iOS App Store |
| Guest booking (no account) | Must Have | Maximum conversion |
| Barber login (email + 2FA) | Must Have | Admin security |
| Role-based routing (customer/barber) | Must Have | Separate navigation trees |
| Session persistence | Must Have | Stay logged in across restarts |
| Multi-tenant: `barber_id` on all records | Must Have | Foundation for scaling |

---

### 5.2 Barber Profile

| Requirement | Priority | Notes |
|------------|---------|-------|
| Hero banner + professional photo | Must Have | First impression |
| Bio text | Must Have | Trust signal |
| Accra location (Google Maps pin) | Must Have | Directions |
| Portfolio gallery (10+ photos) | Must Have | Social proof |
| WhatsApp deep link | Should Have | Fallback contact |
| Instagram link | Should Have | Brand discovery |
| Average star rating badge | Must Have | Conversion signal |
| Service catalog grid | Must Have | Price transparency |

---

### 5.3 Service Catalog

| Requirement | Priority | Notes |
|------------|---------|-------|
| Service name, price (GH₵), duration (mins) | Must Have | Core data |
| Service description + sample images | Should Have | Informed choice |
| Add-ons (checkbox, incremental price) | Must Have | Upsell |
| Dynamic price total as add-ons selected | Must Have | Clarity |
| Barber can add/edit/archive services | Must Have | Dashboard admin |

**Sample Initial Services (Paps James)**

| Service | Price | Duration |
|---------|-------|---------|
| Skin Fade | GH₵ 80 | 45 min |
| Low Cut | GH₵ 60 | 30 min |
| Beard Trim | GH₵ 50 | 20 min |
| Hair Design / Carving | GH₵ 100 | 60 min |
| Full Package (Cut + Beard) | GH₵ 120 | 60 min |

---

### 5.4 Availability & Calendar System

| Requirement | Priority | Notes |
|------------|---------|-------|
| Recurring weekly schedule (Mon–Sat 9AM–7PM) | Must Have | Default schedule |
| Manual time blocks (vacation, breaks) | Must Have | Flexibility |
| 15-min buffer between bookings | Must Have | Prevent back-to-back stress |
| Real-time slot calculation | Must Have | No stale data |
| Weekly + monthly calendar views | Must Have | Customer UX |
| Color-coded availability | Must Have | At-a-glance clarity |
| No double-booking prevention (atomic lock) | Must Have | Zero tolerance |
| Barber can set custom hours per day | Should Have | Phase 1 nice-to-have |

**Colour Coding**

| Colour | Status |
|--------|--------|
| Green | Available |
| Blue | Booked |
| Red/Grey | Blocked or past |

---

### 5.5 Customer Booking Flow (5-Step Wizard)

#### Step 1 — Service Selection
- Service grid with photos, names, prices
- Add-on checkboxes with live price total
- Duration displayed and calculated

#### Step 2 — Date & Time Picker
- Available slots only (real-time from Supabase)
- Tabs: Today / This Week / Next Week
- Daily list view: 9AM–7PM slots
- Real-time update if slot taken while browsing

#### Step 3 — Booking Details
- Client name (pre-filled from auth)
- Phone number (pre-filled, editable)
- Special notes free text ("Low skin fade + lightning bolt")
- Photo reference upload (optional)
- Booking summary card

#### Step 4 — Payment
- Full payment OR deposit (Paps James configures %)
- Paystack checkout: Mobile Money, Card, Bank Transfer
- Optional tip: GH₵10 / GH₵20 / GH₵50 / Skip
- Loading overlay during payment

#### Step 5 — Confirmation
- Lottie success animation
- Full booking summary
- Add to Google Calendar / download `.ics`
- Share via WhatsApp / Instagram

---

### 5.6 Notifications

#### Push Notifications (Firebase Cloud Messaging)

| Trigger | Recipient | Timing |
|---------|-----------|--------|
| Booking confirmed | Customer | Immediate |
| Booking confirmed | Paps James | Immediate |
| 24-hour reminder | Customer | 24h before slot |
| 1-hour reminder | Customer | 1h before slot |
| Cancellation | Customer + Paps James | Immediate |
| Booking updated | Customer | Immediate |
| No-show risk | Paps James | 15 min after slot start |
| New review posted | Paps James | Immediate |

#### SMS Fallback (Africa's Talking)

| Trigger | Condition |
|---------|-----------|
| Booking confirmed | No FCM token (guest user) |
| Payment receipt | All users |
| Cancellation | No FCM token |

---

### 5.7 Cancellation & No-Show Policy

| Rule | Default | Configurable |
|------|---------|-------------|
| Client cancellation window | 4 hours before slot | ✅ Yes (barber sets) |
| Late cancellation penalty | Deposit forfeited | ✅ Yes |
| No-show detection | 30 min after slot start | — |
| No-show charge | Deposit auto-retained | ✅ Yes |
| Barber refund override | Full barber control | — |
| Paystack refund | Triggered on valid cancel | — |

---

### 5.8 Reviews & Social Proof

| Requirement | Priority |
|------------|---------|
| Post-appointment push → review prompt | Must Have |
| 1–5 star rating | Must Have |
| Optional text comment | Should Have |
| Optional photo upload | Should Have |
| One review per booking (enforced) | Must Have |
| Home screen: average + 5 latest reviews | Must Have |
| Barber dashboard: review analytics | Should Have |
| All-reviews paginated screen | Should Have |

---

### 5.9 Revenue & Payments Dashboard

| Requirement | Priority |
|------------|---------|
| Daily / weekly / monthly totals | Must Have |
| Service breakdown chart | Should Have |
| No-show deposit collected | Must Have |
| Pending payout balance | Must Have |
| Per-booking payment status | Must Have |
| Export earnings report | Should Have |

---

## 6. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | Booking flow completes in <2 seconds end-to-end |
| Real-Time | Slot availability updates within 1 second of a booking |
| Offline | Services and profile accessible without internet |
| Offline Queue | Failed bookings retry automatically on reconnect |
| Security | HTTPS everywhere; Paystack PCI DSS compliance; Supabase RLS isolation |
| Scalability | Handle 100 concurrent bookings; support 10,000+ users |
| Reliability | 99.9% uptime target; SMS fallback if push fails |
| Accessibility | Ghana English locale; 48dp minimum tap targets |
| Privacy | No raw card data stored; Paystack tokenisation only |

---

## 7. UI / UX Requirements

### Design Principles
- **Mobile-first:** Every screen designed for one-handed phone use
- **Thumb-friendly:** Primary CTAs in lower 60% of screen
- **Fast to book:** Minimum taps from home to confirmation
- **Ghana-native feel:** Local currency, local lingo, local payment methods

### Visual Identity
| Element | Spec |
|---------|------|
| Primary green | `#006B3F` (Ghana flag green) |
| Accent yellow | `#FCD116` (Ghana flag yellow) |
| Dark base | `#000000` / `#1A1A1A` |
| Typography | Inter or Poppins (system fallback) |
| Component system | Flutter Material 3 |

### Key UX Requirements
- Micro-animations on slot selection, booking confirmation
- Skeleton loading screens (no blank states)
- Shareable deep links: `jpstyleloungestudio.app/paps-james`
- Haptic feedback on key interactions (iOS + Android)
- Dark mode support

---

## 8. Multi-Tenant Architecture Constraints (Phase 1)

> These constraints ensure Phase 1 code is directly upgradeable to multi-barber without rewriting.

| Constraint | Implementation |
|-----------|---------------|
| All DB tables include `barber_id` | Schema enforced from migration 001 |
| Customer app resolves the active barber from route or tenant context | No barber picker UI in Phase 1 |
| Barber dashboard auto-filters to `auth.uid()` | Via Supabase RLS |
| Paystack account mapped to `barber_id` | `barber_paystack_accounts` table |
| RLS policies on all tables | Applied in `001_initial_schema.sql` |
| Slug system ready | `barbers.slug` supports public profile routes |

---

## 9. Out of Scope (Phase 1)

The following are explicitly **not** included in Phase 1 MVP:

- Multi-barber discovery or onboarding
- Loyalty / points system
- Waitlist for fully-booked slots
- Promotional codes
- Referral system
- Web app (barber dashboard is mobile only in Phase 1)
- Product sales / e-commerce
- Platform commission / SaaS billing
- International expansion

---

## 10. Acceptance Criteria (Phase 1 Launch Gate)

Before Phase 1 is considered complete, all of the following must pass:

- [ ] A new user can create an account via phone OTP in under 60 seconds
- [ ] A user can complete a full booking (service → slot → payment) in under 3 minutes
- [ ] Paystack Mobile Money payment processes and booking is confirmed
- [ ] Paps James receives a push notification within 5 seconds of a new booking
- [ ] 24h and 1h reminders fire correctly for a test booking
- [ ] A cancelled booking within policy triggers a Paystack refund
- [ ] A no-show triggers deposit retention (no refund issued)
- [ ] Two users attempting to book the same slot simultaneously result in exactly one confirmed booking
- [ ] Paps James can block a day off and no slots appear for that day
- [ ] Reviews appear on the home screen after a completed appointment
- [ ] Revenue dashboard shows correct totals matching Paystack transactions
- [ ] App functions in offline mode (services viewable without internet)

---

*Last updated: March 2026*
