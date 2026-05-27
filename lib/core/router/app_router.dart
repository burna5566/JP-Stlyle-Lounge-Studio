import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_notifier.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/booking/mvp_booking_flow.dart';
import '../../features/dashboard/barber_dashboard_screen.dart';
import '../../features/home/home_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create({
    required bool appwriteConfigValid,
    required WidgetRef ref,
  }) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, routerState) {
        final authState = ref.read(authNotifierProvider);
        final path = routerState.matchedLocation;

        // Always allow splash, onboarding, login, otp, register through
        const publicPaths = ['/', '/onboarding', '/login', '/otp', '/register'];

        if (publicPaths.contains(path)) return null;

        // profile-setup requires an account but no DB profile yet
        if (path == '/profile-setup') {
          if (authState is AuthStateNeedsProfile) return null;
          if (authState is AuthStateAuthenticated) return '/home';
          return '/login';
        }

        // Protected routes
        if (authState is AuthStateLoading || authState is AuthStateWorking) {
          return null; // let splash handle it
        }

        if (authState is AuthStateUnauthenticated) {
          // Guests are allowed on /home and /booking
          if (path == '/home' || path == '/booking') return null;
          return '/login';
        }

        if (authState is AuthStateNeedsProfile) return '/profile-setup';

        if (authState is AuthStateAuthenticated) {
          final user = authState.user;
          // Barbers redirected away from customer routes
          if ((user.isBarber || user.isAdmin) &&
              (path == '/home' || path == '/booking')) {
            return '/dashboard';
          }
          // Customers redirected away from barber dashboard
          if (user.isCustomer && path == '/dashboard') {
            return '/home';
          }
        }

        return null;
      },
      routes: [
        // Entry point — session check
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/profile-setup',
          builder: (_, _) => const ProfileSetupScreen(),
        ),
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/booking',
          builder: (context, state) =>
              MvpBookingFlow(appwriteConfigValid: appwriteConfigValid),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const BarberDashboardScreen(),
        ),
      ],
    );
  }
}
