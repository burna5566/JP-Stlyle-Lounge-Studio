import 'package:flutter_test/flutter_test.dart';
import 'package:jp_style_lounge_studio/core/appwrite/runtime_guard.dart';

void main() {
  test('verifyAppwriteConfig fails when env keys are missing', () {
    final isValid = RuntimeGuard.verifyAppwriteConfig();

    expect(isValid, isFalse);
    expect(RuntimeGuard.lastErrors, isNotEmpty);
    expect(
      RuntimeGuard.lastErrors.any(
        (error) => error.contains('APPWRITE_ENDPOINT is required.'),
      ),
      isTrue,
    );
    expect(
      RuntimeGuard.lastErrors.any(
        (error) => error.contains('APPWRITE_PROJECT_ID is required.'),
      ),
      isTrue,
    );
  });
}
