# Appwrite Phase 0 Bootstrap Toolkit

This folder contains setup scripts that support Phase 0 execution.

## Script: bootstrap_phase0.dart

Purpose:
- Seed baseline barber profile
- Seed starter service catalog (male, female, unisex)
- Seed recurring availability for Monday to Saturday

### Required Environment Variables

Option A: set these in your shell before running:

```bash
export APPWRITE_ENDPOINT="https://cloud.appwrite.io/v1"
export APPWRITE_PROJECT_ID="your-project-id"
export APPWRITE_JWT="server-jwt-with-row-write-permissions"
export APPWRITE_DATABASE_ID="jp_style_lounge_dev"

# Optional (defaults shown)
export APPWRITE_BARBERS_COLLECTION_ID="barbers"
export APPWRITE_SERVICES_COLLECTION_ID="services"
export APPWRITE_AVAILABILITY_COLLECTION_ID="availability"
```

Option B: create a local secret file at `.appwrite.secrets` in the project root.
This file is gitignored and can hold only server-side values such as:

```bash
APPWRITE_API_KEY=your-server-api-key
```

The scripts will read that file automatically if present.

### Run

```bash
dart run tool/appwrite/bootstrap_phase0.dart
```

### Safety Notes

1. Never put `APPWRITE_API_KEY` in `.env.development` or `.env.production`.
2. Never put `APPWRITE_JWT` in `.env.development` or `.env.production`.
3. Use a local shell export or the gitignored `.appwrite.secrets` file.
4. Script is idempotent for seeded row IDs and will skip rows that already exist.

---

## Script: migrate_add_payment_fields.dart

Purpose:
- Add `payment_ref` field (text, nullable) to bookings collection
- Add `deposit_paid` field (boolean, default false) to bookings collection
- Idempotent: skips if fields already exist

Run this **once** after Phase 0 bootstrap, before deploying the Paystack webhook function.

### Required Environment Variables

Same as bootstrap_phase0.dart:

Option A: shell export
```bash
export APPWRITE_ENDPOINT="https://nyc.cloud.appwrite.io/v1"
export APPWRITE_PROJECT_ID="69f37cd7001ed21d6938"
export APPWRITE_API_KEY="your-server-api-key-from-.appwrite.secrets"
export APPWRITE_DATABASE_ID="69f3860300063c6fba4d"
export APPWRITE_BOOKINGS_COLLECTION_ID="bookings"
```

Option B: `.appwrite.secrets` (recommended)
```bash
# Already set via .appwrite.secrets in project root
```

### Run

```bash
dart run tool/appwrite/migrate_add_payment_fields.dart
```

### What It Does

1. Connects to your Appwrite project
2. Fetches the bookings collection schema
3. Checks if `payment_ref` exists; adds it if missing (text, 255 chars, optional)
4. Checks if `deposit_paid` exists; adds it if missing (boolean, default: false)
5. Reports success or existing fields

### After Migration

Your Paystack webhook function can now:
- Store `payment_ref` (Paystack transaction reference) in bookings
- Set `deposit_paid = true` when `charge.success` webhook arrives
- Update `status = 'confirmed'` atomically with deposit confirmation
