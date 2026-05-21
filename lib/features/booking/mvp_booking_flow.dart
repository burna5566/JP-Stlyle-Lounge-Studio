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

class _MvpBookingFlowState extends State<MvpBookingFlow> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  final List<BookingService> _fallbackServices = const [
    BookingService(
      id: 'skin-fade',
      name: 'Skin Fade',
      durationMinutes: 45,
      priceGhs: 80,
      audience: 'male',
    ),
    BookingService(
      id: 'haircut-beard',
      name: 'Haircut + Beard Trim',
      durationMinutes: 60,
      priceGhs: 120,
      audience: 'male',
    ),
    BookingService(
      id: 'kids-cut',
      name: 'Kids Haircut',
      durationMinutes: 35,
      priceGhs: 60,
      audience: 'male',
    ),
    BookingService(
      id: 'braids-styling',
      name: 'Braids Styling',
      durationMinutes: 90,
      priceGhs: 180,
      audience: 'female',
    ),
    BookingService(
      id: 'silk-press',
      name: 'Silk Press + Trim',
      durationMinutes: 75,
      priceGhs: 160,
      audience: 'female',
    ),
  ];

  late final List<DateTime> _availableDates;
  final List<String> _availableTimeSlots = const [
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  int _currentStep = 0;
  ServiceAudienceFilter _audienceFilter = ServiceAudienceFilter.male;
  ProfessionalRole _selectedProfessionalRole = ProfessionalRole.barber;
  bool _isLoadingServices = false;
  bool _isSubmittingBooking = false;
  String? _servicesError;

  AppwriteBookingRepository? _bookingRepository;
  List<BookingService> _services = const [];

  BookingService? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

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
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('JP Style Lounge Studio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Book Appointment', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Complete the booking steps below. Services are grouped for male and female clients, including barber and hairdresser offerings.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _statusCard(theme),
            const SizedBox(height: 16),
            Stepper(
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
          ],
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
        ...filteredServices.map((service) {
          final selected = _selectedService?.id == service.id;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(service.name),
              subtitle: Text(
                '${service.durationMinutes} min · GHc ${service.priceGhs.toStringAsFixed(0)}',
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: Color(0xFF1B5E20))
                  : null,
              onTap: () => setState(() => _selectedService = service),
            ),
          );
        }),
      ],
    );
  }

  Widget _dateTimeSelector(ThemeData theme) {
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
              onSelected: (_) => setState(() => _selectedDate = date),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Time', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTimeSlots.map((slot) {
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
          callbackUrl: Env.paystackCallbackUrl,
        );

        final didLaunch = await launchUrl(
          Uri.parse(payment.authorizationUrl),
          mode: LaunchMode.platformDefault,
        );

        if (!didLaunch) {
          throw Exception('Could not open Paystack checkout URL.');
        }
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

  void _showError(String message) {
    final composed = _servicesError == null
        ? message
        : '$message\n${_servicesError!}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(composed)));
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
}
