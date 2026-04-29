# JP Style Lounge Studio — Sprint Breakdown

**Phase 1 MVP | 12-Week Plan | Target Launch: Q1 2026**

> Each sprint is 1 week unless noted. Estimated hours are for a solo full-stack Flutter developer.

---

## Sprint Overview

| Sprint | Focus Area | Week | Est. Hours |
|--------|-----------|------|-----------|
| 0 | Foundation & Setup | 1–2 | 20h |
| 1 | Authentication & Roles | 3–4 | 25h |
| 2 | Barber Profile + Service Catalog | 4–5 | 20h |
| 3 | Availability & Calendar Engine | 5–6 | 25h |
| 4 | 5-Step Booking Wizard | 6–8 | 35h |
| 5 | Paystack Payment Integration | 7–8 | 20h |
| 6 | Notifications (Push + SMS) | 8–9 | 20h |
| 7 | Cancellation, No-Show & Refunds | 9 | 15h |
| 8 | Reviews & Social Proof | 10 | 15h |
| 9 | Barber Dashboard & Analytics | 10–11 | 25h |
| 10 | Polish, QA & Launch Prep | 11–12 | 20h |

**Total estimated: ~220 hours over 12 weeks**

---

## Sprint 0 — Foundation & Setup `Week 1–2` `~20h`

### Goals
Working Flutter app that connects to Supabase dev instance with all migrations applied.

### Tasks

#### Flutter Scaffold `~6h`
- [ ] `flutter create jp_style_lounge_studio --org app.jpstyleloungestudio`
- [ ] Setup `lib/` structure:
  ```
  lib/
  ├── core/
  │   ├── supabase/       # client, config
  │   ├── router/         # go_router setup
  │   └── theme/          # Material 3 theme tokens
  ├── features/
  │   ├── auth/
  │   ├── booking/
  │   ├── profile/
  │   ├── dashboard/
  │   └── notifications/
  └── shared/
      ├── widgets/
      └── utils/
  ```
- [ ] Add all dependencies to `pubspec.yaml`
- [ ] Configure `flutter_dotenv` with `.env` (gitignored)
- [ ] Add app icons (Android + iOS) using `flutter_launcher_icons`
- [ ] Add splash screen using `flutter_native_splash`

#### Supabase Setup `~4h`
- [ ] Create Supabase project (dev instance)
- [ ] Apply `001_initial_schema.sql`
- [ ] Seed the initial barber record in the backend with a route-resolvable slug
- [ ] Seed 5 services with prices in GH₵
- [ ] Seed Mon–Sat 9AM–7PM recurring availability
- [ ] Verify RLS policies via Supabase table editor

#### External Services `~4h`
- [ ] Paystack sandbox account + test API keys
- [ ] Firebase project created → download `google-services.json` + `GoogleService-Info.plist`
- [ ] Africa's Talking sandbox account + test credentials
- [ ] Google Maps API key (restricted to bundle ID)
- [ ] Store all keys in `.env`

#### Dev Tooling `~3h`
- [ ] Git repo init with `main` / `develop` / `feature/*` strategy
- [ ] `.gitignore` includes `.env`, `*.keystore`, build artefacts
- [ ] Add `analysis_options.yaml` (strict linting)
- [ ] GitHub Actions workflow: `flutter analyze` + `flutter test` on PR
- [ ] README badge: CI status

#### Verification `~3h`
- [ ] App boots on Android emulator without errors
- [ ] Supabase client connects (basic query runs)
- [ ] Auth test: create a user via Supabase dashboard, query from app
- [ ] `flutter test` passes (at least 1 smoke test)

### Done When
> App boots, DB connected, test user created, all external API keys stored.

---

## Sprint 1 — Authentication & User Roles `Week 3–4` `~25h`

### Goals
Any customer can sign up/in. Paps James can log in as barber and be routed to his dashboard.

### Tasks

#### Auth Flows `~10h`
- [ ] Splash screen with Supabase session check → redirect
- [ ] **Phone OTP Flow:**
  - Phone input screen (Ghana +233 format validation)
  - OTP verification screen (6-digit, 60s resend timer)
  - Supabase `signInWithOtp(phone: ...)`
- [ ] **Email + Password Flow:**
  - Login screen
  - Registration screen (name, email, password)
- [ ] **Google Sign-In:**
  - `google_sign_in` + Supabase OAuth
  - Handle account linking (same email, different provider)
- [ ] **Guest Mode:**
  - "Continue as guest" button on auth screen
  - Guest state stored locally; prompt account creation after booking confirmed
- [ ] Barber login: email + password only (no phone OTP for barber in Phase 1)
- [ ] Barber 2FA: TOTP prompt after login (Supabase MFA)

#### Role-Based Routing `~5h`
- [ ] On auth success: query `users.role`
- [ ] `customer` → `HomeScreen`
- [ ] `barber` → `BarberDashboardScreen`
- [ ] `admin` → `AdminScreen` (placeholder for Phase 3)
- [ ] `go_router` redirect guard: unauthenticated → `/login`
- [ ] `AuthNotifier` (Riverpod): exposes `User?`, `isLoading`, `error`

#### Multi-Tenant Wiring `~3h`
- [ ] Replace static barber config with an active-barber resolver fed by route, auth, or backend context
- [ ] All customer queries: `.eq('barber_id', BarberConfig.barberId)`
- [ ] RLS sanity test: customer A cannot read customer B's bookings (write a test)

#### User Profile Creation `~4h`
- [ ] On first login: if no `users` row exists → insert with `role = 'customer'`
- [ ] Profile completion screen (name, phone if not from OTP)
- [ ] `UserRepository` with `getUser()`, `updateProfile()`

#### Screens to Build `~3h`
- [ ] `SplashScreen` (logo + session check)
- [ ] `OnboardingScreen` (3-slide carousel, skip button)
- [ ] `LoginScreen` (tabs: Phone / Email / Google)
- [ ] `OtpScreen`
- [ ] `RegisterScreen`
- [ ] `ProfileSetupScreen`

### Done When
> Paps James logs in, sees dashboard. New customer signs up via OTP, lands on home. Guest can proceed to home without login.

---

## Sprint 2 — Barber Profile & Service Catalog `Week 4–5` `~20h`

### Goals
Customer sees Paps James's full profile and can browse/select services.

### Tasks

#### Barber Profile Screen `~8h`
- [ ] Fetch barber data from `barbers` using the resolved route slug or tenant context
- [ ] Hero banner (`CachedNetworkImage`, fade-in)
- [ ] Avatar + display name + location badge
- [ ] Bio text (collapsible if long)
- [ ] Google Maps widget: static map + "Get Directions" button (deep link)
- [ ] Contact row: WhatsApp icon → `wa.me/233XXXXXXXXX`; Instagram icon → profile URL
- [ ] Average rating badge (query from `reviews`)
- [ ] Portfolio gallery: horizontal scroll, tap to full-screen lightbox
- [ ] "Book Now" prominent CTA button → booking wizard

#### Service Catalog `~8h`
- [ ] `ServicesRepository`: fetch from `services` where `barber_id = ?` and `is_active = true`
- [ ] Services grid (2-column): photo card, name, price GH₵, duration badge
- [ ] Service detail bottom sheet:
  - Larger image, full description
  - Add-ons list with checkboxes (from `service_addons`)
  - Live total calculation as add-ons toggled
  - "Select This Service" → pass to booking wizard
- [ ] `ServiceNotifier` (Riverpod): selected service + add-ons + total
- [ ] Cache services to Hive for offline access

#### Offline Support `~2h`
- [ ] Hive box for services cache
- [ ] `ServicesRepository.getServices()` → try network, fall back to cache
- [ ] "Offline mode" subtle banner when using cached data

#### Screens `~2h`
- [ ] `HomeScreen` (barber profile as home)
- [ ] `ServicesScreen` (full list if scrolled beyond profile)
- [ ] `ServiceDetailSheet` (bottom sheet)

### Done When
> Customer can view Paps James's profile, browse all services, select service + add-ons, see live price total.

---

## Sprint 3 — Availability & Calendar Engine `Week 5–6` `~25h`

### Goals
Real-time slot availability system with no double-bookings possible.

### Tasks

#### Supabase Slot Logic `~10h`
- [ ] DB function: `get_available_slots(barber_id, date)` returns TIME[] of available slots
  - Query `availability` for recurring schedule on `day_of_week`
  - Exclude one-off `blocked` date entries
  - Exclude already-booked slots (with buffer)
  - Account for service duration + buffer (slot taken = slot_time to slot_time + duration + buffer_mins)
- [ ] Validate: slot is not in the past
- [ ] Validate: slot is within barber's working hours
- [ ] Unique constraint on `bookings(barber_id, slot_date, slot_time)` (already in schema)

#### Real-Time Subscription `~4h`
- [ ] Supabase Realtime channel: subscribe to `bookings` INSERT on `barber_id = ?` for selected date
- [ ] On new booking → refetch available slots for that date
- [ ] Show "Slot just taken" snackbar if currently-selected slot becomes unavailable
- [ ] `AvailabilityNotifier` (Riverpod): manages stream subscription lifecycle

#### Calendar UI `~8h`
- [ ] `table_calendar` integration on booking step 2
- [ ] Mark days as available (dot indicator), blocked (X), or fully booked
- [ ] Day tap → load slots for that day
- [ ] Slots list: scrollable time chips (09:00, 09:45, 10:30 …)
  - Available: green outline chip
  - Past: greyed out, disabled
  - Selected: filled green chip, checkmark
- [ ] Today / This Week / Next Week quick-filter tabs above calendar
- [ ] Loading skeleton while slots fetch

#### Barber Calendar Panel `~3h`
- [ ] Barber dashboard: full month view (`table_calendar`)
- [ ] Tap day → see list of bookings for that day
- [ ] Long press / "+ Block" FAB → block time form (date range + reason)
- [ ] Block saved to `availability` as `status = 'blocked'`
- [ ] Blocked days shown in red on barber calendar

### Done When
> Customer picks a date, sees only real available slots. Two users cannot book same slot. Barber can block days.

---

## Sprint 4 — 5-Step Booking Wizard `Week 6–8` `~35h`

### Goals
Complete end-to-end booking wizard from service to confirmation (payment wired in Sprint 5).

### Tasks

#### Wizard Shell `~3h`
- [ ] `BookingWizardScreen` with step indicator (1–5)
- [ ] `BookingNotifier` (Riverpod): all wizard state (`service`, `addons`, `date`, `time`, `notes`, `photo`, `paymentRef`)
- [ ] Back navigation preserves state
- [ ] "X" exits with confirmation dialog ("Lose your progress?")

#### Step 1 — Service Selection `~5h`
- [ ] Pre-populate from `HomeScreen` service selection if navigated from "Book Now"
- [ ] Re-selectable grid for changing service choice
- [ ] Add-on checkboxes with live total
- [ ] Duration display updated live
- [ ] "Next" enabled only when service selected

#### Step 2 — Date & Time Picker `~6h`
- [ ] Calendar component (from Sprint 3)
- [ ] Slot list filtered to service duration (slots where duration fits before end of day)
- [ ] Real-time subscription active on this step
- [ ] "Next" enabled only when date + time selected

#### Step 3 — Booking Details `~6h`
- [ ] Client name field (pre-filled from `auth.user.name`)
- [ ] Phone field (pre-filled from `auth.user.phone`; editable)
- [ ] Notes `TextFormField` with 200-character limit
- [ ] Photo upload: `image_picker` → compress → upload to Supabase Storage → store URL in state
- [ ] Booking summary card (service name, date, time, total)
- [ ] "Next" enabled when name + phone filled

#### Step 4 — Payment `~8h` *(stub in Sprint 4, full in Sprint 5)*
- [ ] Payment summary card (service total + add-ons + optional tip)
- [ ] Tip selector chips (GH₵10 / GH₵20 / GH₵50 / No tip)
- [ ] Deposit vs full payment toggle (based on `barber_settings.deposit_percent`)
- [ ] "Pay Now" button → launches Paystack (wired in Sprint 5; stub with mock success for now)
- [ ] Loading overlay while processing

#### Step 5 — Confirmation `~7h`
- [ ] Lottie animation on success
- [ ] Booking summary (service, date, time, barber, paid amount)
- [ ] "Add to Calendar" → generate `.ics` and share via `share_plus` / Google Calendar intent
- [ ] "Share Booking" → WhatsApp deeplink with booking detail text
- [ ] Deep link: navigate to `jpstyleloungestudio.app/book/{booking_id}`
- [ ] "Back to Home" button

#### Booking Persistence `~5h`
- [ ] On wizard completion (payment confirmed): INSERT to `bookings` + `booking_addons`
- [ ] Atomic: wrap in DB transaction — slot check + insert in one operation
- [ ] Handle duplicate (slot taken between steps): show "Slot Taken" error → back to Step 2
- [ ] `BookingRepository.createBooking()`

### Done When
> Customer completes all 5 wizard steps, booking appears in DB. Paystack step is stubbed (mock success).

---

## Sprint 5 — Paystack Payment Integration `Week 7–8` `~20h`

### Goals
Real payments via Paystack Mobile Money and card. Webhooks update booking status.

### Tasks

#### Paystack Checkout `~6h`
- [ ] Initialise Paystack transaction via API (call from Edge Function to avoid exposing secret key)
- [ ] Launch Paystack popup / redirect with `access_code`
- [ ] Handle callback: `paystack_flutter` callback or redirect URL parse
- [ ] Success → proceed to Step 5 confirmation
- [ ] Failure → show retry option, clear payment state

#### Edge Function: Transaction Init `~4h`
- [ ] `POST /paystack-init` Edge Function:
  - Receives: `bookingId`, `amount`, `email`, `phone`, `callbackUrl`
  - Calls Paystack `POST /transaction/initialize`
  - Returns `access_code` + `reference` to app
- [ ] Store `payment_ref` in `bookings` table before redirect

#### Edge Function: Webhook Handler `~5h`
- [ ] `POST /paystack-webhook` Edge Function:
  - Verify `x-paystack-signature` HMAC-SHA512
  - On `charge.success`: update `payments.status = 'success'`, `bookings.deposit_paid = true`, `bookings.status = 'confirmed'`
  - On `refund.processed`: update `payments.status = 'refunded'`
- [ ] Idempotency: check if reference already processed before updating

#### Refund Flow `~3h`
- [ ] Edge Function `process-refund`: calls Paystack `POST /refund` with `transaction` reference
- [ ] Triggered by cancellation within policy window (Sprint 7)
- [ ] Update `payments.status = 'refunded'`

#### Testing `~2h`
- [ ] Paystack sandbox: test MTN Mobile Money flow end-to-end
- [ ] Test card payment with Paystack test cards
- [ ] Simulate webhook locally with ngrok / Supabase test webhook

### Done When
> Real money (sandbox) flows through. Booking confirmed in DB after successful payment. Webhook updates status.

---

## Sprint 6 — Notifications `Week 8–9` `~20h`

### Goals
Push and SMS notifications working for all key booking events.

### Tasks

#### FCM Setup `~5h`
- [ ] `firebase_messaging` package configured (Android + iOS)
- [ ] Request permission on first app launch (iOS)
- [ ] Foreground message handler (show in-app banner)
- [ ] Background / terminated message handler (open relevant screen on tap)
- [ ] Save FCM token to `users.fcm_token` on each login
- [ ] Token refresh listener (update DB when token rotates)

#### Edge Function: Send Notification `~5h`
- [ ] `send-notification` Edge Function:
  - Input: `userId`, `title`, `body`, `data` (deep link)
  - Look up `users.fcm_token`
  - Call FCM HTTP v1 API
  - If no FCM token OR FCM returns `UNREGISTERED`: fall back to Africa's Talking SMS
- [ ] Africa's Talking SMS fallback implementation

#### Notification Triggers `~5h`
Wire the following to `send-notification`:
- [ ] Booking created → confirmation push to customer + Paps James
- [ ] Booking cancelled → push to customer + Paps James
- [ ] Booking updated → push to customer
- [ ] No-show risk → push to Paps James (30 min post-slot)

#### Scheduled Reminders (pg_cron) `~4h`
- [ ] `pg_cron` extension enabled on Supabase
- [ ] Job: every 15 minutes, find bookings where `slot_date + slot_time = NOW() + 24h` → call `send-notification`
- [ ] Job: every 15 minutes, find bookings where `slot_date + slot_time = NOW() + 1h` → call `send-notification`
- [ ] Prevent duplicate reminders: `notifications_sent` JSONB column on `bookings` (flags `['24h', '1h']`)

#### In-App Notification Center `~1h` *(optional MVP)*
- [ ] `notifications` table: log all sent notifications
- [ ] Notification bell icon in app bar with unread badge
- [ ] List screen with mark-as-read

### Done When
> Book a test appointment → customer + Paps James both receive push immediately. 24h later a reminder fires.

---

## Sprint 7 — Cancellation, No-Show & Refunds `Week 9` `~15h`

### Tasks

#### Client Cancellation `~6h`
- [ ] "Cancel Booking" option in booking detail screen
- [ ] Policy check: `slot_date + slot_time - NOW() > cancel_window_hours` → allow cancel
- [ ] Late cancel: show warning ("Deposit will not be refunded")
- [ ] Cancellation reason picker
- [ ] On confirm: `bookings.status = 'cancelled'`; if within policy → trigger `process-refund`
- [ ] Send cancellation notification to Paps James

#### No-Show Detection `~4h`
- [ ] pg_cron job: every 15 minutes
  - Find `confirmed` bookings where `slot_date + slot_time + 30min < NOW()` and status ≠ `completed`/`cancelled`
  - Update status → `no_show`
  - Do NOT trigger Paystack refund (deposit retained)
  - Send no-show push to Paps James

#### Barber Overrides `~3h`
- [ ] Barber dashboard: per-booking actions:
  - "Mark Completed" → `status = 'completed'`; trigger review prompt
  - "Mark No-Show" → `status = 'no_show'`
  - "Issue Refund" → trigger `process-refund` regardless of policy
- [ ] Bulk cancel: select multiple bookings → cancel all (e.g., Paps James sick day)

#### Refund Processing `~2h`
- [ ] Verify `process-refund` Edge Function (from Sprint 5) handles full vs partial refund
- [ ] Test: cancel within window → refund appears in Paystack dashboard

### Done When
> Valid cancellation triggers refund. No-show auto-detected, deposit retained. Paps James can override any status.

---

## Sprint 8 — Reviews & Social Proof `Week 10` `~15h`

### Tasks

#### Review Collection `~6h`
- [ ] pg_cron job: 1h after `bookings.status = 'completed'` → send review prompt push
- [ ] Deep link from push → `ReviewScreen` for that `booking_id`
- [ ] `ReviewScreen`:
  - Star tap (1–5)
  - Optional comment `TextField`
  - Optional photo upload (Supabase Storage)
  - Submit → INSERT to `reviews`
- [ ] One review per booking: handle duplicate insert gracefully

#### Public Display `~5h`
- [ ] Home screen widget: average rating (computed from `reviews`) + count
- [ ] Latest 5 reviews scrollable list: name, stars, date, comment, optional photo
- [ ] Full reviews screen (paginated, 20 per page)
- [ ] Empty state: "Be the first to leave a review!"

#### Barber Dashboard Reviews `~4h`
- [ ] Review summary card: avg rating + rating distribution bar chart
- [ ] Review list with filter by rating / date
- [ ] Reply to review placeholder (Phase 2 feature flag)
- [ ] Flag abusive review: sets `reviews.flagged = true` (admin reviews queue)

### Done When
> After completing a booking, review prompt fires. Review appears on home screen. Paps James sees rating in dashboard.

---

## Sprint 9 — Barber Dashboard & Analytics `Week 10–11` `~25h`

### Tasks

#### Revenue Dashboard `~8h`
- [ ] `RevenueRepository`: aggregate queries on `payments` table
- [ ] Period selector: Today / This Week / This Month
- [ ] Total earnings display (GH₵)
- [ ] Service breakdown bar chart (`fl_chart`): earnings per service
- [ ] No-show deposit collected (separate line)
- [ ] Pending payout balance (total confirmed payments not yet transferred)
- [ ] Share / export: build PDF summary, share via `share_plus`

#### Booking Management `~7h`
- [ ] Today's appointments list (chronological, auto-refresh)
- [ ] Upcoming / Past / Cancelled tabs
- [ ] Booking card: client name, service, time, status badge, payment icon
- [ ] Booking detail screen:
  - Client info (name, phone, WhatsApp quick-dial)
  - Service + add-ons + notes
  - Reference photo thumbnail (full-screen on tap)
  - Payment status
  - Status action buttons (Complete / No-Show / Cancel)
- [ ] Search by client name / phone

#### Schedule Management `~5h`
- [ ] Weekly schedule editor: toggle each day on/off, set open/close times
- [ ] Save → update `availability` recurring rows
- [ ] One-off block form: date range picker + optional reason
- [ ] Buffer time setting in `barber_settings`

#### Profile & Settings `~5h`
- [ ] Edit bio + contact links + location pin
- [ ] Upload / reorder portfolio photos (drag-to-reorder)
- [ ] Service management:
  - Add new service form
  - Edit service (name, price, duration, image, add-ons)
  - Archive service (soft delete: `is_active = false`)
- [ ] Payment settings (deposit %, tip options)
- [ ] Cancellation window (hours)
- [ ] Notification preferences (which alerts enabled)

### Done When
> Paps James sees today's bookings, revenue summary, can edit his schedule and services from the dashboard.

---

## Sprint 10 — Polish, QA & Launch Prep `Week 11–12` `~20h`

### Tasks

#### Edge Cases & Reliability `~5h`
- [ ] Concurrent slot booking race condition test (simulate 2 users, same slot, same second)
- [ ] Booking wizard: back navigation doesn't re-submit
- [ ] Network failure on payment step: retry flow, no duplicate charge
- [ ] FCM token refresh handled without crash
- [ ] Supabase session expiry: silent token refresh, no logout surprise

#### UI Polish `~5h`
- [ ] Consistent spacing / typography via `ThemeData`
- [ ] All loading states use skeleton screens (`shimmer` package)
- [ ] Empty states: friendly illustrations + CTAs
- [ ] Micro-animations: slot select pulse (AnimatedContainer), booking success Lottie
- [ ] Haptic: `HapticFeedback.mediumImpact()` on slot select, booking confirm
- [ ] Dark mode: all screens tested in dark theme

#### Testing `~5h`
- [ ] Widget tests: booking wizard step 1–5 navigation
- [ ] Widget test: slot conflict error shows on step 2
- [ ] Integration test: full booking flow on emulator (`integration_test` package)
- [ ] Paystack sandbox end-to-end (real test card)
- [ ] Notification delivery test (FCM test message via Firebase console)
- [ ] RLS test: try to access another user's booking via raw Supabase call

#### Launch Checklist `~5h`
- [ ] Create Supabase production project
- [ ] Migrate schema + seed Paps James data in production
- [ ] Set production environment variables in Flutter + Edge Functions
- [ ] Enable Paystack live keys (after Paps James completes business verification)
- [ ] Google Play Internal Testing track upload (APK signed with release keystore)
- [ ] Apple TestFlight submission (requires Apple Developer account)
- [ ] Sentry error tracking wired (`sentry_flutter`)
- [ ] Supabase alerts configured (DB size, Edge Function errors)
- [ ] Paps James user admin walkthrough (Loom recording)
- [ ] Soft launch: 5 friends/family beta test first week

### Done When
> Signed APK running in TestFlight / Play Internal. Real booking + payment completes in production environment. Paps James has been onboarded.

---

## Phase 1 Launch Gate Checklist

Before declaring Phase 1 **DONE**, all must pass:

- [ ] Customer books → pays via MTN Mobile Money (live Paystack)
- [ ] Paps James receives push notification within 5 seconds
- [ ] 24h and 1h reminders fire correctly
- [ ] Cancellation within 4h window → Paystack refund issued
- [ ] No-show → deposit retained, no refund
- [ ] Simultaneous slot booking → exactly 1 succeeds
- [ ] Paps James blocks a day → no slots visible to customers
- [ ] Review appears on home after completed appointment
- [ ] Revenue dashboard shows correct totals
- [ ] App shows cached data offline (no crash)
- [ ] Zero crash reports in first 48h of soft launch

---

## Phase 2 Sprint Planning (Preview) `Month 4–6`

*Detailed sprint breakdown to be created at end of Phase 1.*

| Sprint | Feature | Estimated |
|--------|---------|-----------|
| P2-1 | Loyalty points system (earn + redeem) | 3 weeks |
| P2-2 | Waitlist + rebooking shortcut | 2 weeks |
| P2-3 | Promotional codes + referral links | 2 weeks |
| P2-4 | Client profiles (Paps James view) | 1 week |
| P2-5 | Advanced analytics (cohort, heatmap) | 2 weeks |

---

*See [ROADMAP.md](../ROADMAP.md) for phase-level overview.*  
*See [docs/PRD.md](PRD.md) for acceptance criteria.*
