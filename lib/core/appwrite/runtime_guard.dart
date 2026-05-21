import 'package:flutter/foundation.dart';

import 'appwrite_config.dart';

class RuntimeGuard {
  RuntimeGuard._();

  static List<String> _lastErrors = const [];

  static List<String> get lastErrors => _lastErrors;

  static bool verifyAppwriteConfig() {
    final config = AppwriteConfig.fromEnv();
    final errors = config.validate();

    _lastErrors = errors;

    if (errors.isNotEmpty) {
      for (final error in errors) {
        debugPrint('Config error: $error');
      }
      return false;
    }

    return true;
  }
}
