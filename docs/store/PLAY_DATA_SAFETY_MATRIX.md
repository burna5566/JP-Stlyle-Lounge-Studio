# Google Play Data Safety Matrix

Status: Draft baseline for JP Style Lounge Studio
Last updated: 2026-04-30

## Data Collection and Sharing Baseline

| Data Type | Collected | Shared | Purpose | Notes |
|---|---|---|---|---|
| Name | Yes | No | Account management, booking identity | User profile fields |
| Phone number | Yes | No | Auth, booking contact, reminders | Required for customer workflow |
| Email | Optional | No | Account recovery, receipts | Depends on auth method |
| Photos/Media (uploads) | Optional | No | Reference photos, reviews | User-initiated uploads only |
| Device tokens (FCM) | Yes | No | Push notifications | Stored to deliver reminders |
| Approx/precise location | Optional | No | Barber location and maps | Prompt only when feature used |
| Payment metadata | Yes | No | Booking payment state | No raw card data in app/backend |

## SDK Surface to Confirm Before Declaration

- Firebase Core / Firebase Messaging
- Appwrite Flutter SDK
- Google Maps Flutter
- Image Picker
- Geolocator
- Paystack client SDK

## Verification Checklist

- [ ] Confirm each SDK runtime data behavior in release build.
- [ ] Verify all optional collections are user-triggered.
- [ ] Match declarations in Play Console exactly.
- [ ] Re-verify after SDK upgrades.
