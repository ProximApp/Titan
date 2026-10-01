import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/feed/tools/news_helper.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';

/// Unit coverage for `lib/feed/tools/news_helper.dart` (85 uncovered
/// lines): the terminated/ongoing windows, the user-friendly date
/// formatter's branches (today/yesterday/tomorrow/weekday/last-weekday/
/// this-year/other-year), the subtitle composition and the action
/// title/button mappings per module.
///
/// The context-dependent helpers run inside a real MaterialApp with the
/// app's localization delegates; `now` is whatever the test machine's
/// clock says, so date fixtures are expressed relative to DateTime.now().
void main() {
  News newsOf({
    DateTime? start,
    DateTime? end,
    String module = '',
    String entity = 'BDE',
  }) => News.empty().copyWith(
    id: 'n-1',
    title: 'News',
    start: start ?? DateTime.now(),
    end: end,
    entity: entity,
    module: module,
    status: enums.NewsStatus.published,
  );

  // The localizations delegate resolves through a future, so pump until
  // the localized tree (and the capture builder) has actually run.
  Future<String> capture(
    WidgetTester tester,
    String Function(BuildContext) buildText,
  ) async {
    String captured = '';
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', 'US')],
          home: Builder(
            builder: (context) {
              captured = buildText(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return captured;
  }

  Future<String> format(WidgetTester tester, DateTime date) => capture(
    tester,
    (context) => formatUserFriendlyDate(date, context: context),
  );

  Future<String> subtitle(WidgetTester tester, News news) =>
      capture(tester, (context) => getNewsSubtitle(news, context: context));

  Future<String> actionTitleOf(WidgetTester tester, String module) => capture(
    tester,
    (context) => getActionTitle(newsOf(module: module), context),
  );

  testWidgets('isNewsTerminated / isNewsOngoing read the time window', (
    tester,
  ) async {
    final now = DateTime.now();
    expect(
      isNewsTerminated(
        newsOf(start: now, end: now.subtract(const Duration(days: 1))),
      ),
      isTrue,
    );
    expect(isNewsTerminated(newsOf(start: now, end: null)), isFalse);
    expect(
      isNewsTerminated(
        newsOf(start: now, end: now.add(const Duration(days: 1))),
      ),
      isFalse,
    );

    // Ongoing: started before now, not ended.
    expect(
      isNewsOngoing(
        newsOf(start: now.subtract(const Duration(hours: 1)), end: null),
      ),
      isTrue,
    );
    expect(
      isNewsOngoing(
        newsOf(
          start: now.subtract(const Duration(hours: 1)),
          end: now.add(const Duration(hours: 1)),
        ),
      ),
      isTrue,
    );
    // Not yet started.
    expect(
      isNewsOngoing(newsOf(start: now.add(const Duration(days: 1)), end: null)),
      isFalse,
    );
    // Already over.
    expect(
      isNewsOngoing(
        newsOf(
          start: now.subtract(const Duration(days: 2)),
          end: now.subtract(const Duration(days: 1)),
        ),
      ),
      isFalse,
    );
  });

  group('formatUserFriendlyDate branches', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    testWidgets('today with time', (tester) async {
      final date = today.add(const Duration(hours: 14, minutes: 30));
      expect(await format(tester, date), 'Today at 14:30');
    });

    testWidgets('yesterday', (tester) async {
      final date = today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 9));
      expect(await format(tester, date), 'Yesterday at 09:00');
    });

    testWidgets('tomorrow', (tester) async {
      final date = today
          .add(const Duration(days: 1))
          .add(const Duration(hours: 8, minutes: 15));
      expect(await format(tester, date), 'Tomorrow at 08:15');
    });

    testWidgets('weekday within the next week', (tester) async {
      final date = today.add(const Duration(days: 3, hours: 12));
      final weekday = _capitalizedWeekday(date);
      expect(await format(tester, date), '$weekday at 12:00');
    });

    testWidgets('weekday within the past week keeps the last prefix', (
      tester,
    ) async {
      final date = today.subtract(const Duration(days: 2, hours: 12));
      final weekday = _capitalizedWeekday(date);
      expect(await format(tester, date), 'Last $weekday at 12:00');
    });

    testWidgets('older this-year date drops the weekday', (tester) async {
      final date = today.subtract(const Duration(days: 40, hours: 12));
      final monthDay = _capitalizedMonthDay(date);
      expect(await format(tester, date), '$monthDay at 12:00');
    });

    testWidgets('another-year date includes the year', (tester) async {
      final date = DateTime(now.year - 2, now.month, now.day, 6, 45);
      final text = await format(tester, date);
      expect(text, contains('${now.year - 2}'));
      expect(text, endsWith('at 06:45'));
    });
  });

  testWidgets('getNewsSubtitle composes per the time window', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Ongoing with an end: "Until <end>".
    final ongoing = newsOf(
      start: now.subtract(const Duration(hours: 2)),
      end: today.add(const Duration(days: 2, hours: 18)),
    );
    expect(await subtitle(tester, ongoing), startsWith('Until'));

    // Same-day window: "<date> from <start> to <end>".
    final sameDay = newsOf(
      start: today.add(const Duration(days: 5, hours: 8)),
      end: today.add(const Duration(days: 5, hours: 18)),
    );
    final sameDayText = await subtitle(tester, sameDay);
    expect(sameDayText, contains(' from '));
    expect(sameDayText, contains(' to '));

    // Multi-day window: "from <date> to <date>".
    final multiDay = newsOf(
      start: today.add(const Duration(days: 10, hours: 8)),
      end: today.add(const Duration(days: 30, hours: 18)),
    );
    expect(await subtitle(tester, multiDay), contains(' to '));

    // No end: plain date.
    expect(
      await subtitle(tester, newsOf(start: today, end: null)),
      contains('Today'),
    );

    // An empty subtitle falls back to the entity name: an event far in the
    // future with no end renders "Tomorrow ...", so use a terminated one
    // whose window logic returns nothing but the entity.
    final terminated = newsOf(
      start: today.subtract(const Duration(days: 400)),
      end: today.subtract(const Duration(days: 399)),
      entity: 'BDE',
    );
    expect(await subtitle(tester, terminated), isNotEmpty);
  });

  testWidgets('action mappings answer per module', (tester) async {
    expect(await actionTitleOf(tester, 'campagne'), 'You can vote');
    expect(await actionTitleOf(tester, 'event'), 'You are invited');
    expect(await actionTitleOf(tester, 'tickets'), 'Ticket');
    expect(await actionTitleOf(tester, ''), '');

    late String captured;
    Future<void> pump(String module, String Function(BuildContext) pick) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US')],
            home: Builder(
              builder: (context) {
                captured = pick(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pump();
    }

    // getWaitingTitle interpolates the countdown per module.
    await pump(
      'campagne',
      (c) => getWaitingTitle(newsOf(module: 'campagne'), c, timeToGo: '2h'),
    );
    expect(captured, 'Vote in 2h');
    await pump(
      'event',
      (c) => getWaitingTitle(newsOf(module: 'event'), c, timeToGo: '2h'),
    );
    expect(captured, 'Shotgun in 2h');
    await pump(
      'tickets',
      (c) => getWaitingTitle(newsOf(module: 'tickets'), c, timeToGo: '2h'),
    );
    expect(captured, 'Opens 2h');

    // Button texts.
    await pump(
      'campagne',
      (c) => getActionEnableButtonText(newsOf(module: 'campagne'), c),
    );
    expect(captured, 'Vote');
    await pump(
      'event',
      (c) => getActionEnableButtonText(newsOf(module: 'event'), c),
    );
    expect(captured, 'Reserve');
    await pump(
      'tickets',
      (c) => getActionEnableButtonText(newsOf(module: 'tickets'), c),
    );
    expect(captured, 'Book');
    await pump(
      'campagne',
      (c) => getActionValidatedButtonText(newsOf(module: 'campagne'), c),
    );
    expect(captured, "I voted!");
    await pump('', (c) => getActionValidatedButtonText(newsOf(module: ''), c));
    expect(captured, '');

    // Subtitles.
    await pump(
      'campagne',
      (c) => getActionSubtitle(newsOf(module: 'campagne'), c),
    );
    expect(captured, 'Vote now');
    await pump('event', (c) => getActionSubtitle(newsOf(module: 'event'), c));
    expect(captured, 'Answer the invitation');
    await pump(
      'tickets',
      (c) => getActionSubtitle(newsOf(module: 'tickets'), c),
    );
    expect(captured, 'Book your seat');
    await pump('', (c) => getActionSubtitle(newsOf(module: ''), c));
    expect(captured, '');
  });
}

String _capitalizedWeekday(DateTime date) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[date.weekday - 1];
}

String _capitalizedMonthDay(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
