import 'dart:io';

void main(List<String> args) {
  final failOnWarning = args.contains('--fail-on-warning');
  final blockers = <String>[];
  final warnings = <String>[];

  _checkFileExists(
    path: 'ios/Runner/PrivacyInfo.xcprivacy',
    onMissing: 'Missing ios/Runner/PrivacyInfo.xcprivacy.',
    blockers: blockers,
  );

  _checkInfoPlist(blockers: blockers, warnings: warnings);
  _checkAndroidReleaseSigning(blockers: blockers);
  _checkAppCompletenessSignal(blockers: blockers);
  _checkCompliancePack(blockers: blockers, warnings: warnings);

  stdout.writeln('Store readiness audit summary');
  stdout.writeln('Blockers: ${blockers.length}');
  stdout.writeln('Warnings: ${warnings.length}');
  stdout.writeln('Fail on warning: $failOnWarning');

  if (blockers.isNotEmpty) {
    stdout.writeln('\nBlockers:');
    for (final item in blockers) {
      stdout.writeln('- $item');
    }
  }

  if (warnings.isNotEmpty) {
    stdout.writeln('\nWarnings:');
    for (final item in warnings) {
      stdout.writeln('- $item');
    }
  }

  if (blockers.isNotEmpty || (failOnWarning && warnings.isNotEmpty)) {
    exitCode = 1;
  }
}

void _checkFileExists({
  required String path,
  required String onMissing,
  required List<String> blockers,
}) {
  if (!File(path).existsSync()) {
    blockers.add(onMissing);
  }
}

void _checkInfoPlist({
  required List<String> blockers,
  required List<String> warnings,
}) {
  final plistFile = File('ios/Runner/Info.plist');
  if (!plistFile.existsSync()) {
    blockers.add('Missing ios/Runner/Info.plist.');
    return;
  }

  final content = plistFile.readAsStringSync();
  final requiredKeys = <String>[
    'NSCameraUsageDescription',
    'NSPhotoLibraryUsageDescription',
    'NSPhotoLibraryAddUsageDescription',
    'NSLocationWhenInUseUsageDescription',
    'UIBackgroundModes',
  ];

  for (final key in requiredKeys) {
    if (!content.contains('<key>$key</key>')) {
      blockers.add('Info.plist missing $key.');
    }
  }

  if (!content.contains('remote-notification')) {
    warnings.add(
      'Info.plist does not declare remote-notification background mode value.',
    );
  }
}

void _checkAndroidReleaseSigning({required List<String> blockers}) {
  final gradleFile = File('android/app/build.gradle.kts');
  if (!gradleFile.existsSync()) {
    blockers.add('Missing android/app/build.gradle.kts.');
    return;
  }

  final content = gradleFile.readAsStringSync();

  if (content.contains('signingConfig = signingConfigs.getByName("debug")')) {
    blockers.add('Android release build still uses debug signing config.');
  }

  if (!content.contains('key.properties')) {
    blockers.add('Android release signing is not wired to key.properties.');
  }
}

void _checkAppCompletenessSignal({required List<String> blockers}) {
  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    blockers.add('Missing lib/main.dart.');
    return;
  }

  final content = mainFile.readAsStringSync();
  if (content.contains('Runtime data only')) {
    blockers.add('App still appears to present runtime placeholder shell.');
  }
}

void _checkCompliancePack({
  required List<String> blockers,
  required List<String> warnings,
}) {
  final requiredFiles = <String>[
    'docs/store/PLAY_DATA_SAFETY_MATRIX.md',
    'docs/store/APP_STORE_PRIVACY_MATRIX.md',
    'docs/store/PRIVACY_AND_DELETION.md',
  ];

  for (final path in requiredFiles) {
    if (!File(path).existsSync()) {
      blockers.add('Missing compliance artifact: $path');
    }
  }

  final deletionFile = File('docs/store/PRIVACY_AND_DELETION.md');
  if (deletionFile.existsSync()) {
    final content = deletionFile.readAsStringSync();
    if (content.contains('TODO')) {
      warnings.add(
        'Privacy/deletion document still contains TODO placeholders for required URLs.',
      );
    }
  }
}
