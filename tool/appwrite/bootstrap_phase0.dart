import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'appwrite_secrets.dart';

void main() async {
  final config = _BootstrapConfig.fromEnvironment(loadAppwriteEnvironment());
  final errors = config.validate();

  if (errors.isNotEmpty) {
    stderr.writeln('Phase 0 bootstrap configuration errors:');
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

  stdout.writeln('Starting Appwrite Phase 0 bootstrap seeding...');

  await _seedBarberProfile(databases, config);
  await _seedServices(databases, config);
  await _seedAvailability(databases, config);

  stdout.writeln('Phase 0 bootstrap seeding complete.');
}

Future<void> _seedBarberProfile(
  Databases databases,
  _BootstrapConfig config,
) async {
  final rowId = 'paps-james-profile';

  await _createOrSkipRow(
    databases: databases,
    databaseId: config.databaseId,
    tableId: config.barbersTableId,
    rowId: rowId,
    data: {
      'name': 'Paps James',
      'slug': 'paps-james',
      'city': 'Accra',
      'isActive': true,
    },
    label: 'barber profile',
  );
}

Future<void> _seedServices(Databases databases, _BootstrapConfig config) async {
  final services = <Map<String, dynamic>>[
    {
      'id': 'service-haircut',
      'name': 'Haircut',
      'durationMinutes': 45,
      'priceGhs': 70,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-haircut-dye',
      'name': 'Haircut & Dye',
      'durationMinutes': 90,
      'priceGhs': 100,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-permcut',
      'name': 'Permcut',
      'durationMinutes': 60,
      'priceGhs': 80,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-kids',
      'name': 'Kids',
      'durationMinutes': 35,
      'priceGhs': 50,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-shape-shave',
      'name': 'Shape & Shave',
      'durationMinutes': 45,
      'priceGhs': 50,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-texturalize',
      'name': 'Texturalize',
      'durationMinutes': 60,
      'priceGhs': 50,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-dye-only',
      'name': 'Dye Only',
      'durationMinutes': 60,
      'priceGhs': 50,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-bleach',
      'name': 'Bleach',
      'durationMinutes': 120,
      'priceGhs': 200,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-colour-dye',
      'name': 'Colour Dye',
      'durationMinutes': 90,
      'priceGhs': 100,
      'audience': 'unisex',
      'isActive': true,
    },
    {
      'id': 'service-appointment-booking',
      'name': 'Appointment Booking',
      'durationMinutes': 30,
      'priceGhs': 150,
      'audience': 'unisex',
      'isActive': true,
    },
  ];

  for (final service in services) {
    await _createOrUpdateRow(
      databases: databases,
      databaseId: config.databaseId,
      tableId: config.servicesTableId,
      rowId: service['id'] as String,
      data: {
        'name': service['name'],
        'durationMinutes': service['durationMinutes'],
        'priceGhs': service['priceGhs'],
        'audience': service['audience'],
        'isActive': service['isActive'],
      },
      label: 'service ${service['name']}',
    );
  }

  await _deleteLegacyRows(
    databases: databases,
    databaseId: config.databaseId,
    tableId: config.servicesTableId,
    rowIds: const [
      'service-skin-fade',
      'service-haircut-beard',
      'service-silk-press',
      'service-braids-styling',
      'service-kids-cut',
    ],
    label: 'legacy service',
  );
}

Future<void> _seedAvailability(
  Databases databases,
  _BootstrapConfig config,
) async {
  for (var dayOfWeek = 1; dayOfWeek <= 6; dayOfWeek++) {
    await _createOrUpdateRow(
      databases: databases,
      databaseId: config.databaseId,
      tableId: config.availabilityTableId,
      rowId: 'availability-day-$dayOfWeek',
      data: {
        'dayOfWeek': dayOfWeek,
        'startTime': '08:30',
        'endTime': '21:00',
        'isBlocked': false,
      },
      label: 'availability day $dayOfWeek',
    );
  }

  await _createOrUpdateRow(
    databases: databases,
    databaseId: config.databaseId,
    tableId: config.availabilityTableId,
    rowId: 'availability-day-7',
    data: {
      'dayOfWeek': 7,
      'startTime': '14:00',
      'endTime': '21:00',
      'isBlocked': false,
    },
    label: 'availability day 7',
  );
}

Future<void> _createOrUpdateRow({
  required Databases databases,
  required String databaseId,
  required String tableId,
  required String rowId,
  required Map<String, dynamic> data,
  required String label,
}) async {
  try {
    await databases.getDocument(
      databaseId: databaseId,
      collectionId: tableId,
      documentId: rowId,
    );

    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: tableId,
      documentId: rowId,
      data: data,
    );

    stdout.writeln('Updated $label ($rowId).');
    return;
  } on AppwriteException {
    // Row not found; create below.
  }

  await databases.createDocument(
    databaseId: databaseId,
    collectionId: tableId,
    documentId: rowId,
    data: data,
  );
  stdout.writeln('Created $label ($rowId).');
}

Future<void> _createOrSkipRow({
  required Databases databases,
  required String databaseId,
  required String tableId,
  required String rowId,
  required Map<String, dynamic> data,
  required String label,
}) async {
  try {
    await databases.getDocument(
      databaseId: databaseId,
      collectionId: tableId,
      documentId: rowId,
    );
    stdout.writeln('Skip existing $label ($rowId).');
    return;
  } on AppwriteException {
    // Row not found; create below.
  }

  await databases.createDocument(
    databaseId: databaseId,
    collectionId: tableId,
    documentId: rowId,
    data: data,
  );
  stdout.writeln('Created $label ($rowId).');
}

Future<void> _deleteLegacyRows({
  required Databases databases,
  required String databaseId,
  required String tableId,
  required List<String> rowIds,
  required String label,
}) async {
  for (final rowId in rowIds) {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: tableId,
        documentId: rowId,
      );
      stdout.writeln('Deleted $label ($rowId).');
    } on AppwriteException {
      stdout.writeln('Skip missing $label ($rowId).');
    }
  }
}

class _BootstrapConfig {
  _BootstrapConfig({
    required this.endpoint,
    required this.projectId,
    required this.apiKey,
    required this.databaseId,
    required this.barbersTableId,
    required this.servicesTableId,
    required this.availabilityTableId,
  });

  final String endpoint;
  final String projectId;
  final String apiKey;
  final String databaseId;
  final String barbersTableId;
  final String servicesTableId;
  final String availabilityTableId;

  factory _BootstrapConfig.fromEnvironment(Map<String, String> environment) {
    return _BootstrapConfig(
      endpoint: environment['APPWRITE_ENDPOINT'] ?? '',
      projectId: environment['APPWRITE_PROJECT_ID'] ?? '',
      apiKey: environment['APPWRITE_API_KEY'] ?? '',
      databaseId: environment['APPWRITE_DATABASE_ID'] ?? '',
      barbersTableId:
          environment['APPWRITE_BARBERS_COLLECTION_ID'] ?? 'barbers',
      servicesTableId:
          environment['APPWRITE_SERVICES_COLLECTION_ID'] ?? 'services',
      availabilityTableId:
          environment['APPWRITE_AVAILABILITY_COLLECTION_ID'] ?? 'availability',
    );
  }

  List<String> validate() {
    final errors = <String>[];

    if (endpoint.trim().isEmpty) {
      errors.add('APPWRITE_ENDPOINT is required.');
    }

    if (projectId.trim().isEmpty) {
      errors.add('APPWRITE_PROJECT_ID is required.');
    }

    if (apiKey.trim().isEmpty) {
      errors.add('APPWRITE_API_KEY is required for bootstrap script.');
    }

    if (databaseId.trim().isEmpty) {
      errors.add('APPWRITE_DATABASE_ID is required.');
    }

    return errors;
  }
}
