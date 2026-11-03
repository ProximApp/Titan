import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/logs/file_logger_output.dart';
import 'package:titan/tools/logs/log.dart';

void main() {
  group('Log', () {
    test('toString formats time, level and message', () {
      final log = Log(
        message: 'hello',
        level: LogLevel.warning,
        time: DateTime(2026, 9, 25, 12, 30),
      );

      expect(log.toString(), '2026-09-25T12:30:00.000 | WARNING | hello');
    });

    test('copyWith overrides only the given fields', () {
      final log = Log(message: 'a', level: LogLevel.info);
      final copy = log.copyWith(message: 'b', level: LogLevel.error);

      expect(copy.message, 'b');
      expect(copy.level, LogLevel.error);
      expect(copy.time, log.time);
    });

    test('Log.empty has an empty debug message', () {
      final log = Log.empty();

      expect(log.message, '');
      expect(log.level, LogLevel.debug);
    });
  });

  group('FileLoggerOutput escaping', () {
    test('logToEscapedString escapes pipes and semicolons', () {
      final output = FileLoggerOutput();
      final log = Log(
        message: 'a|b;c',
        level: LogLevel.info,
        time: DateTime(2026, 1, 2, 3, 4, 5),
      );

      expect(
        output.logToEscapedString(log),
        '2026-01-02T03:04:05.000 | INFO | a-bc;',
      );
    });

    test('round-trips through the escaped string format', () {
      final output = FileLoggerOutput();
      final log = Log(
        message: 'payment of 12.30 done',
        level: LogLevel.notification,
        time: DateTime(2026, 3, 4, 5, 6, 7),
      );

      final escaped = output.logToEscapedString(log);
      final parsed = FileLoggerOutput.logFromEscapedString(
        escaped.substring(0, escaped.length - 1),
      );

      expect(parsed.message, log.message);
      expect(parsed.level, log.level);
      expect(parsed.time, log.time);
    });

    test('parses an empty string into an empty log', () {
      final log = FileLoggerOutput.logFromEscapedString('');

      expect(log.message, '');
      expect(log.level, LogLevel.debug);
    });

    test('returns an error log when parsing fails', () {
      final log = FileLoggerOutput.logFromEscapedString('garbage');

      expect(log.level, LogLevel.error);
      expect(log.message, contains('Parsing log'));
    });

    test('logsFromEscapedString returns logs most-recent first', () {
      final logs = FileLoggerOutput.logsFromEscapedString(
        '2026-01-01T00:00:00.000 | INFO | first;'
        '2026-01-02T00:00:00.000 | ERROR | second;',
      );

      expect(logs, hasLength(2));
      expect(logs.first.message, 'second');
      expect(logs.last.message, 'first');
    });

    test('logsFromEscapedString ignores the trailing separator', () {
      final logs = FileLoggerOutput.logsFromEscapedString('');

      expect(logs, isEmpty);
    });
  });
}
