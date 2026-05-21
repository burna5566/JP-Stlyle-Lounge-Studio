import 'dart:io';

Map<String, String> loadAppwriteEnvironment({
  String secretsFilePath = '.appwrite.secrets',
}) {
  final merged = Map<String, String>.from(Platform.environment);

  final file = File(secretsFilePath);
  if (!file.existsSync()) {
    return merged;
  }

  for (final rawLine in file.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    final exportPrefix = line.startsWith('export ') ? 'export ' : '';
    final normalized = exportPrefix.isEmpty ? line : line.substring(7).trim();
    final equalsIndex = normalized.indexOf('=');
    if (equalsIndex <= 0) {
      continue;
    }

    final key = normalized.substring(0, equalsIndex).trim();
    var value = normalized.substring(equalsIndex + 1).trim();

    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }

    if (key.isNotEmpty) {
      merged[key] = value;
    }
  }

  return merged;
}
