import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Map<String, String> _env() {
    try {
      return dotenv.env;
    } on Object {
      return const {};
    }
  }

  static String _get(String key, {String fallback = ''}) {
    return _env()[key] ?? fallback;
  }

  static bool _getBool(String key, {bool fallback = false}) {
    final value = _env()[key]?.toLowerCase();
    if (value == null) {
      return fallback;
    }

    return value == 'true';
  }

  // Core
  static String get appEnv => _get('APP_ENV', fallback: 'production');
  static bool get freeMode => _getBool('FREE_MODE');

  // Appwrite
  static String get appwriteEndpoint => _get('APPWRITE_ENDPOINT');
  static String get appwriteProjectId => _get('APPWRITE_PROJECT_ID');
  static String get appwriteDatabaseId => _get('APPWRITE_DATABASE_ID');

  // Appwrite collections
  static String get usersCollectionId => _get('APPWRITE_USERS_COLLECTION_ID');
  static String get barbersCollectionId =>
      _get('APPWRITE_BARBERS_COLLECTION_ID');
  static String get servicesCollectionId =>
      _get('APPWRITE_SERVICES_COLLECTION_ID');
  static String get serviceAddonsCollectionId =>
      _get('APPWRITE_SERVICE_ADDONS_COLLECTION_ID');
  static String get availabilityCollectionId =>
      _get('APPWRITE_AVAILABILITY_COLLECTION_ID');
  static String get bookingsCollectionId =>
      _get('APPWRITE_BOOKINGS_COLLECTION_ID');
  static String get bookingAddonsCollectionId =>
      _get('APPWRITE_BOOKING_ADDONS_COLLECTION_ID');
  static String get paymentsCollectionId =>
      _get('APPWRITE_PAYMENTS_COLLECTION_ID');
  static String get reviewsCollectionId =>
      _get('APPWRITE_REVIEWS_COLLECTION_ID');
  static String get barberSettingsCollectionId =>
      _get('APPWRITE_BARBER_SETTINGS_COLLECTION_ID');

  // Appwrite storage buckets
  static String get portfolioBucketId => _get('APPWRITE_PORTFOLIO_BUCKET_ID');
  static String get referencePhotosBucketId =>
      _get('APPWRITE_REFERENCE_PHOTOS_BUCKET_ID');
  static String get serviceImagesBucketId =>
      _get('APPWRITE_SERVICE_IMAGES_BUCKET_ID');
  static String get reviewPhotosBucketId =>
      _get('APPWRITE_REVIEW_PHOTOS_BUCKET_ID');

  // Firebase
  static String get firebaseProjectId => _get('FIREBASE_PROJECT_ID');

  // Google Maps
  static String get googleMapsApiKey => _get('GOOGLE_MAPS_API_KEY');

  // Paystack
  static String get paystackPublicKey => _get('PAYSTACK_PUBLIC_KEY');
  static String get paystackInitFunctionId =>
      _get('APPWRITE_PAYSTACK_INIT_FUNCTION_ID');
  static String get paystackCallbackUrl => _get('PAYSTACK_CALLBACK_URL');

  // Feature toggles
  static bool get enablePayments => _getBool('ENABLE_PAYMENTS');
  static bool get enablePushNotifications =>
      _getBool('ENABLE_PUSH_NOTIFICATIONS');
  static bool get enableSmsNotifications =>
      _getBool('ENABLE_SMS_NOTIFICATIONS');
  static bool get enableMaps => _getBool('ENABLE_MAPS');
  static bool get mockPaymentSuccess => _getBool('MOCK_PAYMENT_SUCCESS');
}
