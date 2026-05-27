import 'dart:convert';
import 'dart:io';

import 'appwrite_secrets.dart';

void main(List<String> args) async {
  final apply = args.contains('--apply');
  final config = _Config.fromEnvironment(loadAppwriteEnvironment());
  final configErrors = config.validate();

  if (configErrors.isNotEmpty) {
    stderr.writeln('Reconcile configuration errors:');
    for (final error in configErrors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Starting stale pending deposit reconciliation...');
  stdout.writeln('Mode: ${apply ? 'APPLY' : 'DRY RUN'}');
  stdout.writeln('Minimum booking age: ${config.minimumAgeMinutes} minutes');
  stdout.writeln('');

  final appwrite = _AppwriteRestClient(config: config);
  final paystack = _PaystackClient(secretKey: config.paystackSecretKey);

  final bookings = await appwrite.listAllBookings();
  final now = DateTime.now().toUtc();

  final candidates = <_BookingRecord>[];
  for (final booking in bookings) {
    final hasReference = booking.paymentReference.isNotEmpty;
    final isUnpaid = booking.depositPaid != true;
    final isPending = booking.status.toLowerCase() == 'pending';
    final isOldEnough =
        now.difference(booking.createdAtUtc).inMinutes >=
        config.minimumAgeMinutes;

    if (hasReference && isUnpaid && isPending && isOldEnough) {
      candidates.add(booking);
    }
  }

  stdout.writeln('Total bookings scanned: ${bookings.length}');
  stdout.writeln('Candidates found: ${candidates.length}');
  stdout.writeln('');

  var verifiedSuccess = 0;
  var updated = 0;
  var skipped = 0;

  for (final booking in candidates) {
    final verify = await paystack.verify(booking.paymentReference);

    if (!verify.isSuccess) {
      skipped += 1;
      stdout.writeln(
        'SKIP ${booking.id} ref=${booking.paymentReference} reason=${verify.reason}',
      );
      continue;
    }

    verifiedSuccess += 1;

    if (!apply) {
      stdout.writeln(
        'DRYRUN UPDATE ${booking.id} ref=${booking.paymentReference} paidAt=${verify.paidAt ?? 'unknown'}',
      );
      continue;
    }

    await appwrite.markBookingAsPaid(booking.id);
    updated += 1;
    stdout.writeln(
      'UPDATED ${booking.id} ref=${booking.paymentReference} -> deposit_paid=true status=confirmed',
    );
  }

  stdout.writeln('');
  stdout.writeln('Summary:');
  stdout.writeln('- Candidate rows: ${candidates.length}');
  stdout.writeln('- Verified success on Paystack: $verifiedSuccess');
  stdout.writeln('- Updated rows: $updated');
  stdout.writeln('- Skipped rows: $skipped');

  if (!apply) {
    stdout.writeln('');
    stdout.writeln(
      'Dry run only. Re-run with --apply to persist updates to Appwrite.',
    );
  }
}

class _Config {
  _Config({
    required this.appwriteEndpoint,
    required this.projectId,
    required this.apiKey,
    required this.databaseId,
    required this.bookingsCollectionId,
    required this.paystackSecretKey,
    required this.minimumAgeMinutes,
  });

  final String appwriteEndpoint;
  final String projectId;
  final String apiKey;
  final String databaseId;
  final String bookingsCollectionId;
  final String paystackSecretKey;
  final int minimumAgeMinutes;

  factory _Config.fromEnvironment(Map<String, String> env) {
    return _Config(
      appwriteEndpoint: env['APPWRITE_ENDPOINT'] ?? '',
      projectId: env['APPWRITE_PROJECT_ID'] ?? '',
      apiKey: env['APPWRITE_API_KEY'] ?? '',
      databaseId: env['APPWRITE_DATABASE_ID'] ?? '',
      bookingsCollectionId:
          env['APPWRITE_BOOKINGS_COLLECTION_ID'] ?? 'bookings',
      paystackSecretKey: env['PAYSTACK_SECRET_KEY'] ?? '',
      minimumAgeMinutes:
          int.tryParse(env['RECONCILE_MIN_AGE_MINUTES'] ?? '') ?? 15,
    );
  }

  List<String> validate() {
    final errors = <String>[];

    if (appwriteEndpoint.trim().isEmpty) {
      errors.add('APPWRITE_ENDPOINT not set');
    }
    if (projectId.trim().isEmpty) {
      errors.add('APPWRITE_PROJECT_ID not set');
    }
    if (apiKey.trim().isEmpty) {
      errors.add('APPWRITE_API_KEY not set');
    }
    if (databaseId.trim().isEmpty) {
      errors.add('APPWRITE_DATABASE_ID not set');
    }
    if (paystackSecretKey.trim().isEmpty) {
      errors.add('PAYSTACK_SECRET_KEY not set');
    }

    return errors;
  }
}

class _AppwriteRestClient {
  _AppwriteRestClient({required this.config});

  final _Config config;

  Future<List<_BookingRecord>> listAllBookings() async {
    final records = <_BookingRecord>[];
    var offset = 0;
    const limit = 100;

    while (true) {
      final response = await _request(
        method: 'GET',
        path:
            '/databases/${config.databaseId}/collections/${config.bookingsCollectionId}/documents',
        queryValues: [
          jsonEncode({
            'method': 'limit',
            'values': [limit],
          }),
          jsonEncode({
            'method': 'offset',
            'values': [offset],
          }),
        ],
      );

      final documents = (response['documents'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      if (documents.isEmpty) {
        break;
      }

      for (final doc in documents) {
        final id = (doc[r'$id'] ?? '').toString().trim();
        final paymentRef = (doc['payment_ref'] ?? '').toString().trim();
        final status = (doc['status'] ?? '').toString().trim();
        final depositPaid = doc['deposit_paid'] == true;
        final createdAtText = (doc[r'$createdAt'] ?? '').toString();
        final createdAt = DateTime.tryParse(createdAtText)?.toUtc();

        if (id.isEmpty || createdAt == null) {
          continue;
        }

        records.add(
          _BookingRecord(
            id: id,
            paymentReference: paymentRef,
            status: status,
            depositPaid: depositPaid,
            createdAtUtc: createdAt,
          ),
        );
      }

      if (documents.length < limit) {
        break;
      }

      offset += limit;
    }

    return records;
  }

  Future<void> markBookingAsPaid(String bookingId) async {
    await _request(
      method: 'PATCH',
      path:
          '/databases/${config.databaseId}/collections/${config.bookingsCollectionId}/documents/$bookingId',
      body: {
        'data': {'deposit_paid': true, 'status': 'confirmed'},
      },
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    List<String> queryValues = const [],
  }) async {
    final endpoint = config.appwriteEndpoint.endsWith('/')
        ? config.appwriteEndpoint.substring(
            0,
            config.appwriteEndpoint.length - 1,
          )
        : config.appwriteEndpoint;

    final query = StringBuffer();
    if (queryValues.isNotEmpty) {
      query.write('?');
      for (var i = 0; i < queryValues.length; i++) {
        if (i > 0) {
          query.write('&');
        }
        query.write('queries%5B%5D=');
        query.write(Uri.encodeQueryComponent(queryValues[i]));
      }
    }

    final uri = Uri.parse('$endpoint$path$query');
    final client = HttpClient();

    try {
      final request = await client.openUrl(method, uri);
      request.headers.set('X-Appwrite-Project', config.projectId);
      request.headers.set('X-Appwrite-Key', config.apiKey);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close();
      final text = await utf8.decodeStream(response);

      if (response.statusCode >= 400) {
        throw Exception('Appwrite API error (${response.statusCode}): $text');
      }

      if (text.trim().isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected Appwrite response shape.');
      }

      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}

class _PaystackClient {
  _PaystackClient({required this.secretKey});

  final String secretKey;

  Future<_PaystackVerifyResult> verify(String reference) async {
    final uri = Uri.parse(
      'https://api.paystack.co/transaction/verify/${Uri.encodeComponent(reference)}',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $secretKey');
      final response = await request.close();
      final text = await utf8.decodeStream(response);

      if (response.statusCode >= 400) {
        return _PaystackVerifyResult(
          isSuccess: false,
          reason: 'paystack_http_${response.statusCode}',
          paidAt: null,
        );
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        return const _PaystackVerifyResult(
          isSuccess: false,
          reason: 'invalid_response_shape',
          paidAt: null,
        );
      }

      final data = decoded['data'];
      if (decoded['status'] != true || data is! Map<String, dynamic>) {
        return const _PaystackVerifyResult(
          isSuccess: false,
          reason: 'verify_failed',
          paidAt: null,
        );
      }

      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        return _PaystackVerifyResult(
          isSuccess: false,
          reason: 'status_$status',
          paidAt: data['paid_at']?.toString(),
        );
      }

      return _PaystackVerifyResult(
        isSuccess: true,
        reason: 'ok',
        paidAt: data['paid_at']?.toString(),
      );
    } catch (_) {
      return const _PaystackVerifyResult(
        isSuccess: false,
        reason: 'network_or_parse_error',
        paidAt: null,
      );
    } finally {
      client.close(force: true);
    }
  }
}

class _BookingRecord {
  const _BookingRecord({
    required this.id,
    required this.paymentReference,
    required this.status,
    required this.depositPaid,
    required this.createdAtUtc,
  });

  final String id;
  final String paymentReference;
  final String status;
  final bool depositPaid;
  final DateTime createdAtUtc;
}

class _PaystackVerifyResult {
  const _PaystackVerifyResult({
    required this.isSuccess,
    required this.reason,
    required this.paidAt,
  });

  final bool isSuccess;
  final String reason;
  final String? paidAt;
}
