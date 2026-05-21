# Firebase Free Tier Integration + Env Setup

## Completed Steps
- [x] Update pubspec.yaml: Add flutter_dotenv dep
- [x] Create lib/firebase_options.dart (template)
- [x] Edit lib/main.dart: dotenv load, Firebase init, FCM token
- [x] Create .env.development (from .env.example, dev settings)
- [x] Create .env.production (from .env.example, prod settings)
- [x] Create android/app/google-services.json (placeholder)
- [x] Create ios/Runner/GoogleService-Info.plist (placeholder)
- [x] Update .gitignore: Add .env*
- [x] flutter pub get

## Pending Steps
- [x] User: Download real configs from Firebase console & fill keys
- [x] User: `flutterfire configure`
- [x] Test: `flutter run --dart-define=APP_ENV=development`
- [ ] Commit & push Firebase integration

## Foundation Hardening
- [x] Add runtime Appwrite config validation (`lib/core/appwrite/runtime_guard.dart`)
- [x] Add Appwrite SDK client factory (`lib/core/appwrite/appwrite_client_factory.dart`)
- [x] Add environment verification script (`tool/verify_env.dart`)
- [x] Add CI step to run `dart run tool/verify_env.dart`
- [x] Add Appwrite bootstrap scripts for database, collections, indexes, and buckets

## User Actions (Critical)
1. Create and connect Paystack sandbox keys (client public key in env; server secrets outside Flutter assets).
2. Create and connect Africa's Talking sandbox credentials (server-only).
3. Commit and push Phase 0 completion changes.

## User Actions
1. Keep `.appwrite.secrets` local and gitignored for admin scripts (`tool/appwrite/*`).
2. Keep `.env.development` and `.env.production` client-safe only (no server keys).
3. Run baseline gate command before each PR:
   - `flutter analyze && flutter test && dart run tool/verify_env.dart && dart run tool/store_readiness_audit.dart --fail-on-warning`
