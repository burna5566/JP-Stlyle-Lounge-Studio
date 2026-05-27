import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_notifier.dart';

/// Customer home screen — serves as the app entry point post-login.
/// Sprint 2 will replace the body with Barber Profile + Service Catalog.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isGuest = authState is AuthStateUnauthenticated && authState.isGuest;
    final userName = authState is AuthStateAuthenticated
        ? authState.user.name
        : 'Guest';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'JP Style Lounge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
            ),
          if (isGuest)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Sign in',
                style: TextStyle(color: Color(0xFF006B3F)),
              ),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.content_cut, size: 64, color: Color(0xFF006B3F)),
              const SizedBox(height: 20),
              Text(
                'Hello, $userName 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Barber profile and service catalog\ncoming in Sprint 2.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B3F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => context.go('/booking'),
                ),
              ),
              if (isGuest) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => context.go('/login'),
                  child: const Text('Create Account for Booking History'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
