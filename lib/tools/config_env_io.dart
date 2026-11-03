import 'dart:io';

/// True inside `flutter test`, which runs every isolate with `FLUTTER_TEST=true`
/// in the process environment. No real app build sets it, so production keeps
/// failing fast on missing config while the suite degrades gracefully.
final bool isFlutterTestEnv = Platform.environment['FLUTTER_TEST'] == 'true';
