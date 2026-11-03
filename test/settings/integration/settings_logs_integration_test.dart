import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/settings/ui/pages/log_page/log_card.dart';
import 'package:titan/tools/logs/log.dart';
import 'package:titan/tools/logs/logger_output.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

/// The log page reads from the logger's output, not the repository: a fake
/// LoggerOutput keeps the shell hermetic (the real one opens a file on IO).
class FakeLoggerOutput implements LoggerOutput {
  final List<Log> logs;
  final List<Log> notificationLogs;

  /// Counts the reads so a test can assert the pull-to-refresh reloaded.
  int getLogsCalls = 0;
  int getNotificationLogsCalls = 0;

  FakeLoggerOutput({this.logs = const [], this.notificationLogs = const []});

  @override
  Future<void> init() async {}

  @override
  void writeLog(Log log) {}

  @override
  List<Log> getLogs() {
    getLogsCalls++;
    return logs;
  }

  @override
  List<Log> getNotificationLogs() {
    getNotificationLogsCalls++;
    return notificationLogs;
  }

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
            // The fifth level falls through the color chain to the final
            // yellow branch (log_card line 22).
            Log(
              message: 'new announcement',
              level: LogLevel.notification,
              time: DateTime(2026, 9, 28, 15),
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
      expect(find.text('new announcement'), findsOneWidget);
      // The log cards are gone — the tab content swapped.
      expect(find.text('cache refreshed'), findsNothing);
    },
  );

  testWidgets(
    'the profile edit modal saves phone changes through usersMePatch',
    (tester) async {
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      when(() => scaffold.repository.notificationTopicsGet())
          .thenAnswer((_) async => chopperListResponse(<TopicUser>[]));
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
      when(() => scaffold.repository.usersMePatch(body: any(named: 'body')))
          .thenAnswer((_) async => chopperResponseVoid());
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

  testWidgets(
    'the birthday field opens the date picker and saves the picked day',
    (tester) async {
      scaffold.setWideSurface(tester);
      scaffold.stubProfilePicture();
      when(() => scaffold.repository.notificationTopicsGet())
          .thenAnswer((_) async => chopperListResponse(<TopicUser>[]));
      final me = CoreUser.empty().copyWith(
        email: 'me@myemapp.com',
        phone: '0699887766',
        birthday: DateTime(2004, 1, 1),
      );

      await scaffold.pumpApp(
        tester,
        scaffold.makeContainer(user: me, seedAsyncUser: true),
        initialPath: '/settings',
      );
      await settle(tester, frames: 8);

      await scaffold.openModal(tester, find.text('Profile'));

      // Tapping the DateEntry fires getOnlyDayDate → showDatePicker
      // (edit_profile's onTap closure and its date arguments).
      await tester.tap(find.text('Birthday'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Pick a day (the picker opens on initialDate = 2004) and confirm:
      // the controller takes the locale-formatted value.
      await tester.tap(find.text('20'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);

      // Phone is unchanged, so the save guard's second operand (the
      // birthday emptiness line) is the one evaluated.
      when(() => scaffold.repository.usersMePatch(body: any(named: 'body')))
          .thenAnswer((_) async => chopperResponseVoid());
      await tester.dragUntilVisible(
        find.text('Confirm'),
        find.byType(SingleChildScrollView).last,
        const Offset(0, -200),
      );
      await tester.tap(find.text('Confirm'));
      await settle(tester, frames: 10);

      expect(find.text('Account edited'), findsOneWidget);
      expect(scaffold.isModalOpen(tester), isFalse);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  /// The debug and warning fixtures also paint the two card color branches
  /// the render-only test never hit (only error/info levels were fed).
  Log debugLog() => Log(
    message: 'debug trace',
    level: LogLevel.debug,
    time: DateTime(2026, 9, 28, 9),
  );

  Log warningLog() => Log(
    message: 'cache is stale',
    level: LogLevel.warning,
    time: DateTime(2026, 9, 28, 10),
  );

  testWidgets('a log card copies its message to the clipboard and toasts', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    scaffold.stubProfilePicture();
    scaffold.stubClipboard(tester);
    scaffold.stubLoggerOutput(
      FakeLoggerOutput(logs: [debugLog(), warningLog()]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings/logs',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    // Both new levels render their cards (color branches built).
    expect(find.text('debug trace'), findsOneWidget);
    expect(find.text('cache is stale'), findsOneWidget);

    final firstCard = find.byType(LogCard).first;
    await tester.tap(
      find.descendant(of: firstCard, matching: find.byType(HeroIcon)),
    );
    await settle(tester, frames: 4);

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    expect(data?.text, 'debug trace');
    expect(find.text('Copied!'), findsOneWidget);
    // Drain the toast auto-close timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('each tab trash clears its logs after the confirmation', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    scaffold.stubProfilePicture();
    scaffold.stubLoggerOutput(
      FakeLoggerOutput(logs: [warningLog()], notificationLogs: [debugLog()]),
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings/logs',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);

    // The trash button is the only HeroIcon in the tab header row (the
    // header reads 'Logs'; 'Log' alone is the tab chip).
    final logTrash = find.ancestor(
      of: find.text('Logs'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: logTrash, matching: find.byType(HeroIcon)),
    );
    await settle(tester, frames: 4);
    expect(find.text('Delete logs?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 6);
    expect(find.text('cache is stale'), findsNothing);

    // Same flow on the notification tab.
    await tester.tap(find.text('Notification'));
    await settle(tester, frames: 8);
    expect(find.text('debug trace'), findsOneWidget);

    final notifTrash = find.ancestor(
      of: find.text('Notifications'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: notifTrash, matching: find.byType(HeroIcon)),
    );
    await settle(tester, frames: 4);
    expect(find.text('Delete notification logs?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await settle(tester, frames: 6);
    expect(find.text('debug trace'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the log page reloads both tabs through pull to refresh', (
    tester,
  ) async {
    scaffold.setWideSurface(tester);
    scaffold.stubProfilePicture();
    final output = FakeLoggerOutput(
      logs: List.generate(
        30,
        (i) => Log(
          message: 'log entry $i',
          level: LogLevel.info,
          time: DateTime(2026, 9, 28, i % 24),
        ),
      ),
    );
    scaffold.stubLoggerOutput(output);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(),
      initialPath: '/settings/logs',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 12);
    expect(output.getLogsCalls, 1);

    // The 30 cards overflown the surface, which is what arms the Cupertino
    // refresh control in a test.
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(output.getLogsCalls, greaterThan(1));
    expect(tester.takeException(), isNull);
  });
}
