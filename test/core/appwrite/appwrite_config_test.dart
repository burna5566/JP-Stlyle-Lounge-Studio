import 'package:flutter_test/flutter_test.dart';
import 'package:jp_style_lounge_studio/core/appwrite/appwrite_config.dart';

void main() {
  test('validate reports invalid endpoint and missing fields', () {
    final config = AppwriteConfig(
      endpoint: 'not-a-url',
      projectId: '',
      databaseId: '',
      usersCollectionId: '',
      barbersCollectionId: '',
      servicesCollectionId: '',
      serviceAddonsCollectionId: '',
      availabilityCollectionId: '',
      bookingsCollectionId: '',
      bookingAddonsCollectionId: '',
      paymentsCollectionId: '',
      reviewsCollectionId: '',
      barberSettingsCollectionId: '',
      portfolioBucketId: '',
      referencePhotosBucketId: '',
      serviceImagesBucketId: '',
      reviewPhotosBucketId: '',
    );

    final errors = config.validate();

    expect(errors, isNotEmpty);
    expect(errors.any((e) => e.contains('APPWRITE_ENDPOINT')), isTrue);
    expect(errors.any((e) => e.contains('APPWRITE_PROJECT_ID')), isTrue);
  });

  test('validate passes for complete config', () {
    final config = AppwriteConfig(
      endpoint: 'https://cloud.appwrite.io/v1',
      projectId: 'project-id',
      databaseId: 'db-id',
      usersCollectionId: 'users',
      barbersCollectionId: 'barbers',
      servicesCollectionId: 'services',
      serviceAddonsCollectionId: 'service_addons',
      availabilityCollectionId: 'availability',
      bookingsCollectionId: 'bookings',
      bookingAddonsCollectionId: 'booking_addons',
      paymentsCollectionId: 'payments',
      reviewsCollectionId: 'reviews',
      barberSettingsCollectionId: 'barber_settings',
      portfolioBucketId: 'portfolio',
      referencePhotosBucketId: 'reference_photos',
      serviceImagesBucketId: 'service_images',
      reviewPhotosBucketId: 'review_photos',
    );

    expect(config.validate(), isEmpty);
  });
}
