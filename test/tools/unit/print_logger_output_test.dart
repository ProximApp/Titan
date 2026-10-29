import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/logs/print_logger_output.dart';

void main() {
  test('the print output answers the whole LoggerOutput contract', () async {
    final output = PrintLoggerOutput();

    await output.init();
    // Print keeps nothing, so both log views read empty and the clear
    // methods are no-ops rather than errors.
    expect(output.getLogs(), isEmpty);
    expect(output.getNotificationLogs(), isEmpty);
    output.clearLogs();
    output.clearNotificationLogs();

    // writeLog prints the formatted `[time] | LEVEL | message` line —
    // captured through the zone because a bare print only reaches the
    // test's own output.
    var printed = '';
    runZoned(
      () => output.writeLog(Log(message: 'boom', level: LogLevel.error)),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => printed = line,
      ),
    );
    expect(printed, contains('ERROR | boom'));
  });
}
