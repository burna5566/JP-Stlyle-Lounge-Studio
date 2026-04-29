import 'package:flutter/material.dart';

const String kAppEnv = String.fromEnvironment('APP_ENV', defaultValue: 'production');
const bool kFreeMode = bool.fromEnvironment('FREE_MODE', defaultValue: false);

void main() {
  runApp(const JpStyleLoungeStudioApp());
}

class JpStyleLoungeStudioApp extends StatelessWidget {
  const JpStyleLoungeStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JP Style Lounge Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006B3F)),
        useMaterial3: true,
      ),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JP Style Lounge Studio',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  Text('Runtime data only', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Mode: ${kAppEnv.toUpperCase()} ${kFreeMode ? '(FREE)' : '(PAID)'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This build does not bundle barber profiles, services, or availability. Connect your backend and resolve the active business context at runtime before rendering booking flows.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
