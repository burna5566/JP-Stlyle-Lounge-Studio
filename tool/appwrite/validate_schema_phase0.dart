import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'appwrite_secrets.dart';

void main() async {
  final config = _ValidateConfig.fromEnvironment(loadAppwriteEnvironment());
  final errors = config.validate();

  if (errors.isNotEmpty) {
    stderr.writeln('Schema validation configuration errors:');
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

  stdout.writeln('Starting Appwrite Phase 0 schema validation...');
  stdout.writeln('');

  var issueCount = 0;

  // Validate each table and its expected columns
  issueCount += await _validateTable(
    databases: databases,
    databaseId: config.databaseId,
    tableId: config.barbersTableId,
    tableName: 'Barbers',
    expectedColumns: {
      'name': 'text',
      'slug': 'text',
      'city': 'text',
      'isActive': 'boolean',
    },
  );

  issueCount += await _validateTable(
    databases: databases,
    databaseId: config.databaseId,
    tableId: config.servicesTableId,
    tableName: 'Services',
    expectedColumns: {
      'name': 'text',
      'durationMinutes': 'integer',
      'priceGhs': 'integer',
      'audience': 'text',
      'isActive': 'boolean',
    },
  );

  issueCount += await _validateTable(
    databases: databases,
    databaseId: config.databaseId,
    tableId: config.availabilityTableId,
    tableName: 'Availability',
    expectedColumns: {
      'dayOfWeek': 'integer',
      'startTime': 'text',
      'endTime': 'text',
      'isBlocked': 'boolean',
    },
  );

  issueCount += await _validateTable(
    databases: databases,
    databaseId: config.databaseId,
    tableId: config.bookingsTableId,
    tableName: 'Bookings',
    expectedColumns: {
      'serviceId': 'text',
      'serviceName': 'text',
      'servicePriceGhs': 'double',
      'serviceAudience': 'text',
      'professionalRole': 'text',
      'reportingSegment': 'text',
      'appointmentDate': 'text',
      'appointmentTime': 'text',
      'appointmentAt': 'datetime',
      'customerName': 'text',
      'customerPhone': 'text',
      'notes': 'text',
      'status': 'text',
      'source': 'text',
    },
  );

  stdout.writeln('');
  if (issueCount == 0) {
    stdout.writeln('✓ All Phase 0 schema validation checks passed!');
    stdout.writeln(
      'Ready to run: dart run tool/appwrite/bootstrap_phase0.dart',
    );
  } else {
    stderr.writeln('✗ Schema validation found $issueCount issue(s).');
    stderr.writeln('');
    stderr.writeln('Next steps:');
    stderr.writeln('1. Visit Appwrite Console: ${config.endpoint}');
    stderr.writeln('2. Go to Database: ${config.databaseId}');
    stderr.writeln('3. Create missing tables or add missing columns');
    stderr.writeln('4. Use the expected columns above as reference');
    stderr.writeln('5. Re-run this validation script to confirm');
    exitCode = 1;
  }
}

Future<int> _validateTable({
  required Databases databases,
  required String databaseId,
  required String tableId,
  required String tableName,
  required Map<String, String> expectedColumns,
}) async {
  var issueCount = 0;

  stdout.writeln('Checking $tableName table ($tableId)...');

  try {
    final collection = await databases.getCollection(
      databaseId: databaseId,
      collectionId: tableId,
    );

    stdout.writeln('  ✓ Table exists');

    // Get existing column names and types.
    // Appwrite may return attributes as maps depending on SDK/version.
    final existingColumns = <String, String>{};
    for (final attr in collection.attributes) {
      String? key;
      String? type;

      if (attr is Map<String, dynamic>) {
        key = attr['key'] as String?;
        type = attr['type'] as String?;
      } else {
        final dynamicAttr = attr as dynamic;
        try {
          final data = dynamicAttr.data as Map<String, dynamic>?;
          key = data?['key'] as String?;
          type = data?['type'] as String?;
        } on Object {
          // Skip unknown shapes.
        }
      }

      if (key != null && type != null) {
        existingColumns[key] = type;
      }
    }

    // Check each expected column
    for (final expectedCol in expectedColumns.entries) {
      final colName = expectedCol.key;
      final expectedType = expectedCol.value;

      final actualType = existingColumns[colName];
      if (actualType == null) {
        stderr.writeln(
          '    ✗ Missing column "$colName" (expected: $expectedType)',
        );
        issueCount++;
        continue;
      }

      if (_typeMatches(expectedType, actualType)) {
        stdout.writeln('    ✓ Column "$colName" ($actualType)');
      } else {
        stderr.writeln(
          '    ✗ Type mismatch for "$colName" '
          '(expected: $expectedType, actual: $actualType)',
        );
        issueCount++;
      }
    }
  } on AppwriteException catch (e) {
    stderr.writeln('  ✗ Table not found');
    stderr.writeln('    Error: ${e.message}');
    issueCount++;
  }

  stdout.writeln('');
  return issueCount;
}

bool _typeMatches(String expected, String actual) {
  final normalizedExpected = expected.trim().toLowerCase();
  final normalizedActual = actual.trim().toLowerCase();

  if (normalizedExpected == normalizedActual) {
    return true;
  }

  const aliases = <String, Set<String>>{
    'text': {'text', 'string'},
    'string': {'text', 'string'},
    'integer': {'integer', 'int'},
    'double': {'double', 'float', 'number'},
    'boolean': {'boolean', 'bool'},
    'datetime': {'datetime', 'date', 'timestamp'},
  };

  final allowed = aliases[normalizedExpected];
  if (allowed == null) {
    return false;
  }

  return allowed.contains(normalizedActual);
}

class _ValidateConfig {
  _ValidateConfig({
    required this.endpoint,
    required this.projectId,
    required this.apiKey,
    required this.databaseId,
    required this.barbersTableId,
    required this.servicesTableId,
    required this.availabilityTableId,
    required this.bookingsTableId,
  });

  final String endpoint;
  final String projectId;
  final String apiKey;
  final String databaseId;
  final String barbersTableId;
  final String servicesTableId;
  final String availabilityTableId;
  final String bookingsTableId;

  factory _ValidateConfig.fromEnvironment(Map<String, String> environment) {
    return _ValidateConfig(
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
