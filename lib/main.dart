import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/appwrite/runtime_guard.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'firebase_options.dart';

const String _appEnvDefine = String.fromEnvironment('APP_ENV');
const String _environmentDefine = String.fromEnvironment('ENVIRONMENT');
final String kAppEnv = _resolveAppEnv();

String _resolveAppEnv() {
  if (_appEnvDefine.isNotEmpty) {
    return _appEnvDefine;
  }

  if (_environmentDefine.isNotEmpty) {
    return _environmentDefine;
  }

  return 'production';
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(
      fileName: kAppEnv == 'development'
          ? '.env.development'
          : '.env.production',
    );

    await NotificationService.instance.initialize(
      backgroundHandler: firebaseMessagingBackgroundHandler,
    );

    final appwriteConfigValid = RuntimeGuard.verifyAppwriteConfig();

    runApp(
      ProviderScope(
        child: JpStyleLoungeStudioApp(appwriteConfigValid: appwriteConfigValid),
      ),
    );
  } on Object catch (error, stackTrace) {
    debugPrint('App startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      ProviderScope(
        child: JpStyleLoungeStudioApp(
          appwriteConfigValid: false,
          startupError: 'Startup failed: $error',
        ),
      ),
    );
  }
}

class JpStyleLoungeStudioApp extends StatelessWidget {
  const JpStyleLoungeStudioApp({
    required this.appwriteConfigValid,
    this.startupError,
    super.key,
  });

  final bool appwriteConfigValid;
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return MaterialApp(
        title: 'JP Style Lounge Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Scaffold(
          appBar: AppBar(title: const Text('JP Style Lounge Studio')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              startupError!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    // Router needs a Ref to read auth state for redirect guards.
    // We use a Consumer to get the ref inside build.
    return Consumer(
      builder: (context, ref, _) {
        final router = AppRouter.create(
          appwriteConfigValid: appwriteConfigValid,
          ref: ref as Ref,
        );
        return MaterialApp.router(
          title: 'JP Style Lounge Studio',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
        );
      },
    );
  }
}
