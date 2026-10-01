import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/logs/logger_output.dart';

import '../../shared/app_scaffold.dart';

/// The log page reads from the logger's output, not the repository: a fake
/// LoggerOutput keeps the shell hermetic (the real one opens a file on IO).
class FakeLoggerOutput implements LoggerOutput {
  final List<Log> logs;
  final List<Log> notificationLogs;

  FakeLoggerOutput({this.logs = const [], this.notificationLogs = const []});

  @override
  Future<void> init() async {}

  @override
  void writeLog(Log log) {}

  @override
  List<Log> getLogs() => logs;

  @override
  List<Log> getNotificationLogs() => notificationLogs;

  @override
  void clearLogs() {}

  @override
  void clearNotificationLogs() {}
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets(
    'deep link to /settings/logs renders log cards and switches to the notification tab',
    (tester) async {
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      scaffold.stubLoggerOutput(
        FakeLoggerOutput(
          logs: [
            Log(
              message: 'GET /feed failed',
              level: LogLevel.error,
              time: DateTime(2026, 9, 28, 12),
            ),
            Log(
              message: 'cache refreshed',
              level: LogLevel.info,
              time: DateTime(2026, 9, 28, 13),
            ),
          ],
          notificationLogs: [
            Log(
              message: 'push token registered',
              level: LogLevel.info,
              time: DateTime(2026, 9, 28, 14),
            ),
          ],
        ),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(),
        initialPath: '/settings/logs',
        pumpAndSettle: false,
      );
      await settle(tester, frames: 12);

      // Tab chips render (capitalize(enum.name)); the log tab is selected.
      expect(find.text('Log'), findsOneWidget);
      expect(find.text('Notification'), findsOneWidget);
      // Log cards render message + timestamp from the fake output.
      expect(find.text('GET /feed failed'), findsOneWidget);
      expect(find.text('cache refreshed'), findsOneWidget);
      expect(find.textContaining('2026-09-28 12'), findsOneWidget);
      // The notification tab is not mounted yet.
      expect(find.text('push token registered'), findsNothing);

      // Switch to the notification tab through the real chip.
      await tester.tap(find.text('Notification'));
      await settle(tester, frames: 8);

      expect(find.text('push token registered'), findsOneWidget);
      // The log cards are gone — the tab content swapped.
      expect(find.text('cache refreshed'), findsNothing);
    },
  );

  testWidgets(
    'the profile edit modal saves phone changes through usersMePatch',
    (tester) async {
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      when(
        () => scaffold.repository.notificationTopicsGet(),
      ).thenAnswer((_) async => chopperListResponse(<TopicUser>[]));
      // The save button is disabled until a field changes vs `me`, so the user
      // needs both phone and birthday set (birthday also gates `me.birthday!`).
      final me = CoreUser.empty().copyWith(
        email: 'me@myemapp.com',
        phone: '0699887766',
        birthday: DateTime(2004, 3, 15),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: me, seedAsyncUser: true),
        initialPath: '/settings',
      );
      await settle(tester, frames: 8);

      // Open the Edit account sheet through the real ListItem. The ListItem
      // subtitle and the modal title are the same text while the sheet is open.
      await scaffold.openModal(tester, find.text('Profile'));
      expect(find.text('Edit account'), findsNWidgets(2));
      // The form is prefilled from the signed-in user.
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);

      // Change the phone and save: the real usersMePatch fires.
      when(
        () => scaffold.repository.usersMePatch(body: any(named: 'body')),
      ).thenAnswer((_) async => chopperResponseVoid());
      await tester.enterText(find.byType(TextField).at(1), '0601020304');
      await settle(tester, frames: 4);
      // The sheet scrolls (isScrollControlled + EditProfile's
      // SingleChildScrollView) and Confirm sits below the fold: drag that
      // scrollable up before tapping — tester.tap silently drops taps on
      // off-screen widgets (deny-listed hit testers).
      await tester.dragUntilVisible(
        find.text('Confirm'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 10);

      // Success toast + the sheet self-closed.
      expect(find.text('Account edited'), findsOneWidget);
      expect(scaffold.isModalOpen(tester), isFalse);
      // Drain the toast timer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    },
  );
}
