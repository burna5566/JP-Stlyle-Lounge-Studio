# Appwrite Backend Plan

This project targets Appwrite. The Flutter app should
only receive client-safe values from `.env.development` and `.env.production`.
Appwrite API keys, Paystack secrets, webhook secrets, and SMS provider secrets
belong in Appwrite Functions, CI secrets, or local setup files that are never
bundled into Flutter.

## Project

| Environment | Project ID | Database ID |
|-------------|------------|-------------|
| Development | `nyc-69f37cd7001ed21d6938` | `jp_style_lounge_dev` |
| Production | Configure before launch | `jp_style_lounge_prod` |

## Collections

| Collection ID | Purpose |
|---------------|---------|
| `users` | Customer, barber, and admin profile data linked to Appwrite Auth users |
| `barbers` | Barber profile, public slug, location, contact, hero media |
| `services` | Service catalog scoped by `barber_id` |
| `service_addons` | Optional add-ons scoped by service |
| `availability` | Recurring hours and manual blocks |
| `bookings` | Booking records, slot lock fields, payment state |
| `booking_addons` | Add-on price snapshots for each booking |
| `payments` | Paystack transaction metadata and status |
| `reviews` | Post-appointment ratings and photos |
| `barber_settings` | Deposit, cancellation, buffer, currency, and tip settings |

## Storage Buckets

| Bucket ID | Purpose |
|-----------|---------|
| `portfolio` | Barber portfolio/gallery images |
| `reference_photos` | Customer-uploaded haircut references |
| `service_images` | Service catalog photos |
| `review_photos` | Review photos |

## Immediate Build Order

1. Create the database and collections in Appwrite.
2. Add collection attributes and indexes for booking lookups and slot locking.
3. Configure collection permissions around Appwrite Auth roles/teams.
4. Move payment webhooks, SMS sending, and privileged writes into Appwrite Functions.
5. Add the Flutter Appwrite SDK and a small client factory that reads from `Env`.
