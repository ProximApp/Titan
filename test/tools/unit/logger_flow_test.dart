import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/logs/logger.dart';

/// End-to-end through the real [Logger] (constructor kicks off `init`): the
/// file output is backed by a mocked path_provider, then logs are written,
/// read back by kind and cleared. The VM branch of `init` — `kIsWeb` is
/// always false under `flutter test`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('titan_logger_flow');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
            case 'getTemporaryDirectory':
              return dir.path;
          }
          return null;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('Logger initializes a file output and routes logs through it', () async {
    final logger = Logger();
    // The constructor already started init; run one more awaited pass so the
    // output exists and the pending queue has flushed.
    await logger.init();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    logger.info('written to the file output');
    expect(logger.getLogs(), isNotEmpty);

    expect(logger.getNotificationLogs(), isEmpty);
    logger.clearNotificationLogs();
    logger.clearLogs();
    expect(logger.getLogs(), isEmpty);

    logger.logException(Exception('kaboom'));
    expect(logger.getLogs().last.message, contains('kaboom'));
  });
}
