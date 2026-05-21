import 'dart:io';

Future<void> main() async {
  final files = <String>['.env.development', '.env.production'];

  var hasError = false;

  for (final file in files) {
    final result = await _verifyFile(file);
    if (!result) {
      hasError = true;
    }
  }

  if (hasError) {
    stderr.writeln('Environment verification failed.');
    exitCode = 1;
    return;
  }

  stdout.writeln('Environment verification passed.');
}

Future<bool> _verifyFile(String path) async {
  final file = File(path);

  if (!await file.exists()) {
    stderr.writeln('$path does not exist.');
    return false;
  }

  final lines = await file.readAsLines();
  final keys = <String>{};

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    final parts = trimmed.split('=');
    if (parts.length < 2) {
      stderr.writeln('$path has malformed line: $line');
      return false;
    }

    keys.add(parts.first.trim());
  }

  final requiredKeys = <String>[
    'APP_ENV',
    'FREE_MODE',
    'ENABLE_PAYMENTS',
    'ENABLE_PUSH_NOTIFICATIONS',
    'ENABLE_SMS_NOTIFICATIONS',
    'ENABLE_MAPS',
    'MOCK_PAYMENT_SUCCESS',
    'APPWRITE_ENDPOINT',
    'APPWRITE_PROJECT_ID',
    'APPWRITE_DATABASE_ID',
    'APPWRITE_USERS_COLLECTION_ID',
    'APPWRITE_BARBERS_COLLECTION_ID',
    'APPWRITE_SERVICES_COLLECTION_ID',
    'APPWRITE_SERVICE_ADDONS_COLLECTION_ID',
    'APPWRITE_AVAILABILITY_COLLECTION_ID',
    'APPWRITE_BOOKINGS_COLLECTION_ID',
    'APPWRITE_BOOKING_ADDONS_COLLECTION_ID',
    'APPWRITE_PAYMENTS_COLLECTION_ID',
    'APPWRITE_REVIEWS_COLLECTION_ID',
    'APPWRITE_BARBER_SETTINGS_COLLECTION_ID',
    'APPWRITE_PORTFOLIO_BUCKET_ID',
    'APPWRITE_REFERENCE_PHOTOS_BUCKET_ID',
    'APPWRITE_SERVICE_IMAGES_BUCKET_ID',
    'APPWRITE_REVIEW_PHOTOS_BUCKET_ID',
    'FIREBASE_PROJECT_ID',
    'GOOGLE_MAPS_API_KEY',
    'PAYSTACK_PUBLIC_KEY',
    'APPWRITE_PAYSTACK_INIT_FUNCTION_ID',
    'PAYSTACK_CALLBACK_URL',
  ];

  final missing = requiredKeys.where((key) => !keys.contains(key)).toList();

  if (missing.isNotEmpty) {
    stderr.writeln('$path is missing required keys: ${missing.join(', ')}');
    return false;
  }

  final forbiddenKeys = <String>[
    'APPWRITE_API_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
    'PAYSTACK_SECRET_KEY',
    'PAYSTACK_WEBHOOK_SECRET',
    'AFRICAS_TALKING_API_KEY',
  ];

  final leaked = forbiddenKeys.where((key) => keys.contains(key)).toList();

  if (leaked.isNotEmpty) {
    stderr.writeln(
      '$path includes forbidden server-side keys: ${leaked.join(', ')}',
    );
    return false;
  }

  stdout.writeln('$path verified.');
  return true;
}
