# JP Style Lounge Studio — Technical Architecture

**Version:** 1.0  
**Stack:** Flutter + Supabase + Paystack + Firebase

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                              │
│                                                             │
│   ┌──────────────────┐        ┌──────────────────┐         │
│   │  Customer App     │        │  Barber Dashboard │         │
│   │  (Flutter Mobile) │        │  (Flutter Mobile) │         │
│   └────────┬─────────┘        └────────┬──────────┘         │
│            │                           │                     │
└────────────┼───────────────────────────┼─────────────────────┘
             │  HTTPS / WSS              │  HTTPS / WSS
┌────────────┼───────────────────────────┼─────────────────────┐
│                    BACKEND LAYER                             │
│            │                           │                     │
│   ┌────────▼───────────────────────────▼──────────┐         │
│   │              Supabase                          │         │
│   │                                                │         │
│   │  ┌─────────────┐  ┌──────────┐  ┌──────────┐ │         │
│   │  │  PostgreSQL  │  │   Auth   │  │ Realtime │ │         │
│   │  │  (RLS + MT)  │  │ (JWT)    │  │ (WS PubSub)│ │       │
│   │  └─────────────┘  └──────────┘  └──────────┘ │         │
│   │                                                │         │
│   │  ┌─────────────┐  ┌──────────┐                │         │
│   │  │   Storage   │  │  Edge    │                │         │
│   │  │  (S3-compat) │  │Functions │                │         │
│   │  └─────────────┘  └──────────┘                │         │
│   └────────────────────────────────────────────────┘         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
             │                  │                │
             ▼                  ▼                ▼
      ┌──────────┐       ┌──────────┐    ┌──────────────┐
      │ Paystack │       │ Firebase │    │Africa's Talking│
      │ Payments │       │   FCM    │    │   SMS (Ghana) │
      └──────────┘       └──────────┘    └──────────────┘
             │
             ▼
      ┌──────────┐
      │  Google  │
      │   Maps   │
      └──────────┘
```

---

## Technology Stack

### Frontend — Flutter

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | Flutter 3.x | Single codebase iOS + Android; strong community; Dart null-safety |
| State Management | Riverpod 2.x | Compile-safe, testable, no boilerplate |
| Navigation | go_router | Deep link support (`jpstyleloungestudio.app/paps-james`); declarative routing |
| UI Components | Material 3 | Modern, accessible, customisable |
| HTTP Client | Supabase Flutter SDK | Auto-manages auth headers; realtime built-in |
| Local Storage | Hive / Isar | Fast offline cache for services and profile |

**Key Flutter Packages**

| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Backend, auth, realtime |
| `riverpod` + `flutter_riverpod` | State management |
| `go_router` | Navigation + deep links |
| `paystack_flutter` | Payment checkout |
| `firebase_messaging` | Push notifications |
| `google_maps_flutter` | Maps + location pin |
| `table_calendar` | Calendar widget |
| `fl_chart` | Revenue charts |
| `image_picker` | Photo reference uploads |
| `lottie` | Success animations |
| `flutter_dotenv` | Environment variables |
| `hive` | Offline caching |
| `share_plus` | WhatsApp / social sharing |

---

### Backend — Supabase

| Feature | Usage |
|---------|-------|
| **PostgreSQL** | Primary database; all app data |
| **Auth** | Phone OTP, email/password, Google OAuth |
| **Row Level Security** | Multi-tenant data isolation per `barber_id` |
| **Realtime** | Live slot availability updates via WebSocket |
| **Storage** | Portfolio photos, service images, review photos, reference uploads |
| **Edge Functions** | Paystack webhook handler; notification scheduler; no-show detector |
| **pg_cron** | Scheduled notification triggers (24h and 1h reminders) |

---

### Payments — Paystack

| Feature | Implementation |
|---------|---------------|
| Currency | GH₵ (Ghanaian Cedi) |
| Channels | Mobile Money (MTN, Vodafone, AirtelTigo), Card, Bank Transfer |
| Deposit model | Configurable % via `barber_settings.deposit_percent` |
| No-show charge | Retain deposit (no refund triggered) |
| Refunds | API call from Edge Function on valid cancellation |
| Webhooks | Edge Function verifies signature, updates `bookings.payment_status` |
| Card storage | None — Paystack tokenisation only, no raw card data in DB |
| Payouts | Direct to Paps James's Paystack account (manual Phase 1, automated Phase 3) |

---

### Notifications

#### Firebase Cloud Messaging (Push)

| Component | Detail |
|-----------|--------|
| Token storage | `users.fcm_token` in DB, refreshed on login |
| Triggering | Supabase Edge Function calls FCM HTTP v1 API |
| Scheduling | pg_cron jobs for 24h/1h reminders |
| Topics | `barber-{barber_id}` topic for barber alerts |

#### Africa's Talking (SMS)

| Component | Detail |
|-----------|--------|
| Use case | Guest users without FCM token; push delivery failures |
| Sender ID | `JPSTYLE` (alphanumeric, requires AT approval) |
| Number format | +233 XX XXX XXXX |
| Triggering | Same Edge Function as push; fallback path |

---

### Maps — Google Maps Flutter

| Usage | Detail |
|-------|--------|
| Barber location pin | Static marker on profile screen |
| Directions | Deep link to Google Maps with barbershop coords |
| API key restriction | Restrict to bundle ID / package name |

---

## Database Schema

### Entity Relationship Diagram

```
barbers ─────────── services
   │                   │
   │           service_addons
   │
   ├─── availability
   │
   └─── bookings ──── booking_addons
           │
           ├─── payments
           │
           └─── reviews
```

### Tables

#### `barbers`
```sql
id            UUID PK
user_id       UUID FK → auth.users
slug          TEXT UNIQUE  -- 'pap-james', 'james'
display_name  TEXT
bio           TEXT
location_lat  DECIMAL
location_lng  DECIMAL
location_name TEXT
whatsapp      VARCHAR
instagram     VARCHAR
banner_url    TEXT
avatar_url    TEXT
created_at    TIMESTAMPTZ
```

#### `users`
```sql
id          UUID PK  -- mirrors auth.users.id
barber_id   UUID FK → barbers (NULL for customers)
role        TEXT CHECK IN ('customer','barber','admin')
phone       VARCHAR UNIQUE
name        VARCHAR
email       VARCHAR UNIQUE
fcm_token   TEXT
created_at  TIMESTAMPTZ
updated_at  TIMESTAMPTZ
```

#### `services`
```sql
id          UUID PK
barber_id   UUID FK → barbers NOT NULL
name        VARCHAR           -- 'Skin Fade'
price       DECIMAL(10,2)     -- 80.00
duration    INTEGER           -- 45 (minutes)
description TEXT
image_url   TEXT
is_active   BOOLEAN DEFAULT TRUE
sort_order  INTEGER
created_at  TIMESTAMPTZ
```

#### `service_addons`
```sql
id          UUID PK
service_id  UUID FK → services
name        VARCHAR     -- 'Beard Trim'
price       DECIMAL     -- 50.00
duration    INTEGER     -- 20
```

#### `availability`
```sql
id          UUID PK
barber_id   UUID FK → barbers NOT NULL
day_of_week INTEGER     -- 0=Sun, 1=Mon … 6=Sat (recurring)
date        DATE        -- NULL for recurring; set for one-off blocks
start_time  TIME
end_time    TIME
status      TEXT CHECK IN ('available','blocked')
created_at  TIMESTAMPTZ
```

#### `bookings`
```sql
id              UUID PK
barber_id       UUID FK → barbers NOT NULL
customer_id     UUID FK → users
service_id      UUID FK → services
slot_date       DATE NOT NULL
slot_time       TIME NOT NULL
duration        INTEGER        -- total including add-ons
status          TEXT CHECK IN ('pending','confirmed','completed','cancelled','no_show')
special_notes   TEXT
reference_photo TEXT           -- Supabase Storage URL
total_amount    DECIMAL(10,2)
deposit_amount  DECIMAL(10,2)
deposit_paid    BOOLEAN DEFAULT FALSE
payment_ref     TEXT           -- Paystack reference
created_at      TIMESTAMPTZ
updated_at      TIMESTAMPTZ

UNIQUE (barber_id, slot_date, slot_time)  -- prevent double-booking
```

#### `booking_addons`
```sql
id          UUID PK
booking_id  UUID FK → bookings
addon_id    UUID FK → service_addons
price       DECIMAL    -- snapshot at time of booking
```

#### `payments`
```sql
id              UUID PK
booking_id      UUID FK → bookings
paystack_ref    TEXT UNIQUE
amount          DECIMAL(10,2)
currency        TEXT DEFAULT 'GHS'
channel         TEXT     -- 'mobile_money','card','bank'
status          TEXT CHECK IN ('pending','success','failed','refunded')
tip_amount      DECIMAL(10,2) DEFAULT 0
created_at      TIMESTAMPTZ
```

#### `reviews`
```sql
id          UUID PK
booking_id  UUID UNIQUE FK → bookings    -- one review per booking
barber_id   UUID FK → barbers
rating      INTEGER CHECK (rating BETWEEN 1 AND 5)
comment     TEXT
photo_url   TEXT
created_at  TIMESTAMPTZ
```

#### `barber_settings`
```sql
barber_id           UUID PK FK → barbers
deposit_percent     INTEGER DEFAULT 50  -- 0 = full payment required
cancel_window_hours INTEGER DEFAULT 4
buffer_mins         INTEGER DEFAULT 15
currency            TEXT DEFAULT 'GHS'
tip_options         JSONB   -- [10, 20, 50]
updated_at          TIMESTAMPTZ
```

---

### Row Level Security Policies

```sql
-- Customers see only their own bookings
CREATE POLICY "customers_own_bookings" ON bookings
  FOR ALL USING (customer_id = auth.uid());

-- Barbers see all bookings for their barber_id
CREATE POLICY "barbers_own_bookings" ON bookings
  FOR ALL USING (
    barber_id IN (
      SELECT id FROM barbers WHERE user_id = auth.uid()
    )
  );

-- Services are readable by anyone (public catalog)
CREATE POLICY "services_public_read" ON services
  FOR SELECT USING (is_active = TRUE);

-- Only barber can modify their services
CREATE POLICY "barbers_manage_services" ON services
  FOR ALL USING (
    barber_id IN (
      SELECT id FROM barbers WHERE user_id = auth.uid()
    )
  );

-- Reviews: public read, customer owns insert for their booking
CREATE POLICY "reviews_public_read" ON reviews
  FOR SELECT USING (TRUE);

CREATE POLICY "customers_insert_review" ON reviews
  FOR INSERT WITH CHECK (
    booking_id IN (
      SELECT id FROM bookings WHERE customer_id = auth.uid()
    )
  );
```

---

## Edge Functions

| Function | Trigger | Responsibility |
|----------|---------|---------------|
| `paystack-webhook` | HTTP POST (Paystack) | Verify HMAC signature; update payment + booking status |
| `send-notification` | DB trigger / HTTP | Send FCM push; fallback to Africa's Talking SMS |
| `schedule-reminders` | pg_cron (every 15 min) | Find bookings 24h/1h away; enqueue notifications |
| `detect-noshow` | pg_cron (every 15 min) | Flag unconfirmed bookings 30 min past slot time |
| `process-refund` | HTTP (internal) | Call Paystack refund API on valid cancellation |

---

## Security Considerations

| Concern | Mitigation |
|---------|-----------|
| SQL injection | Supabase parameterised queries; never raw SQL with user input |
| IDOR on bookings | RLS policies isolate all customer data by `auth.uid()` |
| Paystack webhook spoofing | HMAC-SHA512 signature verification in Edge Function |
| FCM token theft | Tokens scoped to device; rotated on each login |
| Card data storage | Zero — Paystack handles all PCI scope |
| XSS (web dashboard future) | Supabase SDK escapes all output; CSP headers |
| Rate limiting | Supabase built-in rate limiting on auth endpoints |
| Secret management | All API keys in Supabase Edge Function secrets (never in app bundle) |
| Sensitive env vars | `.env` gitignored; production secrets via CI secrets |

---

## Performance Targets

| Operation | Target |
|-----------|--------|
| App cold start | <2 seconds |
| Slot availability load | <500ms |
| Booking submission | <2 seconds end-to-end |
| Real-time slot update propagation | <1 second |
| Image load (portfolio) | <1 second (cached) |
| Paystack payment redirect | Paystack-controlled; ~3–5 seconds |

---

## Deployment & Environments

| Environment | Supabase Project | Purpose |
|------------|-----------------|---------|
| `dev` | jp-style-lounge-studio-dev | Local development |
| `staging` | jp-style-lounge-studio-staging | QA + Paps James testing |
| `production` | jp-style-lounge-studio-prod | Live client bookings |

**Flutter build flavours:**
- `--dart-define=ENVIRONMENT=dev`
- `--dart-define=ENVIRONMENT=staging`
- `--dart-define=ENVIRONMENT=production`

---

*See [docs/PRD.md](PRD.md) for product requirements.*  
*See [ROADMAP.md](../ROADMAP.md) for implementation timeline.*
