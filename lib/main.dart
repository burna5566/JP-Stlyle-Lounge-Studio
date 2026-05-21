import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  await dotenv.load(
    fileName: kAppEnv == 'development' ? '.env.development' : '.env.production',
  );

  await NotificationService.instance.initialize(
    backgroundHandler: firebaseMessagingBackgroundHandler,
  );

  final appwriteConfigValid = RuntimeGuard.verifyAppwriteConfig();

  runApp(JpStyleLoungeStudioApp(appwriteConfigValid: appwriteConfigValid));
}

class JpStyleLoungeStudioApp extends StatelessWidget {
  const JpStyleLoungeStudioApp({required this.appwriteConfigValid, super.key});

  final bool appwriteConfigValid;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.create(appwriteConfigValid: appwriteConfigValid);

    return MaterialApp.router(
      title: 'JP Style Lounge Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
