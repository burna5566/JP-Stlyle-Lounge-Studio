# JP Style Lounge Studio Development Setup Guide

**Status:** Sprint 0 Complete ✅  
**Last Updated:** March 2026

---

## Prerequisites

Before starting, ensure you have these installed:

- **Flutter 3.16+** → [Install](https://flutter.dev/docs/get-started/install)
- **Dart 3.1+** → (included with Flutter)
- **Git** → [Install](https://git-scm.com/)
- **Android Studio** or **Xcode** (for emulator)
- **VS Code** Extensions:
  - Flutter
  - Dart
  - Supabase
  - GitHub Copilot (recommended)

---

## Step 1: Clone & Setup

```bash
cd /path/to/project
cd JPStyleLoungeStudio

# Install Flutter dependencies
flutter pub get

# Install code generators
flutter pub run build_runner build --delete-conflicting-outputs

# Verify setup
flutter doctor
```

**Expected Output:**
```
✓ Flutter
✓ Dart
✓ Android toolchain
✓ Xcode (macOS)
✓ VS Code
✓ Connected devices
```

---

## Step 2: Environment Configuration

### 2.1 Copy `.env` Template

```bash
cp .env.example .env
```

### 2.2 Fill in Production Credentials

Edit `.env` with your development credentials:

```env
# Core environment
APP_ENV=production
FREE_MODE=false

# Feature toggles (standard production)
ENABLE_PAYMENTS=true
ENABLE_PUSH_NOTIFICATIONS=true
ENABLE_SMS_NOTIFICATIONS=true
ENABLE_MAPS=true
MOCK_PAYMENT_SUCCESS=false

# Supabase Project
SUPABASE_URL=https://YOUR_DEV_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_DEV_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_DEV_SERVICE_ROLE_KEY

# Paystack (Live)
PAYSTACK_PUBLIC_KEY=pk_live_YOUR_PUBLIC_KEY
PAYSTACK_SECRET_KEY=sk_live_YOUR_SECRET_KEY
PAYSTACK_WEBHOOK_SECRET=whsec_YOUR_WEBHOOK_SECRET

# Firebase (Production)
FIREBASE_PROJECT_ID=jp-style-lounge-studio-prod

# Google Maps (Production)
GOOGLE_MAPS_API_KEY=YOUR_PROD_MAPS_KEY

# Africa's Talking (Production)
AFRICAS_TALKING_API_KEY=YOUR_PROD_AT_API_KEY
```

**Production default:** paid integrations are enabled and must be configured with live credentials before launch.

**Never commit `.env`!** It's in `.gitignore`.

---

## Step 3: Supabase Setup

### 3.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create new project → `jp-style-lounge-studio-dev`
3. Wait for DB initialization (~2 min)
4. Copy `Project URL` and `Anon Key` to `.env`

### 3.2 Apply Database Migration

```bash
# Option A: Via Supabase CLI (recommended)
supabase db push

# Option B: Via Supabase Dashboard
# - Go to SQL Editor
# - Create new query
# - Paste: supabase/migrations/001_initial_schema.sql
# - Run
```

### 3.3 Verify Schema

In Supabase Dashboard:
- Go to **Table Editor**
- Verify tables exist:
  - `barbers`, `users`, `services`, `bookings`, `reviews`, etc.
- Check **RLS Policies** are enabled

---

## Step 4: Firebase Setup (Notifications)

### 4.1 Create Firebase Project

1. Go to [firebase.google.com](https://firebase.google.com)
2. Create new project → `jp-style-lounge-studio-dev`
3. Enable Firestore (or Realtime DB)
4. Create Android & iOS apps

### 4.2 Android Setup

```bash
# Download google-services.json from Firebase
# Place it in: android/app/google-services.json
```

### 4.3 iOS Setup

```bash
# Download GoogleService-Info.plist from Firebase
# Place it in: ios/Runner/GoogleService-Info.plist
```

---

## Step 5: Run the App

### 5.1 Start Emulator

```bash
# List available devices
flutter devices

# Run on Android emulator (example)
flutter run -d emulator-5554

# Or iOS simulator
open -a Simulator
flutter run -d "iPhone 15 Pro"
```

### 5.2 Expected Startup

App should:
1. Show JP Style Lounge Studio splash screen
2. Connect to Supabase
3. No errors in console

```bash
# Check logs
flutter logs
```

### 5.3 Hot Reload

Press `r` in terminal to hot reload code changes (during development).

---

## Step 6: Verify Setup

### 6.1 Run Analyzer

```bash
flutter analyze
```

Expected: No warnings related to your code (ignore generated files).

### 6.2 Format Check

```bash
dart format --set-exit-if-changed .
```

### 6.3 Run Tests

```bash
flutter test
```

---

## External Service Accounts (Create Now)

| Service | Purpose | Signup |
|---------|---------|--------|
| Paystack | Payments (GH₵) | [paystack.com](https://paystack.com) — Choose **Test** mode |
| Africa's Talking | SMS (Ghana) | [africastalking.com](https://africastalking.com) — Use **Sandbox** |
| Google Cloud | Maps API | [cloud.google.com](https://cloud.google.com) — Get API key |

---

## Development Workflow

### Branch Strategy

```bash
# Create feature branch
git checkout -b feature/auth-flows

# Make changes & commit
git add .
git commit -m "feat: implement phone OTP login"

# Push to GitHub
git push origin feature/auth-flows

# Create Pull Request on GitHub
```

### Branches

- `main` → Production (tagged releases)
- `develop` → Staging (current sprint)
- `feature/*` → Individual features
- `bugfix/*` → Bug fixes

### Commit Conventions

```
feat: add phone OTP authentication
fix: prevent double-booking race condition
docs: update README setup steps
style: format code with dart format
test: add unit tests for BookingNotifier
refactor: restructure auth providers
```

---

## Common Tasks

### Update Dependencies

```bash
flutter pub upgrade

# Or specific package
flutter pub upgrade supabase_flutter
```

### Generate Code

Some packages require code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file change)
flutter pub run build_runner watch
```

### Clear Build Cache

```bash
flutter clean
flutter pub get
flutter pub run build_runner build
```

---

## Troubleshooting

### Issue: "Supabase: Auth token missing"

**Solution:** Check `.env` has correct `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

### Issue: "App crashes on startup"

**Solution:** Check `flutter logs` for error. Common causes:
- Missing `.env` file
- Invalid Supabase credentials
- Firebase not initialized

### Issue: "Emulator doesn't start"

**Solution:**
```bash
# Kill running emulator
adb kill-server

# Restart
flutter devices
flutter run
```

### Issue: "Hot reload fails"

**Solution:**
```bash
# Full rebuild
flutter clean
flutter run
```

---

## IDE Setup (VS Code)

### Recommended Extensions

```
flutter.flutter
dart-code.dart-code
dart-code.flutter
ms-azuretools.vscode-azure-github-copilot (GitHub Copilot)
```

### Launch Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "JP Style Lounge Studio (Dev)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=ENVIRONMENT=dev"
      ]
    }
  ]
}
```

Press `F5` to debug.

---

## Next Steps

1. ✅ Environment setup complete
2. ⏭️ **Sprint 1:** Implement authentication flows
3. ⏭️ **Sprint 2:** Build barber profile & service catalog

---

## Need Help?

- Check [Flutter Docs](https://flutter.dev/docs)
- Check [Supabase Docs](https://supabase.com/docs)
- See [ROADMAP.md](../ROADMAP.md) for project phases
- See [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) for tech details

---

**Last Updated:** March 25, 2026  
**Maintained by:** Paps James
