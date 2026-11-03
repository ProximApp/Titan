import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/tools/news_helper.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:intl/intl.dart';

import '../../shared/app_scaffold.dart';

/// `formatUserFriendlyDate` and `getNewsSubtitle` are pure string builders, but
/// every branch depends on how far a date is from "now": today, yesterday,
/// tomorrow, inside the week, inside the last week, this year, another year —
/// plus the same-day span that prints "from 20:00 to 02:00" instead of two
/// dates. Only two of those seven arms were reached.
///
/// The dates are built RELATIVE to now, because that is what the function
/// measures against: pinning literals would make the suite rot every month.
void main() {
  /// Renders [build] with a real BuildContext in an English locale, which is
  /// what the formatters need for their connectors.
  Future<String> render(
    WidgetTester tester,
    String Function(BuildContext context) build,
  ) async {
    late String value;
    await pumpWidgetAt(
      tester,
      Builder(
        builder: (context) {
          value = build(context);
          return const SizedBox();
        },
      ),
      locale: const Locale('en', 'US'),
    );
    return value;
  }

  final now = DateTime.now();
  DateTime daysFromNow(int days, {int hour = 20, int minute = 0}) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: days));
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  testWidgets('today, yesterday and tomorrow each name the day', (
    tester,
  ) async {
    expect(
      await render(tester, (c) => formatUserFriendlyDate(now, context: c)),
      contains('Today'),
    );
    expect(
      await render(
        tester,
        (c) => formatUserFriendlyDate(daysFromNow(-1), context: c),
      ),
      contains('Yesterday'),
    );
    expect(
      await render(
        tester,
        (c) => formatUserFriendlyDate(daysFromNow(1), context: c),
      ),
      contains('Tomorrow'),
    );
  });

  testWidgets('a date inside the coming week prints its weekday', (
    tester,
  ) async {
    final inThreeDays = daysFromNow(3);
    final expected = DateFormat.EEEE('en_US').format(inThreeDays);

    final value = await render(
      tester,
      (c) => formatUserFriendlyDate(inThreeDays, context: c),
    );
    // Capitalized weekday + the "at" connector + the time.
    expect(value.toLowerCase(), contains(expected.toLowerCase()));
    expect(value, contains('at'));
    expect(value, contains('20:00'));
  });

  testWidgets('a date inside the past week is prefixed as the last one', (
    tester,
  ) async {
    final threeDaysAgo = daysFromNow(-3);
    final weekday = DateFormat.EEEE('en_US').format(threeDaysAgo);

    final value = await render(
      tester,
      (c) => formatUserFriendlyDate(threeDaysAgo, context: c),
    );
    expect(value.toLowerCase(), contains(weekday.toLowerCase()));
    expect(value.toLowerCase(), contains('last'));
  });

  testWidgets('far dates fall back to month-day, and to the year when it '
      'differs', (tester) async {
    // Same year, far enough that no weekday shortcut applies.
    final thisYear = DateTime(now.year, 3, 14, 9, 30);
    final sameYear = await render(
      tester,
      (c) => formatUserFriendlyDate(thisYear, context: c),
    );
    // The label comes from the same formatter, so a locale/pattern change does
    // not rot the assertion.
    expect(sameYear, contains(DateFormat.MMMd('en_US').format(thisYear)));
    expect(sameYear, contains('09:30'));

    // A different year carries it explicitly.
    final lastYear = DateTime(now.year - 1, 3, 14, 9, 30);
    final otherYear = await render(
      tester,
      (c) => formatUserFriendlyDate(lastYear, context: c),
    );
    expect(otherYear, contains('${now.year - 1}'));
  });

  testWidgets('a same-day span reads as a from/to range, not two dates', (
    tester,
  ) async {
    final start = daysFromNow(30, hour: 20, minute: 0);
    final end = daysFromNow(30, hour: 23, minute: 30);
    final news = News.empty().copyWith(start: start, end: end);

    final subtitle = await render(
      tester,
      (c) => getNewsSubtitle(news, context: c),
    );

    expect(subtitle, contains('from'));
    expect(subtitle, contains('20:00'));
    expect(subtitle, contains('23:30'));
    // The same day is named ONCE: a range that repeats the date is wrong.
    final dayLabel = DateFormat.MMMd('en_US').format(start);
    expect(subtitle.split(dayLabel).length, 2, reason: subtitle);
  });

  testWidgets('a multi-day span shows both dates with the right connector', (
    tester,
  ) async {
    final start = daysFromNow(30);
    final end = daysFromNow(33);
    final news = News.empty().copyWith(start: start, end: end);

    final subtitle = await render(
      tester,
      (c) => getNewsSubtitle(news, context: c),
    );

    expect(subtitle, contains('From'));
    expect(subtitle.split('at').length, greaterThan(1));
  });

  testWidgets('an open-ended news item shows its start date alone', (
    tester,
  ) async {
    final news = News.empty().copyWith(start: daysFromNow(30), end: null);

    final subtitle = await render(
      tester,
      (c) => getNewsSubtitle(news, context: c),
    );

    expect(
      subtitle,
      contains(DateFormat.MMMd('en_US').format(daysFromNow(30))),
    );
    expect(subtitle, isNot(contains('From')));
  });
}
