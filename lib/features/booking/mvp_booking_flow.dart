import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/appwrite/appwrite_client_factory.dart';
import '../../core/appwrite/appwrite_config.dart';
import '../../core/env/env.dart';
import 'appwrite_booking_repository.dart';

class BookingService {
  const BookingService({
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

enum ServiceAudienceFilter { male, female }

enum ProfessionalRole { barber, hairdresser }

class MvpBookingFlow extends StatefulWidget {
  const MvpBookingFlow({required this.appwriteConfigValid, super.key});

  final bool appwriteConfigValid;

  @override
  State<MvpBookingFlow> createState() => _MvpBookingFlowState();
}

class _MvpBookingFlowState extends State<MvpBookingFlow>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  final List<BookingService> _fallbackServices = const [
    BookingService(
      id: 'haircut',
      name: 'Haircut',
      durationMinutes: 45,
      priceGhs: 70,
      audience: 'unisex',
    ),
    BookingService(
      id: 'haircut-dye',
      name: 'Haircut & Dye',
      durationMinutes: 90,
      priceGhs: 100,
      audience: 'unisex',
    ),
    BookingService(
      id: 'permcut',
      name: 'Permcut',
      durationMinutes: 60,
      priceGhs: 80,
      audience: 'unisex',
    ),
    BookingService(
      id: 'kids-haircut',
      name: 'Kids',
      durationMinutes: 35,
      priceGhs: 50,
      audience: 'unisex',
    ),
    BookingService(
      id: 'shape-shave',
      name: 'Shape & Shave',
      durationMinutes: 45,
      priceGhs: 50,
      audience: 'unisex',
    ),
    BookingService(
      id: 'texturalize',
      name: 'Texturalize',
      durationMinutes: 60,
      priceGhs: 50,
      audience: 'unisex',
    ),
    BookingService(
      id: 'dye-only',
      name: 'Dye Only',
      durationMinutes: 60,
      priceGhs: 50,
      audience: 'unisex',
    ),
    BookingService(
      id: 'bleach',
      name: 'Bleach',
      durationMinutes: 120,
      priceGhs: 200,
      audience: 'unisex',
    ),
    BookingService(
      id: 'colour-dye',
      name: 'Colour Dye',
      durationMinutes: 90,
      priceGhs: 100,
      audience: 'unisex',
    ),
    BookingService(
      id: 'appointment-booking',
      name: 'Appointment Booking',
      durationMinutes: 30,
      priceGhs: 150,
      audience: 'unisex',
    ),
  ];

  late final List<DateTime> _availableDates;
  final List<String> _weekdayTimeSlots = const [
    '08:30',
    '09:30',
    '10:30',
    '11:30',
    '12:30',
    '13:30',
    '14:30',
    '15:30',
    '16:30',
    '17:30',
    '18:30',
    '19:30',
    '20:30',
  ];

  final List<String> _sundayTimeSlots = const [
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  int _currentStep = 0;
  ServiceAudienceFilter _audienceFilter = ServiceAudienceFilter.male;
  ProfessionalRole _selectedProfessionalRole = ProfessionalRole.barber;
  bool _isLoadingServices = false;
  bool _isSubmittingBooking = false;
  bool _isCheckingStalePending = false;
  String? _servicesError;
  String? _stalePendingError;

  AppwriteBookingRepository? _bookingRepository;
  List<BookingService> _services = const [];

  BookingService? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<StalePendingBookingAlert> _stalePendingAlerts = const [];
  Timer? _stalePendingDebounce;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _paymentReturnSub;
  String? _pendingPaymentBookingId;
  String? _pendingPaymentReference;
  bool _isVerifyingPaymentReturn = false;

  List<BookingService> get _filteredServices {
    final target = _audienceFilter.name;
    return _services
        .where(
          (service) =>
              service.audience == target || service.audience == 'unisex',
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final now = DateTime.now();
    _availableDates = List<DateTime>.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day + index),
    );
    _selectedDate = _availableDates.first;

    _services = _fallbackServices;

    if (widget.appwriteConfigValid) {
      final config = AppwriteConfig.fromEnv();
      final factory = AppwriteClientFactory(config);
      _bookingRepository = AppwriteBookingRepository(
        config: config,
        clientFactory: factory,
      );
      _loadServicesFromAppwrite();
      _phoneController.addListener(_onPhoneChangedForStaleGuard);
    }

    if (!kIsWeb) {
      unawaited(_setupPaymentReturnHandling());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stalePendingDebounce?.cancel();
    _paymentReturnSub?.cancel();
    _phoneController.removeListener(_onPhoneChangedForStaleGuard);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || kIsWeb) {
      return;
    }

    // When app resumes (e.g., after Paystack browser closes), wait a moment
    // for Appwrite webhook to process the payment, then verify.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        unawaited(_verifyReturnedPayment(source: 'resume'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('JP Style Lounge Studio')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Book Appointment', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Complete the booking steps below. Services are grouped for male and female clients, including barber and hairdresser offerings.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _statusCard(theme),
              const SizedBox(height: 12),
              Expanded(
                child: Stepper(
                  physics: const ClampingScrollPhysics(),
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  onStepContinue: () {
                    _onStepContinue();
                  },
                  onStepCancel: _onStepCancel,
                  controlsBuilder: (context, details) {
                    return Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isSubmittingBooking
                              ? null
                              : details.onStepContinue,
                          child: Text(
                            _currentStep == 3
                                ? (_isSubmittingBooking
                                      ? 'Submitting...'
                                      : 'Confirm booking')
                                : 'Continue',
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ],
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Choose service'),
                      isActive: _currentStep >= 0,
                      content: _serviceSelector(theme),
                    ),
                    Step(
                      title: const Text('Pick date and time'),
                      isActive: _currentStep >= 1,
                      content: _dateTimeSelector(theme),
                    ),
                    Step(
                      title: const Text('Your details'),
                      isActive: _currentStep >= 2,
                      content: _detailsForm(theme),
                    ),
                    Step(
                      title: const Text('Review and confirm'),
                      isActive: _currentStep >= 3,
                      content: _reviewCard(theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(ThemeData theme) {
    final valid = widget.appwriteConfigValid;

    return Card(
      color: valid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          valid
              ? 'Runtime config status: VALID. Appwrite sync enabled.'
              : 'Runtime config status: INVALID. Set .env values before connecting to live backend.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valid ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _serviceSelector(ThemeData theme) {
    final filteredServices = _filteredServices;
    final screenHeight = MediaQuery.of(context).size.height;
    final servicesPanelHeight = screenHeight < 760
        ? screenHeight * 0.32
        : screenHeight * 0.38;

    if (_isLoadingServices) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredServices.isEmpty) {
      return Text(
        'No services found for this category yet. Check Appwrite service audience values.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Client category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Male (Barber)'),
              selected: _audienceFilter == ServiceAudienceFilter.male,
              onSelected: (_) => _setAudienceFilter(ServiceAudienceFilter.male),
            ),
            ChoiceChip(
              label: const Text('Female (Hairdresser)'),
              selected: _audienceFilter == ServiceAudienceFilter.female,
              onSelected: (_) =>
                  _setAudienceFilter(ServiceAudienceFilter.female),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 120,
            maxHeight: servicesPanelHeight,
          ),
          child: Scrollbar(
            thumbVisibility: filteredServices.length > 4,
            child: ListView.builder(
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                final selected = _selectedService?.id == service.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    title: Text(service.name),
                    subtitle: Text(
                      '${service.durationMinutes} min · GHc ${service.priceGhs.toStringAsFixed(0)}',
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1B5E20),
                          )
                        : null,
                    onTap: () => setState(() => _selectedService = service),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateTimeSelector(ThemeData theme) {
    final activeTimeSlots = _timeSlotsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableDates.map((date) {
            final selected = _selectedDate == date;
            return ChoiceChip(
              label: Text('${date.day}/${date.month}'),
              selected: selected,
              onSelected: (_) => setState(() {
                _selectedDate = date;

                final nextSlots = _timeSlotsForDate(_selectedDate);
                if (!nextSlots.contains(_selectedTimeSlot)) {
                  _selectedTimeSlot = null;
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Card(
          color: const Color(0xFFF3E5F5),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'Opening hours: Monday-Saturday 08:30-21:00, Sunday 14:00-21:00',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Time', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeTimeSlots.map((slot) {
            return ChoiceChip(
              label: Text(slot),
              selected: _selectedTimeSlot == slot,
              onSelected: (_) => setState(() => _selectedTimeSlot = slot),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _detailsForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your full name'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone (+233...)'),
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.trim().length < 8
                ? 'Enter a valid phone number'
                : null,
          ),
          const SizedBox(height: 12),
          _stalePendingGuardCard(theme),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty || !text.contains('@')) {
                return 'Enter a valid email address';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProfessionalRole>(
            initialValue: _selectedProfessionalRole,
            decoration: const InputDecoration(labelText: 'Professional role'),
            items: const [
              DropdownMenuItem(
                value: ProfessionalRole.barber,
                child: Text('Barber'),
              ),
              DropdownMenuItem(
                value: ProfessionalRole.hairdresser,
                child: Text('Hairdresser'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() => _selectedProfessionalRole = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${_selectedService?.name ?? '-'}'),
            const SizedBox(height: 6),
            Text(
              'Date: ${_selectedDate != null ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' : '-'}',
            ),
            const SizedBox(height: 6),
            Text('Time: ${_selectedTimeSlot ?? '-'}'),
            const SizedBox(height: 6),
            Text(
              'Client: ${_fullNameController.text.isEmpty ? '-' : _fullNameController.text}',
            ),
            const SizedBox(height: 6),
            Text(
              'Phone: ${_phoneController.text.isEmpty ? '-' : _phoneController.text}',
            ),
            const SizedBox(height: 6),
            Text(
              'Email: ${_emailController.text.isEmpty ? '-' : _emailController.text}',
            ),
            const SizedBox(height: 6),
            Text(
              'Estimated total: GHc ${_selectedService?.priceGhs.toStringAsFixed(0) ?? '-'}',
            ),
            const SizedBox(height: 6),
            Text(
              'Category: ${_selectedService == null ? '-' : _audienceLabelFromValue(_selectedService!.audience)}',
            ),
            const SizedBox(height: 6),
            Text(
              'Professional role: ${_professionalRoleLabel(_selectedProfessionalRole)}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStepContinue() async {
    if (_currentStep == 0) {
      if (_selectedService == null) {
        _showError('Please select a service first.');
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (_selectedDate == null || _selectedTimeSlot == null) {
        _showError('Please select date and time.');
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) {
        return;
      }
      setState(() => _currentStep = 3);
      return;
    }

    await _confirmBooking();
  }

  void _onStepCancel() {
    if (_currentStep == 0) {
      return;
    }

    setState(() => _currentStep -= 1);
  }

  Future<void> _confirmBooking() async {
    if (_selectedService == null ||
        _selectedDate == null ||
        _selectedTimeSlot == null) {
      _showError('Booking details are incomplete.');
      return;
    }

    final repository = _bookingRepository;
    if (repository == null) {
      _showError('Appwrite booking is not available. Check runtime config.');
      return;
    }

    setState(() => _isSubmittingBooking = true);

    try {
      final selectedService = AppwriteBookingService(
        id: _selectedService!.id,
        name: _selectedService!.name,
        durationMinutes: _selectedService!.durationMinutes,
        priceGhs: _selectedService!.priceGhs,
        audience: _selectedService!.audience,
      );

      final bookingId = await repository.createBooking(
        service: selectedService,
        professionalRole: _selectedProfessionalRole.name,
        date: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        notes: _notesController.text,
      );

      if (Env.enablePayments) {
        final functionId = Env.paystackInitFunctionId.trim();
        if (functionId.isEmpty) {
          throw Exception(
            'Payments are enabled but APPWRITE_PAYSTACK_INIT_FUNCTION_ID is empty.',
          );
        }

        final payment = await repository.initializePaystackPayment(
          functionId: functionId,
          bookingId: bookingId,
          amountGhs: selectedService.priceGhs,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          callbackUrl: _resolvePaystackCallbackUrl(bookingId: bookingId),
        );

        _pendingPaymentBookingId = bookingId;
        _pendingPaymentReference = payment.reference;

        // Handle redirect based on platform
        await _redirectToPaystackCheckout(payment.authorizationUrl);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Env.enablePayments
                ? 'Booking created. Redirecting to Paystack...'
                : 'Booking submitted to Appwrite.',
          ),
        ),
      );

      setState(() {
        _currentStep = 0;
        _selectedService = null;
        _selectedTimeSlot = null;
        _fullNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _notesController.clear();
        _selectedDate = _availableDates.first;
        _selectedProfessionalRole =
            _audienceFilter == ServiceAudienceFilter.male
            ? ProfessionalRole.barber
            : ProfessionalRole.hairdresser;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Booking submission failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmittingBooking = false);
      }
    }
  }

  Future<void> _loadServicesFromAppwrite() async {
    final repository = _bookingRepository;
    if (repository == null) {
      return;
    }

    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
    });

    try {
      final appwriteServices = await repository.fetchServices();
      if (!mounted) {
        return;
      }

      final mapped = appwriteServices
          .map(
            (service) => BookingService(
              id: service.id,
              name: service.name,
              durationMinutes: service.durationMinutes,
              priceGhs: service.priceGhs,
              audience: service.audience,
            ),
          )
          .toList(growable: false);

      setState(() {
        _services = mapped.isEmpty ? _fallbackServices : mapped;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _services = _fallbackServices;
        _servicesError = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

  Widget _stalePendingGuardCard(ThemeData theme) {
    final hasPhone = _phoneController.text.trim().length >= 8;
    final hasAlerts = _stalePendingAlerts.isNotEmpty;
    final hasError = (_stalePendingError ?? '').isNotEmpty;

    if (!hasPhone && !hasAlerts && !hasError && !_isCheckingStalePending) {
      return const SizedBox.shrink();
    }

    if (_isCheckingStalePending) {
      return Card(
        color: const Color(0xFFE3F2FD),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Checking for unfinished payments linked to this phone...',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasError) {
      return Card(
        color: const Color(0xFFFFF8E1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Could not check pending payments right now: ${_stalePendingError!}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6D4C41),
            ),
          ),
        ),
      );
    }

    if (!hasAlerts) {
      return const SizedBox.shrink();
    }

    final first = _stalePendingAlerts.first;
    return Card(
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment follow-up needed',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFBF360C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Found ${_stalePendingAlerts.length} pending booking(s) with unpaid deposits for this phone number.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Most recent booking: ${first.bookingId} (ref: ${first.paymentReference})',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    final composed = _servicesError == null
        ? message
        : '$message\n${_servicesError!}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(composed)));
  }

  void _onPhoneChangedForStaleGuard() {
    final repository = _bookingRepository;
    if (repository == null) {
      return;
    }

    final phone = _phoneController.text.trim();
    _stalePendingDebounce?.cancel();

    if (phone.length < 8) {
      if (_stalePendingAlerts.isNotEmpty || _stalePendingError != null) {
        setState(() {
          _stalePendingAlerts = const [];
          _stalePendingError = null;
          _isCheckingStalePending = false;
        });
      }
      return;
    }

    _stalePendingDebounce = Timer(
      const Duration(milliseconds: 650),
      () => _checkForStalePendingBookings(phone),
    );
  }

  Future<void> _checkForStalePendingBookings(String phone) async {
    final repository = _bookingRepository;
    if (repository == null || !mounted) {
      return;
    }

    setState(() {
      _isCheckingStalePending = true;
      _stalePendingError = null;
    });

    try {
      final alerts = await repository.findStalePendingBookingsByPhone(
        phone: phone,
      );

      if (!mounted || _phoneController.text.trim() != phone) {
        return;
      }

      setState(() {
        _stalePendingAlerts = alerts;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stalePendingAlerts = const [];
        _stalePendingError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingStalePending = false);
      }
    }
  }

  void _setAudienceFilter(ServiceAudienceFilter filter) {
    setState(() {
      _audienceFilter = filter;
      _selectedProfessionalRole = filter == ServiceAudienceFilter.male
          ? ProfessionalRole.barber
          : ProfessionalRole.hairdresser;

      final selected = _selectedService;
      if (selected == null) {
        return;
      }

      final stillVisible = _filteredServices.any(
        (service) => service.id == selected.id,
      );

      if (!stillVisible) {
        _selectedService = null;
      }
    });
  }

  String _audienceLabelFromValue(String audience) {
    if (audience == 'female') {
      return 'Female (Hairdresser)';
    }
    if (audience == 'male') {
      return 'Male (Barber)';
    }

    return 'Unisex';
  }

  String _professionalRoleLabel(ProfessionalRole role) {
    switch (role) {
      case ProfessionalRole.barber:
        return 'Barber';
      case ProfessionalRole.hairdresser:
        return 'Hairdresser';
    }
  }

  Future<void> _setupPaymentReturnHandling() async {
    _appLinks ??= AppLinks();

    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) {
        await _handlePaymentReturnUri(initial, source: 'initial-link');
      }
    } on Object {
      // Ignore startup link errors and rely on resume checks.
    }

    _paymentReturnSub = _appLinks!.uriLinkStream.listen(
      (uri) => _handlePaymentReturnUri(uri, source: 'stream-link'),
      onError: (_) {
        // Ignore stream errors and rely on resume checks.
      },
    );
  }

  Future<void> _handlePaymentReturnUri(
    Uri uri, {
    required String source,
  }) async {
    final isMatch =
        uri.scheme == 'jpstylelounge' && uri.host == 'payment-return';
    if (!isMatch) {
      return;
    }

    final bookingId = (uri.queryParameters['bookingId'] ?? '').trim();
    final reference = (uri.queryParameters['reference'] ?? '').trim();
    if (bookingId.isNotEmpty) {
      _pendingPaymentBookingId = bookingId;
    }
    if (reference.isNotEmpty) {
      _pendingPaymentReference = reference;
    }

    await _verifyReturnedPayment(source: source);
  }

  Future<void> _verifyReturnedPayment({required String source}) async {
    if (_isVerifyingPaymentReturn) {
      return;
    }

    final repository = _bookingRepository;
    final bookingId = _pendingPaymentBookingId;
    if (repository == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    setState(() => _isVerifyingPaymentReturn = true);
    try {
      final status = await repository.fetchBookingPaymentStatus(
        bookingId: bookingId,
      );

      if (!mounted) {
        return;
      }

      if (status.depositPaid || status.status == 'confirmed') {
        final reference = status.paymentReference.isNotEmpty
            ? status.paymentReference
            : (_pendingPaymentReference ?? 'n/a');

        _pendingPaymentBookingId = null;
        _pendingPaymentReference = null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment confirmed ($reference). Booking is now secured.',
            ),
          ),
        );

        final phone = _phoneController.text.trim();
        if (phone.length >= 8) {
          unawaited(_checkForStalePendingBookings(phone));
        }
      } else if (source != 'resume') {
        final reference = _pendingPaymentReference ?? status.paymentReference;
        final referenceText = reference.isEmpty ? '' : ' ($reference)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment still pending$referenceText. We will auto-check again when you return to the app.',
            ),
          ),
        );
      }
    } on Object catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifyingPaymentReturn = false);
      }
    }
  }

  String _resolvePaystackCallbackUrl({required String bookingId}) {
    // Keep web behavior unchanged so Paystack returns to the web app directly.
    if (kIsWeb) {
      return Uri.base.origin;
    }

    final platform = defaultTargetPlatform;
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    if (!isMobile) {
      return '';
    }

    // On mobile, use a hosted success page that can deep-link back to the app.
    final configured = Env.paystackCallbackUrl.trim();
    if (configured.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(configured);
    if (parsed == null ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      return '';
    }

    final query = Map<String, String>.from(parsed.queryParameters);
    query['bookingId'] = bookingId;

    // If configured URL already points to a page, keep it.
    if (parsed.path.isNotEmpty && parsed.path != '/') {
      return parsed.replace(queryParameters: query).toString();
    }

    // Otherwise append the standard mobile success page path.
    final basePath = parsed.path.endsWith('/')
        ? parsed.path
        : '${parsed.path}/';
    return parsed
        .replace(
          path: '${basePath}payment-success.html',
          queryParameters: query,
        )
        .toString();
  }

  Future<void> _redirectToPaystackCheckout(String authorizationUrl) async {
    if (kIsWeb) {
      final didLaunch = await launchUrl(
        Uri.parse(authorizationUrl),
        webOnlyWindowName: '_self',
      );
      if (!didLaunch) {
        throw Exception('Could not open Paystack checkout URL on web.');
      }
      return;
    } else {
      // On mobile platforms, use url_launcher
      final didLaunch = await launchUrl(
        Uri.parse(authorizationUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!didLaunch) {
        throw Exception('Could not open Paystack checkout URL.');
      }
    }
  }

  List<String> _timeSlotsForDate(DateTime? date) {
    final effectiveDate = date ?? DateTime.now();
    final isSunday = effectiveDate.weekday == DateTime.sunday;
    return isSunday ? _sundayTimeSlots : _weekdayTimeSlots;
  }
}
