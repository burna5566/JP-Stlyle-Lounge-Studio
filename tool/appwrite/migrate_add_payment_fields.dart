import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'appwrite_secrets.dart';

void main() async {
  final config = _MigrateConfig.fromEnvironment(loadAppwriteEnvironment());
  final errors = config.validate();

  if (errors.isNotEmpty) {
    stderr.writeln('Migration configuration errors:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  final client = Client()
      .setEndpoint(config.endpoint)
      .setProject(config.projectId)
      .setKey(config.apiKey);

  final databases = Databases(client);

  stdout.writeln('Starting Appwrite bookings schema migration...');
  stdout.writeln(
    'Adding payment_ref and deposit_paid fields to bookings collection.',
  );
  stdout.writeln('');

  try {
    // Fetch current collection to check if fields exist
    final collection = await databases.getCollection(
      databaseId: config.databaseId,
      collectionId: config.bookingsTableId,
    );

    final existingFields = <String>{};
    for (final attr in collection.attributes) {
      String? key;
      if (attr is Map<String, dynamic>) {
        key = attr['key'] as String?;
      } else {
        final dynamicAttr = attr as dynamic;
        try {
          final data = dynamicAttr.data as Map<String, dynamic>?;
          key = data?['key'] as String?;
        } on Object {
          // Skip unknown shapes
        }
      }
      if (key != null) {
        existingFields.add(key);
      }
    }

    // Add payment_ref if missing
    if (!existingFields.contains('payment_ref')) {
      stdout.writeln('Adding field: payment_ref (text, nullable)...');
      await databases.createStringAttribute(
        databaseId: config.databaseId,
        collectionId: config.bookingsTableId,
        key: 'payment_ref',
        size: 255,
        xrequired: false,
      );
      stdout.writeln('✓ Added payment_ref field');
    } else {
      stdout.writeln('✓ Field payment_ref already exists');
    }

    // Add deposit_paid if missing
    if (!existingFields.contains('deposit_paid')) {
      stdout.writeln('Adding field: deposit_paid (boolean, default false)...');
      await databases.createBooleanAttribute(
        databaseId: config.databaseId,
        collectionId: config.bookingsTableId,
        key: 'deposit_paid',
        xrequired: false,
      );
      stdout.writeln('✓ Added deposit_paid field');
    } else {
      stdout.writeln('✓ Field deposit_paid already exists');
    }

    stdout.writeln('');
    stdout.writeln('✓ Migration complete!');
    stdout.writeln('');
    stdout.writeln('Next steps:');
    stdout.writeln('1. Deploy your Paystack webhook function to Appwrite');
    stdout.writeln('2. Set webhook env vars in Appwrite function settings');
    stdout.writeln('3. Copy function HTTP trigger URL to Paystack dashboard');
    stdout.writeln('4. Test with a sandbox payment');
  } on AppwriteException catch (e) {
    stderr.writeln('✗ Migration failed: ${e.message}');
    exitCode = 1;
  }
}

class _MigrateConfig {
  _MigrateConfig({
    required this.endpoint,
    required this.projectId,
    required this.apiKey,
    required this.databaseId,
    required this.bookingsTableId,
  });

  final String endpoint;
  final String projectId;
  final String apiKey;
  final String databaseId;
  final String bookingsTableId;

  factory _MigrateConfig.fromEnvironment(Map<String, String> environment) {
    return _MigrateConfig(
      endpoint: environment['APPWRITE_ENDPOINT'] ?? '',
      projectId: environment['APPWRITE_PROJECT_ID'] ?? '',
      apiKey: environment['APPWRITE_API_KEY'] ?? '',
      databaseId: environment['APPWRITE_DATABASE_ID'] ?? '',
      bookingsTableId:
          environment['APPWRITE_BOOKINGS_COLLECTION_ID'] ?? 'bookings',
    );
  }

  List<String> validate() {
    final errors = <String>[];

    if (endpoint.isEmpty) {
      errors.add('APPWRITE_ENDPOINT not set');
    }
    if (projectId.isEmpty) {
      errors.add('APPWRITE_PROJECT_ID not set');
    }
    if (apiKey.isEmpty) {
      errors.add('APPWRITE_API_KEY not set');
    }
    if (databaseId.isEmpty) {
      errors.add('APPWRITE_DATABASE_ID not set');
    }

    return errors;
  }
}
