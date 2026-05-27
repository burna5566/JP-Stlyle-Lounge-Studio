import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_notifier.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      switch (next) {
        case AuthStateAuthenticated(:final user):
          if (user.isBarber || user.isAdmin) {
            context.go('/dashboard');
          } else {
            context.go('/home');
          }
        case AuthStateUnauthenticated(isGuest: true):
          context.go('/home');
        case AuthStateUnauthenticated():
          context.go('/onboarding');
        case AuthStateNeedsProfile():
          context.go('/profile-setup');
        case AuthStateLoading():
        case AuthStateWorking():
        case AuthStateError():
          break;
      }
    });

    final state = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Logo(),
            const SizedBox(height: 40),
            if (state is AuthStateError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  (state as AuthStateError).message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            else
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006B3F)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFF006B3F),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.content_cut, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 20),
        const Text(
          'JP Style Lounge',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Studio',
          style: TextStyle(
            color: Color(0xFF006B3F),
            fontSize: 16,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
