import '../env/env.dart';

class AppwriteConfig {
  AppwriteConfig({
    required this.endpoint,
    required this.projectId,
    required this.databaseId,
    required this.usersCollectionId,
    required this.barbersCollectionId,
    required this.servicesCollectionId,
    required this.serviceAddonsCollectionId,
    required this.availabilityCollectionId,
    required this.bookingsCollectionId,
    required this.bookingAddonsCollectionId,
    required this.paymentsCollectionId,
    required this.reviewsCollectionId,
    required this.barberSettingsCollectionId,
    required this.portfolioBucketId,
    required this.referencePhotosBucketId,
    required this.serviceImagesBucketId,
    required this.reviewPhotosBucketId,
  });

  final String endpoint;
  final String projectId;
  final String databaseId;
  final String usersCollectionId;
  final String barbersCollectionId;
  final String servicesCollectionId;
  final String serviceAddonsCollectionId;
  final String availabilityCollectionId;
  final String bookingsCollectionId;
  final String bookingAddonsCollectionId;
  final String paymentsCollectionId;
  final String reviewsCollectionId;
  final String barberSettingsCollectionId;
  final String portfolioBucketId;
  final String referencePhotosBucketId;
  final String serviceImagesBucketId;
  final String reviewPhotosBucketId;

  static AppwriteConfig fromEnv() {
    return AppwriteConfig(
      endpoint: Env.appwriteEndpoint,
      projectId: Env.appwriteProjectId,
      databaseId: Env.appwriteDatabaseId,
      usersCollectionId: Env.usersCollectionId,
      barbersCollectionId: Env.barbersCollectionId,
      servicesCollectionId: Env.servicesCollectionId,
      serviceAddonsCollectionId: Env.serviceAddonsCollectionId,
      availabilityCollectionId: Env.availabilityCollectionId,
      bookingsCollectionId: Env.bookingsCollectionId,
      bookingAddonsCollectionId: Env.bookingAddonsCollectionId,
      paymentsCollectionId: Env.paymentsCollectionId,
      reviewsCollectionId: Env.reviewsCollectionId,
      barberSettingsCollectionId: Env.barberSettingsCollectionId,
      portfolioBucketId: Env.portfolioBucketId,
      referencePhotosBucketId: Env.referencePhotosBucketId,
      serviceImagesBucketId: Env.serviceImagesBucketId,
      reviewPhotosBucketId: Env.reviewPhotosBucketId,
    );
  }

  List<String> validate() {
    final errors = <String>[];

    _requireNonEmpty('APPWRITE_ENDPOINT', endpoint, errors);
    _requireNonEmpty('APPWRITE_PROJECT_ID', projectId, errors);
    _requireNonEmpty('APPWRITE_DATABASE_ID', databaseId, errors);

    _requireNonEmpty('APPWRITE_USERS_COLLECTION_ID', usersCollectionId, errors);
    _requireNonEmpty(
      'APPWRITE_BARBERS_COLLECTION_ID',
      barbersCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_SERVICES_COLLECTION_ID',
      servicesCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_SERVICE_ADDONS_COLLECTION_ID',
      serviceAddonsCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_AVAILABILITY_COLLECTION_ID',
      availabilityCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_BOOKINGS_COLLECTION_ID',
      bookingsCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_BOOKING_ADDONS_COLLECTION_ID',
      bookingAddonsCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_PAYMENTS_COLLECTION_ID',
      paymentsCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_REVIEWS_COLLECTION_ID',
      reviewsCollectionId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_BARBER_SETTINGS_COLLECTION_ID',
      barberSettingsCollectionId,
      errors,
    );

    _requireNonEmpty('APPWRITE_PORTFOLIO_BUCKET_ID', portfolioBucketId, errors);
    _requireNonEmpty(
      'APPWRITE_REFERENCE_PHOTOS_BUCKET_ID',
      referencePhotosBucketId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_SERVICE_IMAGES_BUCKET_ID',
      serviceImagesBucketId,
      errors,
    );
    _requireNonEmpty(
      'APPWRITE_REVIEW_PHOTOS_BUCKET_ID',
      reviewPhotosBucketId,
      errors,
    );

    if (!_isLikelyUrl(endpoint)) {
      errors.add('APPWRITE_ENDPOINT must be a valid http(s) URL.');
    }

    return errors;
  }

  void _requireNonEmpty(String key, String value, List<String> errors) {
    if (value.trim().isEmpty) {
      errors.add('$key is required.');
    }
  }

  bool _isLikelyUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return false;
    }

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
