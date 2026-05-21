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
  - Appwrite
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

### 2.2 Fill in Client-Safe Configuration

Edit `.env.development` and `.env.production` with client-safe values only:

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

# Appwrite public client config
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=YOUR_APPWRITE_PROJECT_ID
APPWRITE_DATABASE_ID=jp_style_lounge_dev

# Paystack public key
PAYSTACK_PUBLIC_KEY=pk_live_YOUR_PUBLIC_KEY

# Firebase (Production)
FIREBASE_PROJECT_ID=jp-style-lounge-studio-prod

# Google Maps (Production)
GOOGLE_MAPS_API_KEY=YOUR_PROD_MAPS_KEY

# Backend-only secrets such as APPWRITE_API_KEY, PAYSTACK_SECRET_KEY,
# PAYSTACK_WEBHOOK_SECRET, and AFRICAS_TALKING_API_KEY must not go here.
```

**Production default:** paid integrations are enabled and must be configured with live credentials before launch.

**Never commit backend/admin secrets.** The Flutter-bundled env files are for
public client configuration only.

---

## Step 3: Appwrite Setup

### 3.1 Create Appwrite Project

1. Go to [cloud.appwrite.io](https://cloud.appwrite.io)
2. Create or open the JP Style Lounge Studio project
3. Add Flutter platforms for the package/bundle IDs you will run
4. Copy the endpoint and project ID to `.env.development`

### 3.2 Create Database Shape

Use [docs/APPWRITE_BACKEND.md](docs/APPWRITE_BACKEND.md) as the current
collection and bucket plan. Server/admin API keys are only for setup scripts
or Appwrite Functions and must never be added to Flutter env assets.

### 3.3 Verify Schema

In Appwrite Console:
- Go to **Databases**
- Verify tables exist:
  - `barbers`, `users`, `services`, `bookings`, `reviews`, etc.
- Check collection permissions before using production data

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
2. Connect to Appwrite
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

### Merge Rules

- `feature/*` and `bugfix/*` merge into `develop` via pull request only.
- `develop` merges into `main` only from a release PR after all quality gates pass.
- Direct pushes to `main` are disallowed.
- PRs require green checks for `flutter analyze`, `flutter test`, `tool/verify_env.dart`, and `tool/store_readiness_audit.dart`.

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
flutter pub upgrade appwrite_flutter
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

### Issue: "Appwrite: auth or config missing"

**Solution:** Check `.env` has correct `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, and collection IDs.

### Issue: "App crashes on startup"

**Solution:** Check `flutter logs` for error. Common causes:
- Missing `.env` file
- Invalid Appwrite credentials
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
- Check [Appwrite Docs](https://appwrite.com/docs)
- See [ROADMAP.md](../ROADMAP.md) for project phases
- See [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) for tech details

---

**Last Updated:** March 25, 2026  
**Maintained by:** Paps James
