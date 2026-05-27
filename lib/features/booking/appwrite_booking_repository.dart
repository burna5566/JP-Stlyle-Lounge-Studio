import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;

import '../../core/appwrite/appwrite_config.dart';
import '../../core/appwrite/appwrite_client_factory.dart';

class PaystackInitResult {
  const PaystackInitResult({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  final String authorizationUrl;
  final String accessCode;
  final String reference;
}

class AppwriteBookingService {
  const AppwriteBookingService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.priceGhs,
    required this.audience,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final double priceGhs;
  final String audience;
}

class StalePendingBookingAlert {
  const StalePendingBookingAlert({
    required this.bookingId,
    required this.paymentReference,
    required this.createdAt,
    required this.status,
  });

  final String bookingId;
  final String paymentReference;
  final DateTime createdAt;
  final String status;
}

class BookingPaymentStatus {
  const BookingPaymentStatus({
    required this.bookingId,
    required this.status,
    required this.depositPaid,
    required this.paymentReference,
  });

  final String bookingId;
  final String status;
  final bool depositPaid;
  final String paymentReference;
}

class AppwriteBookingRepository {
  AppwriteBookingRepository({
    required AppwriteConfig config,
    required AppwriteClientFactory clientFactory,
  }) : _config = config,
       _tablesDb = clientFactory.createTablesDb(),
       _functions = clientFactory.createFunctions();

  final AppwriteConfig _config;
  final TablesDB _tablesDb;
  final Functions _functions;

  Future<List<AppwriteBookingService>> fetchServices() async {
    final result = await _tablesDb.listRows(
      databaseId: _config.databaseId,
      tableId: _config.servicesCollectionId,
    );

    return result.rows.map(_mapService).toList(growable: false);
  }

  Future<String> createBooking({
    required AppwriteBookingService service,
    required String professionalRole,
    required DateTime date,
    required String timeSlot,
    required String fullName,
    required String phone,
    required String notes,
  }) async {
    final appointmentAt = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeSlot.split(':')[0]),
      int.parse(timeSlot.split(':')[1]),
    );

    final created = await _tablesDb.createRow(
      databaseId: _config.databaseId,
      tableId: _config.bookingsCollectionId,
      rowId: ID.unique(),
      data: {
        'serviceId': service.id,
        'serviceName': service.name,
        'servicePriceGhs': service.priceGhs,
        'serviceAudience': service.audience,
        'professionalRole': professionalRole,
        'reportingSegment': '${service.audience}_$professionalRole',
        'appointmentDate': _formatDate(date),
        'appointmentTime': timeSlot,
        'appointmentAt': appointmentAt.toIso8601String(),
        'customerName': fullName.trim(),
        'customerPhone': phone.trim(),
        'notes': notes.trim(),
        'status': 'pending',
        'source': 'mobile_app',
      },
    );

    return created.$id;
  }

  Future<PaystackInitResult> initializePaystackPayment({
    required String functionId,
    required String bookingId,
    required double amountGhs,
    required String email,
    required String phone,
    String? callbackUrl,
  }) async {
    final execution = await _functions.createExecution(
      functionId: functionId,
      xasync: false,
      method: enums.ExecutionMethod.pOST,
      body: jsonEncode({
        'bookingId': bookingId,
        'amount': amountGhs,
        'email': email,
        'phone': phone,
        if (callbackUrl != null && callbackUrl.trim().isNotEmpty)
          'callbackUrl': callbackUrl,
      }),
    );

    if (execution.responseStatusCode >= 400) {
      throw Exception(
        'Paystack init failed (${execution.responseStatusCode}): '
        '${execution.responseBody}',
      );
    }

    final dynamic decoded = jsonDecode(execution.responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected Paystack init response shape.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Paystack init response is missing data payload.');
    }

    final authorizationUrl = (data['authorization_url'] ?? '').toString();
    final accessCode = (data['access_code'] ?? '').toString();
    final reference = (data['reference'] ?? '').toString();

    if (authorizationUrl.isEmpty || reference.isEmpty || accessCode.isEmpty) {
      throw Exception('Paystack init response is incomplete.');
    }

    return PaystackInitResult(
      authorizationUrl: authorizationUrl,
      accessCode: accessCode,
      reference: reference,
    );
  }

  Future<List<StalePendingBookingAlert>> findStalePendingBookingsByPhone({
    required String phone,
    Duration minimumAge = const Duration(minutes: 15),
    int limit = 25,
  }) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      return const [];
    }

    final result = await _tablesDb.listRows(
      databaseId: _config.databaseId,
      tableId: _config.bookingsCollectionId,
      queries: [
        Query.equal('customerPhone', normalizedPhone),
        Query.limit(limit),
      ],
    );

    final now = DateTime.now().toUtc();
    final alerts = <StalePendingBookingAlert>[];

    for (final row in result.rows) {
      final paymentReference = (row.data['payment_ref'] ?? '')
          .toString()
          .trim();
      if (paymentReference.isEmpty) {
        continue;
      }

      if (row.data['deposit_paid'] == true) {
        continue;
      }

      final status = (row.data['status'] ?? '').toString().trim().toLowerCase();
      if (status != 'pending') {
        continue;
      }

      final createdAt = DateTime.tryParse(row.$createdAt)?.toUtc();
      if (createdAt == null) {
        continue;
      }

      if (now.difference(createdAt) < minimumAge) {
        continue;
      }

      alerts.add(
        StalePendingBookingAlert(
          bookingId: row.$id,
          paymentReference: paymentReference,
          createdAt: createdAt,
          status: status,
        ),
      );
    }

    alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return alerts;
  }

  Future<BookingPaymentStatus> fetchBookingPaymentStatus({
    required String bookingId,
  }) async {
    final row = await _tablesDb.getRow(
      databaseId: _config.databaseId,
      tableId: _config.bookingsCollectionId,
      rowId: bookingId,
    );

    final status = (row.data['status'] ?? '').toString().trim().toLowerCase();
    final paymentReference = (row.data['payment_ref'] ?? '').toString().trim();

    return BookingPaymentStatus(
      bookingId: row.$id,
      status: status,
      depositPaid: row.data['deposit_paid'] == true,
      paymentReference: paymentReference,
    );
  }

  AppwriteBookingService _mapService(models.Row row) {
    final data = row.data;

    final name = _readString(
      data,
      keys: const ['name', 'title', 'serviceName'],
      fallback: 'Service ${row.$id}',
    );

    final durationMinutes = _readInt(
      data,
      keys: const ['durationMinutes', 'duration', 'duration_mins'],
      fallback: 45,
    );

    final priceGhs = _readDouble(
      data,
      keys: const ['priceGhs', 'price', 'price_ghs'],
      fallback: 0,
    );

    return AppwriteBookingService(
      id: row.$id,
      name: name,
      durationMinutes: durationMinutes,
      priceGhs: priceGhs,
      audience: _normalizeAudience(
        _readString(
          data,
          keys: const ['audience', 'serviceFor', 'gender', 'targetGender'],
          fallback: 'male',
        ),
      ),
    );
  }

  String _normalizeAudience(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'male' || normalized == 'female') {
      return normalized;
    }

    return 'unisex';
  }

  String _readString(
    Map<String, dynamic> data, {
    required List<String> keys,
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  int _readInt(
    Map<String, dynamic> data, {
    required List<String> keys,
    required int fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return fallback;
  }

  double _readDouble(
    Map<String, dynamic> data, {
    required List<String> keys,
    required double fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return fallback;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
