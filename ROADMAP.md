# JP Style Lounge Studio Project Roadmap

**Solo Barber Booking App — Paps James, Accra**  
*Multi-Tenant SaaS Foundation | Target MVP Launch: Q1 2026*

---

## Roadmap at a Glance

```
Phase 0  │  Foundation & Setup         │  Week 1–2
Phase 1  │  MVP — Core Booking Engine  │  Week 3–12  (primary sprint)
Phase 2  │  Growth & Retention         │  Month 4–6
Phase 3  │  Multi-Barber Platform       │  Month 7–12
Phase 4  │  Marketplace & Monetisation │  Month 12+
```

---

## Phase 0 — Foundation & Setup `Week 1–2`

Goal: Zero to running local environment with DB, auth, and CI structure in place.

### Milestones
- [ ] Flutter project scaffolded and running on device/emulator
- [ ] Supabase project created, `.env` wired, local CLI working
- [ ] Paystack sandbox account and test keys configured
- [ ] Firebase project created (FCM enabled)
- [ ] Africa's Talking sandbox account ready
- [ ] All migrations applied to Supabase dev instance
- [ ] Git repository structured with branch strategy defined

### Tasks

**Project Scaffold**
- [ ] `flutter create jp_style_lounge_studio --org app.jpstyleloungestudio`
- [ ] Add core dependencies to `pubspec.yaml`:
  - `supabase_flutter`, `go_router`, `riverpod`, `flutter_stripe` (or paystack_flutter)
  - `firebase_messaging`, `google_maps_flutter`, `image_picker`
  - `intl`, `table_calendar`, `fl_chart`
- [ ] Setup `lib/` folder structure (`features/`, `core/`, `shared/`)
- [ ] Configure `.env` & `flutter_dotenv`
- [ ] Add iOS/Android app icons and splash screen (Paps James's brand)

**Backend & Database**
- [ ] Apply `001_initial_schema.sql` migration
- [ ] Seed the initial barber profile in the backend data store
- [ ] Seed initial service catalog (prices in GH₵)
- [ ] Seed recurring availability (Mon–Sat 9AM–7PM)
- [ ] Verify all RLS policies active and tested

**Dev Environment**
- [ ] Define Git branching: `main` → `develop` → `feature/*`
- [ ] Setup linting (`flutter analyze`, `dart format`)
- [ ] Add CI basics (GitHub Actions: lint + test on PR)

### Exit Criteria
> Database seeded, app boots on emulator, Supabase client connects, auth test user created.

---

## Phase 1 — MVP Core Booking Engine `Week 3–12`

Goal: A fully working booking app Paps James can use with real clients in Accra.

### Sprint 1 — Authentication & User Roles `Week 3–4`

**Customer Auth**
- [ ] Phone OTP login via Supabase Auth (Ghana +233 format)
- [ ] Email + password login
- [ ] Google Sign-In (`google_sign_in` package)
- [ ] Guest booking mode (skip login, prompt account creation post-booking)
- [ ] Persist session across app restarts

**Barber Auth**
- [ ] Barber login screen (email + password)
- [ ] 2FA prompt for barber role
- [ ] Role detection on login → route to correct home (customer vs barber dashboard)
- [ ] Auth state management via Riverpod `AuthNotifier`

**Multi-Tenant Wiring**
- [ ] Customer app resolves the active barber from route or tenant context in all queries
- [ ] Supabase RLS: customers see only their own bookings
- [ ] Supabase RLS: barber sees only bookings where `barber_id = auth.uid()`

**Screens**
- [ ] Splash / loading screen
- [ ] Onboarding carousel (3 slides: Book → Pay → Relax)
- [ ] Login screen (phone OTP primary, email/Google as options)
- [ ] OTP verification screen
- [ ] Account creation screen (name, optional email)

### Sprint 2 — Barber Profile & Service Catalog `Week 4–5`

**Barber Profile**
- [ ] Hero screen: banner photo, Paps James's name, Accra location badge
- [ ] Short bio section
- [ ] Google Maps widget pinned to barbershop location
- [ ] WhatsApp deep link button
- [ ] Instagram profile link button
- [ ] Portfolio gallery (horizontal scroll, 10+ photos from Supabase Storage)
- [ ] Average star rating + review count badge

**Service Catalog**
- [ ] Fetch services from `services` table filtered by the resolved active barber ID
- [ ] Grid view: photo, name, price (GH₵), duration (mins)
- [ ] Service detail bottom sheet: description, sample images, add-ons
- [ ] Add-on selection state (e.g., Beard Trim +GH₵50)
- [ ] "Book Now" CTA from service detail

**Screens**
- [ ] Home / Barber profile screen
- [ ] Full services list screen
- [ ] Service detail bottom sheet

### Sprint 3 — Availability & Calendar Engine `Week 5–6`

**Backend Logic**
- [ ] Supabase function / view: generate available time slots from `availability` table minus existing `bookings`
- [ ] 15-minute buffer time logic between bookings
- [ ] Recurring weekly schedule (Mon–Sat) vs manual block support
- [ ] Real-time subscription: slots update when new booking is created

**Calendar UI**
- [ ] Weekly calendar header (Today/This Week/Next Week tabs)
- [ ] Daily slot list (9AM–7PM in configurable step intervals)
- [ ] Color coding:
  - Green → available
  - Blue → booked
  - Red/Grey → blocked / past
- [ ] Month view (using `table_calendar`)
- [ ] Tap slot → proceed to booking wizard

**Barber Calendar (Admin)**
- [ ] Full calendar view of all bookings
- [ ] "Block time" action (add to `availability` as blocked)
- [ ] View booking detail on slot tap

### Sprint 4 — 5-Step Booking Wizard `Week 6–8`

**Step 1: Service Selection**
- [ ] Service grid (pre-populated if navigated from service card)
- [ ] Add-on checkboxes with live price total
- [ ] Duration calculation (base + add-on time)
- [ ] "Next" enabled only when service selected

**Step 2: Date & Time Picker**
- [ ] Date selector (calendar strip or full calendar)
- [ ] Time slot list for selected date (only available slots)
- [ ] Real-time update if slot taken while user is on screen
- [ ] "Next" enabled when slot selected

**Step 3: Booking Details**
- [ ] Client name (pre-filled from auth profile)
- [ ] Phone number (pre-filled, editable)
- [ ] Special notes text area ("Low skin fade + lightning bolt")
- [ ] Photo reference upload (optional, Supabase Storage)
- [ ] Summary card: service, date, time, price

**Step 4: Payment**
- [ ] Paystack checkout initialisation (booking total)
- [ ] Payment options: Mobile Money (MTN/Vodafone), Card, Bank Transfer
- [ ] Deposit mode toggle (configurable by barber — full or 50% deposit)
- [ ] Optional tip selector (GH₵10 / GH₵20 / GH₵50 / Skip)
- [ ] Loading overlay during payment processing
- [ ] Paystack webhook handler (Supabase Edge Function) → mark `deposit_paid`

**Step 5: Confirmation**
- [ ] Lottie success animation
- [ ] Booking summary: service, date, time, barber name, total paid
- [ ] `.ics` calendar file download / Add to Google Calendar
- [ ] Share via WhatsApp, Instagram Stories
- [ ] Deep link: `jpstyleloungestudio.app/book/[booking_id]`
- [ ] "Back to Home" CTA

**Booking State Management**
- [ ] `BookingNotifier` (Riverpod): holds wizard state across steps
- [ ] Prevent double-booking: Supabase unique constraint + client-side slot lock

### Sprint 5 — Notifications System `Week 8–9`

**Push Notifications (FCM)**
- [ ] Firebase project linked to Flutter app (iOS + Android)
- [ ] Request notification permission on onboarding
- [ ] Store FCM token in `users.fcm_token`
- [ ] Notification triggers (Supabase Edge Functions or pg_cron):
  - Booking confirmed → immediate push
  - 24h before appointment → scheduled push
  - 1h before appointment → scheduled push
  - Booking cancelled/updated → immediate push

**SMS Fallback (Africa's Talking)**
- [ ] Africa's Talking API integration in Edge Function
- [ ] SMS sent when:
  - User has no FCM token (non-app guest)
  - Push delivery fails
  - Payment confirmed (receipt)
- [ ] Ghana number formatting (+233)

**Barber Notifications**
- [ ] New booking alert (push + sound)
- [ ] Cancellation alert
- [ ] No-show risk alert (15 mins late → push to Paps James)

**Notification Center (In-App)**
- [ ] Notification history screen
- [ ] Mark as read
- [ ] Deep link from notification → relevant booking

### Sprint 6 — Cancellation, No-Show & Refunds `Week 9`

**Cancellation Policy**
- [ ] Client can cancel up to 4h before slot (configurable by barber)
- [ ] UI: cancellation reason selector + confirm dialog
- [ ] Update booking status → `cancelled`
- [ ] Paystack refund trigger (if within policy)
- [ ] Notification to barber on cancellation

**No-Show Handling**
- [ ] Auto-flag booking as `no_show` if not marked `completed` within 30 mins of slot time
- [ ] Auto-charge deposit from Paystack (retain deposit, don't refund)
- [ ] Barber can manually override: mark as `completed` or waive charge

**Barber Override**
- [ ] Barber dashboard: mark any booking as completed / cancelled / no-show
- [ ] Add manual discount or override price
- [ ] Bulk cancel (e.g., Paps James sick day)

### Sprint 7 — Reviews & Social Proof `Week 10`

**Post-Appointment Review Flow**
- [ ] Trigger: 1h after `slot_time` if status = `completed` → push notification
- [ ] Review screen: 1–5 star tap, optional comment, optional photo upload
- [ ] One review per booking (enforced by DB unique constraint)
- [ ] Review posted to `reviews` table, linked to `booking_id`

**Public Display**
- [ ] Home screen: average rating (stars) + total review count
- [ ] Latest 5 reviews scrollable list (name, stars, comment, photo thumbnail)
- [ ] All reviews screen (pagination)

**Barber Dashboard**
- [ ] Review summary widget (avg rating, trend chart)
- [ ] Filter reviews by rating / date
- [ ] Flag/report abusive review

### Sprint 8 — Barber Dashboard & Analytics `Week 10–11`

**Revenue Dashboard**
- [ ] Daily / weekly / monthly earnings totals
- [ ] Service breakdown bar chart (which service earns most)
- [ ] No-show deposit collected (separate line item)
- [ ] Pending payout balance
- [ ] Export to PDF / share

**Booking Management**
- [ ] Today's appointments list (chronological)
- [ ] Upcoming / past tabs
- [ ] Search / filter by client name
- [ ] Booking detail: client info, service, notes, photo reference, payment status

**Schedule Management**
- [ ] Weekly schedule editor (toggle days on/off, set hours)
- [ ] One-off block creation (drag on calendar or "+ Block" form)
- [ ] Buffer time setting (default 15 min, adjustable)

**Profile & Settings**
- [ ] Edit bio, contact links, location pin
- [ ] Upload/reorder portfolio photos
- [ ] Manage service catalog (add / edit / archive services)
- [ ] Payment settings (deposit %, tip options)
- [ ] Cancellation policy settings (window in hours)
- [ ] Notification preferences

### Sprint 9 — Polish, Edge Cases & Launch Prep `Week 11–12`

**Quality & Reliability**
- [ ] Offline mode: cache services + profile for no-internet viewing
- [ ] Retry queue: failed bookings re-attempt on reconnect
- [ ] Handle concurrent slot booking race condition (Supabase atomic transaction)
- [ ] Error boundaries + user-friendly error screens
- [ ] App-wide loading skeleton screens

**UI Polish**
- [ ] Consistent Ghana colour palette (green #006B3F, yellow #FCD116, black #000000)
- [ ] Micro-animations: slot select pulse, booking success Lottie
- [ ] Thumb-friendly tap targets (48dp minimum)
- [ ] Haptic feedback on key interactions
- [ ] Dark mode support

**Internationalisation**
- [ ] Ghana English locale
- [ ] GH₵ currency formatting throughout
- [ ] Ghana phone number input validation (+233)

**Testing**
- [ ] Widget tests for booking wizard steps
- [ ] Integration test: full booking flow (emulator)
- [ ] Payment sandbox end-to-end test
- [ ] Notification delivery test (FCM test message)

**Launch Prep**
- [ ] App Store Connect submission (iOS TestFlight)
- [ ] Google Play Internal Testing track
- [ ] Supabase production project (separate from dev)
- [ ] Production environment variables locked
- [ ] Paystack live keys enabled
- [ ] Monitoring: Supabase logs + Sentry error tracking
- [ ] Paps James onboarding: walkthrough video + admin doc

### Phase 1 Exit Criteria
> - Real client books, pays via Mobile Money, receives confirmation SMS
> - Paps James receives push notification and sees booking in dashboard
> - 24h reminder fires automatically
> - No double-bookings in 50-booking stress test

---

## Phase 2 — Growth & Retention `Month 4–6`

Goal: Reduce churn, increase repeat bookings, add marketing fuel.

### Features
- [ ] **Loyalty Points System** — Earn points per booking, redeem for discounts
- [ ] **Waitlist** — Join waitlist for fully-booked slots; auto-notify on cancellation
- [ ] **Rebooking Shortcut** — "Book same service again" from booking history
- [ ] **Client Profiles** — Paps James views client booking history, preferred services, notes
- [ ] **Advanced Analytics** — Cohort retention, peak hours heatmap, revenue forecast
- [ ] **Promotional Codes** — Paps James creates discount codes (%, fixed, one-time)
- [ ] **Referral System** — Share link → friend books → referrer earns credit
- [ ] **Rich Gallery** — Before/after photo pairs, video clips
- [ ] **Instagram Integration** — Auto-pull latest posts to portfolio section

### Phase 2 Milestone
> 50+ active monthly clients, 60%+ rebooking rate, loyalty program live.

---

## Phase 3 — Multi-Barber Platform `Month 7–12`

Goal: Onboard additional barbers, build discovery experience.

### Features
- [ ] **Barber Onboarding Flow** — Self-serve signup, profile creation, service setup
- [ ] **Barber Discovery Screen** — List/map of all barbers (filterable by location, service)
- [ ] **Individual Barber Booking Pages** — `jpstyleloungestudio.app/[barber-slug]`
- [ ] **Multi-Barber Calendar** — Shared availability view for shop owners
- [ ] **Barber Approval Workflow** — Admin reviews and approves new barber accounts
- [ ] **Barber Performance Dashboard** — Ratings, bookings, revenue per barber (admin view)
- [ ] **Payout Automation** — Scheduled Paystack payouts per barber, configurable split
- [ ] **Barbershop Teams** — Group barbers under a shop entity
- [ ] **Client Follows** — Follow favourite barbers, get notified of availability

### Phase 3 Milestone
> 5+ active barbers, discovery screen live, each barber managing their own schedule independently.

---

## Phase 4 — Marketplace & Monetisation `Month 12+`

Goal: Sustainable platform revenue model, become the top barber booking app in Ghana.

### Features
- [ ] **Platform Commission** — Configurable % fee on each booking via Paystack split
- [ ] **Subscription Tiers for Barbers** — Free (limited bookings) / Pro / Premium
- [ ] **Barber Boosts** — Paid placement in discovery listings
- [ ] **Product Sales** — Barbers sell hair care products via app
- [ ] **Gift Cards** — Purchasable, redeemable vouchers
- [ ] **B2B / Corporate Bookings** — Companies book sessions for employees
- [ ] **API Access** — Third-party integrations (POS, payroll systems)
- [ ] **Accra Expansion → National** — Kumasi, Cape Coast, Takoradi rollout
- [ ] **West Africa Expansion** — Nigeria (Paystack), Senegal, Côte d'Ivoire

### Phase 4 Milestone
> Platform generating recurring SaaS revenue, 50+ barbers, operating across 2+ cities.

---

## Milestone Summary

| Milestone | Target Date | Success Signal |
|-----------|-------------|----------------|
| Phase 0 Complete | Week 2 | App boots, DB connected |
| Auth Live | Week 4 | Paps James logs in, customer books as guest |
| Booking Flow Live | Week 8 | End-to-end booking + payment |
| MVP Launch | Week 12 | First real paid booking in production |
| 50 Monthly Bookings | Month 3 | Organic growth post-launch |
| Phase 2 Launch | Month 6 | Loyalty + waitlist active |
| Multi-Barber Beta | Month 9 | 3+ barbers onboarded |
| Platform Fees Live | Month 13 | First commission revenue |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Paystack Mobile Money delays | Medium | High | Test sandbox extensively; have card fallback |
| FCM push delivery failures in Ghana | Medium | Medium | SMS fallback via Africa's Talking |
| Double-booking race condition | Low | High | Supabase atomic slot-lock transaction |
| Client adoption resistance | Medium | High | WhatsApp share link; guest booking mode |
| Paps James availability for testing | Low | Medium | Weekly check-ins; async Loom feedback |
| App Store rejection | Low | Medium | Follow iOS HIG; no in-app currency workarounds |

---

## Dependencies & Accounts Needed

| Service | Purpose | Status |
|---------|---------|--------|
| Supabase | Backend, DB, Auth, Storage | Setup needed |
| Paystack | Payments (GH₵) | Account needed |
| Firebase | Push notifications | Setup needed |
| Africa's Talking | SMS (Ghana +233) | Account needed |
| Google Cloud | Maps API key | Key needed |
| Apple Developer | iOS distribution | Enrolment needed |
| Google Play | Android distribution | Account needed |

---

*See [docs/SPRINTS.md](docs/SPRINTS.md) for week-by-week task assignments.*  
*See [docs/PRD.md](docs/PRD.md) for full product requirements.*
