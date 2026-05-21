import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../env/env.dart';

typedef BackgroundMessageHandler = Future<void> Function(RemoteMessage message);

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  Future<void> initialize({
    required BackgroundMessageHandler backgroundHandler,
  }) async {
    if (!Env.enablePushNotifications) {
      debugPrint('Push notifications disabled by environment.');
      return;
    }

    try {
      await _initializeFirebase();
      FirebaseMessaging.onBackgroundMessage(backgroundHandler);

      if (_shouldRequestPermission) {
        await FirebaseMessaging.instance.requestPermission();
      }

      if (!kIsWeb) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM token available: ${fcmToken != null}');
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Push notification initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  bool get _shouldRequestPermission {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }
}
