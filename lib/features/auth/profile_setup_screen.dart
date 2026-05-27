import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_notifier.dart';
import '../../shared/widgets/auth_widgets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+233');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authNotifierProvider);
    if (authState is! AuthStateNeedsProfile) return;

    final phone = _phoneController.text.trim();
    ref
        .read(authNotifierProvider.notifier)
        .completeProfile(
          userId: authState.accountUser.$id,
          name: _nameController.text.trim(),
          phone: phone.length > 4 ? phone : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthStateAuthenticated) {
        context.go(next.user.isBarber ? '/dashboard' : '/home');
      } else if (next is AuthStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    // Pre-fill name from account if available
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthStateNeedsProfile) {
      final accountName = authState.accountUser.name;
      if (_nameController.text.isEmpty && accountName.isNotEmpty) {
        _nameController.text = accountName;
      }
      final pendingPhone = authState.pendingPhone;
      if (pendingPhone != null && _phoneController.text == '+233') {
        _phoneController.text = pendingPhone;
      }
    }

    final isWorking = authState is AuthStateWorking;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF006B3F),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Almost there!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us your name so Paps James knows who is coming.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                AuthField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Kwame Mensah',
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                AuthField(
                  controller: _phoneController,
                  label: 'Phone Number (optional)',
                  hint: '+233XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    // Allow empty (just the +233 prefix)
                    if (v == null || v.trim() == '+233' || v.trim().isEmpty) {
                      return null;
                    }
                    if (v.trim().length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: 'Save & Continue',
                  isWorking: isWorking,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
