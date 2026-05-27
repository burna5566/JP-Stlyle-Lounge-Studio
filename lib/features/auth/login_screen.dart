import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_notifier.dart';
import '../../shared/widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthStateAuthenticated) {
        final user = next.user;
        context.go(user.isBarber || user.isAdmin ? '/dashboard' : '/home');
      } else if (next is AuthStateNeedsProfile) {
        context.go('/profile-setup');
      } else if (next is AuthStateUnauthenticated && next.isGuest) {
        context.go('/home');
      } else if (next is AuthStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isWorking = authState is AuthStateWorking;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _Header(),
              const SizedBox(height: 32),
              _TabBar(controller: _tab),
              const SizedBox(height: 24),
              SizedBox(
                height: 340,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _PhoneTab(isWorking: isWorking),
                    _EmailTab(isWorking: isWorking),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Divider(),
              const SizedBox(height: 12),
              // _GoogleButton(isWorking: isWorking), // TODO: Uncomment when Google OAuth ready
              const SizedBox(height: 20),
              _GuestButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Welcome 👋',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Sign in to book your next session with Paps James.',
          style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: const Color(0xFF006B3F),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Phone'),
          Tab(text: 'Email'),
        ],
      ),
    );
  }
}

// ── Phone Tab ─────────────────────────────────────────────────────────────────

class _PhoneTab extends ConsumerStatefulWidget {
  const _PhoneTab({required this.isWorking});
  final bool isWorking;

  @override
  ConsumerState<_PhoneTab> createState() => _PhoneTabState();
}

class _PhoneTabState extends ConsumerState<_PhoneTab> {
  final _phoneController = TextEditingController(text: '+233');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authNotifierProvider.notifier)
        .sendPhoneOtp(_phoneController.text.trim());
    context.push('/otp');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+233XXXXXXXXX',
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().length < 10) {
                return 'Enter a valid phone number (e.g. +233244123456)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send OTP',
            isWorking: widget.isWorking,
            onPressed: _sendOtp,
          ),
        ],
      ),
    );
  }
}

// ── Email Tab ─────────────────────────────────────────────────────────────────

class _EmailTab extends ConsumerStatefulWidget {
  const _EmailTab({required this.isWorking});
  final bool isWorking;

  @override
  ConsumerState<_EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends ConsumerState<_EmailTab> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authNotifierProvider.notifier)
        .signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            obscureText: _obscure,
            validator: (v) =>
                (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/register'),
              child: const Text(
                'Create account',
                style: TextStyle(color: Color(0xFF006B3F)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Sign In',
            isWorking: widget.isWorking,
            onPressed: _signIn,
          ),
        ],
      ),
    );
  }
}

// ── Google (disabled for now; requires Appwrite SDK update) ─────────────────

// class _GoogleButton extends ConsumerWidget {
//   const _GoogleButton({required this.isWorking});
//   final bool isWorking;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return SizedBox(
//       width: double.infinity,
//       height: 50,
//       child: OutlinedButton.icon(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: Colors.white,
//           side: const BorderSide(color: Colors.white24),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white70),
//         label: const Text('Continue with Google'),
//         onPressed: isWorking
//             ? null
//             : () {
//                 ref
//                     .read(authNotifierProvider.notifier)
//                     .signInWithGoogle(
//                       successUrl: 'jpstylelounge://auth-callback',
//                       failureUrl: 'jpstylelounge://auth-callback?error=true',
//                     );
//               },
//       ),
//     );
//   }
// }

// ── Guest ──────────────────────────────────────────────────────────────────────

class _GuestButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton(
        onPressed: () {
          ref.read(authNotifierProvider.notifier).continueAsGuest();
          context.go('/home');
        },
        child: const Text(
          'Continue as Guest',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: Colors.white38)),
        ),
        Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }
}
