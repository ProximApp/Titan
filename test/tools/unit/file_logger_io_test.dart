import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/logs/file_logger_output.dart';
import 'package:titan/tools/logs/log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('titan_file_logger_io');
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

  test('every method guards against an uninitialized output', () {
    final output = FileLoggerOutput();
    output.writeLog(Log(message: 'lost', level: LogLevel.info));
    expect(output.getLogs(), isEmpty);
    expect(output.getNotificationLogs(), isEmpty);
    output.clearLogs();
    output.clearNotificationLogs();
  });

  test('init writes, reads back and clears logs by kind', () async {
    final output = FileLoggerOutput();
    await output.init();
    output
      ..writeLog(Log(message: 'plain', level: LogLevel.info))
      ..writeLog(Log(message: 'secret|with;pipes', level: LogLevel.warning))
      ..writeLog(Log(message: 'pinged', level: LogLevel.notification));

    final plain = output.getLogs().map((l) => l.message).toList();
    expect(plain, unorderedEquals(['plain', 'secret-withpipes']));
    expect(output.getNotificationLogs().map((l) => l.message), ['pinged']);

    output.clearLogs();
    expect(output.getLogs(), isEmpty);
    expect(output.getNotificationLogs().map((l) => l.message), ['pinged']);

    output.clearNotificationLogs();
    expect(output.getNotificationLogs(), isEmpty);
  });

  test('clearNotificationLogs keeps the regular logs', () async {
    final output = FileLoggerOutput();
    await output.init();
    output
      ..writeLog(Log(message: 'plain', level: LogLevel.info))
      ..writeLog(Log(message: 'pinged', level: LogLevel.notification));

    output.clearNotificationLogs();
    expect(output.getLogs().map((l) => l.message), ['plain']);
    expect(output.getNotificationLogs(), isEmpty);
  });
}
