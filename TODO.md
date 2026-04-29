# JP Style Lounge Studio Project TODO

## Phase 1 MVP Deliverables

### 1. Project Setup
- [ ] Flutter project initialization (`flutter create jp_style_lounge_studio`)
- [ ] Supabase project setup and config
- [ ] Paystack account and API keys
- [ ] Firebase for notifications (or OneSignal)
- [ ] .env config for secrets
- [ ] Assets folder with barber photos/services images

### 2. Backend (Supabase)
- [ ] Database schema creation (users, services, availability, bookings, reviews)
- [ ] Row Level Security (RLS) policies for multi-tenant (resolved active barber context)
- [ ] Edge Functions for Paystack webhooks/notifications if needed

### 3. Authentication
- [ ] Supabase Auth: Phone OTP, Email/Password, Google Sign-In
- [ ] Role-based access (customer/barber)
- [ ] Guest booking flow

### 4. Barber Profile (Runtime-Loaded)
- [ ] Hero screen with bio, location (Google Maps), portfolio
- [ ] Service catalog screen (grid with images/prices)

### 5. Availability & Calendar
- [ ] Recurring schedule setup (Mon-Sat 9AM-7PM)
- [ ] Real-time slot availability (Supabase realtime)
- [ ] Block time UI for barber

### 6. Booking Flow (5-Step Wizard)
- [ ] Step 1: Service selection + add-ons
- [ ] Step 2: Date/time picker (available slots only)
- [ ] Step 3: Details/notes/photo upload
- [ ] Step 4: Paystack payment
- [ ] Step 5: Confirmation + .ics/share

### 7. Notifications
- [ ] Firebase Cloud Messaging setup
- [ ] SMS fallback (Africa's Talking)
- [ ] Automated reminders (24h, 1h)

### 8. Cancellation/No-Show
- [ ] Policy enforcement (4h cancel window)
- [ ] Auto-charge deposit for no-shows

### 9. Reviews
- [ ] Post-appointment rating/photo
- [ ] Display latest reviews on home

### 10. Barber Dashboard
- [ ] Revenue analytics
- [ ] Booking management
- [ ] Review moderation

### 11. Testing & Launch
- [ ] End-to-end testing
- [ ] App Store/Play Store submission
- [ ] Analytics integration

## Current Status
All items pending.

## Next Sprint
**Sprint 1: Project Setup + Database + Auth**
