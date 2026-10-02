import 'package:flutter_test/flutter_test.dart';
import 'package:titan/service/class/message.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/logs/logger.dart';

import '../../shared/app_scaffold.dart';

/// [Logger]'s level threshold — the filter that decides what is written at
/// all.
///
/// The audit: `minimalLogLevel` defaulted to `LogLevel.warning` and
/// `writeLog` drops `log.level.index < minimalLogLevel.index`, so
/// `info` (and `debug`) were accepted by [Logger.info]/[Logger.debug] and
/// then thrown away without ever reaching the output. The app has exactly
/// one `logger.info` call — setUpNotification's "Firebase messaging token
/// registered" — so the app's only informational diagnostic never landed in
/// the log file, the settings log page, or the console.
///
/// [UninitialisedLogger] deliberately never marks itself ready, which is what
/// the shipped test harness's `_StubLogger` does (and what any real logger
/// does when its output init throws). Writes are queued until init settles,
/// so these tests await a microtask before reading the capture.
class UninitialisedLogger extends Logger {
  UninitialisedLogger(CapturingLoggerOutput output) {
    loggerOutput = output;
  }

  @override
  Future<void> init() async {}
}

void main() {
  /// Lets the queued-write flush run (init's future, then the flush).
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('Logger level threshold', () {
    test('the default floor keeps info and drops debug', () async {
      final output = CapturingLoggerOutput();
      final logger = UninitialisedLogger(output);

      logger.debug('a debug line');
      logger.info('an info line');
      logger.warning('a warning line');
      logger.error('an error line');
      logger.logNotification(
        Message(
          title: 'a notification line',
          content: 'body',
          actionModule: null,
          actionTable: null,
        ),
      );
      await flush();

      // The regression: `info` used to be dropped by the `warning` default.
      expect(output.logs.map((l) => l.level).toList(), [
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]);
      expect(output.logs.map((l) => l.message).toList(), [
        'an info line',
        'a warning line',
        'an error line',
      ]);
      // `debug` is still below the floor: nothing in the app writes it.
      expect(output.logs.where((l) => l.level == LogLevel.debug), isEmpty);
      // `logNotification` serialises the whole Message, not its title.
      expect(output.notifications, hasLength(1));
      expect(output.notifications.single.level, LogLevel.notification);
      expect(
        output.notifications.single.message,
        contains('a notification line'),
      );
    });

    test('raising the floor drops the levels below it', () async {
      final output = CapturingLoggerOutput();
      final logger = UninitialisedLogger(output)
        ..minimalLogLevel = LogLevel.error;

      logger.info('an info line');
      logger.warning('a warning line');
      logger.error('an error line');
      await flush();

      expect(output.logs.map((l) => l.message).toList(), ['an error line']);
    });

    test('writeLog honours the floor for direct Log writes too', () async {
      final output = CapturingLoggerOutput();
      final logger = UninitialisedLogger(output);

      logger.writeLog(Log(message: 'raw info', level: LogLevel.info));
      logger.writeLog(Log(message: 'raw debug', level: LogLevel.debug));
      await flush();

      expect(output.logs.map((l) => l.message).toList(), ['raw info']);
    });

    test('a queued write is flushed once, not re-queued forever', () async {
      final output = CapturingLoggerOutput();
      final logger = UninitialisedLogger(output);

      logger.info('queued while uninitialised');
      // Two microtask turns is enough for the flush to land; the old code
      // re-queued writeLog from init's future on every pass and never settled
      // (an unhandled, unending microtask loop) for a logger whose init()
      // never flags itself ready.
      await flush();
      await flush();

      expect(output.logs.map((l) => l.message).toList(), [
        'queued while uninitialised',
      ]);
    });

    test('a dropped log is never queued', () async {
      final output = CapturingLoggerOutput();
      final logger = UninitialisedLogger(output)
        ..minimalLogLevel = LogLevel.error;

      logger.debug('never queued');
      await flush();
      await flush();

      expect(output.logs, isEmpty);
    });

    test('getLogs/clearLogs go through to the output', () async {
      final output = CapturingLoggerOutput();
      final logger = UninitialisedLogger(output);

      logger.info('a line');
      await flush();

      expect(logger.getLogs().map((l) => l.message).toList(), ['a line']);
      logger.clearLogs();
      expect(logger.getLogs(), isEmpty);
    });
  });
}
