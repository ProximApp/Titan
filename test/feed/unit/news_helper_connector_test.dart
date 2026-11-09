import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/tools/news_helper.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/l10n/app_localizations.dart';

/// The multi-day connector of `getNewsSubtitle`: it narrows `dateBetweenDays`
/// to `dateTo` while the event's last day is within one day of today.
///
/// The two keys are the same word in English ("to"), so this file renders the
/// subtitle in FRENCH, where `dateTo` is "à" and `dateBetweenDays` is "au".
/// That is the only way to tell the arms apart from the outside.
///
/// Kept in its own file (and its own isolate) because the French delegate has
/// to be the FIRST localization the tree loads: reusing another test's en_US
/// `MaterialApp` leaves the builder un-run for the frame that matters.
void main() {
  News newsOf({required DateTime start, required DateTime end}) =>
      News.empty().copyWith(
        id: 'n-1',
        title: 'News',
        start: start,
        end: end,
        entity: 'BDE',
        module: '',
      );

  Future<String> frenchSubtitle(WidgetTester tester, News news) async {
    String captured = '';
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr', 'FR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', 'FR')],
          home: Builder(
            builder: (context) {
              captured = getNewsSubtitle(news, context: context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return captured;
  }

  testWidgets('the connector narrows to "à" when the event ends today', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Started three days ago and ended at midnight today: not ongoing (its
    // end is in the past), so it reaches the multi-day branch, where the
    // difference between the end day and today is 0.
    final endsToday = newsOf(
      start: today.subtract(const Duration(days: 3)),
      end: today,
    );
    final text = await frenchSubtitle(tester, endsToday);
    expect(text, startsWith('De '));
    expect(text, contains(' à '), reason: 'dateTo, not dateBetweenDays');
  });

  testWidgets('the connector stays "au" when the event ends weeks later', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Both dates in the future, so it is neither ongoing nor same-day: the
    // difference is 30 days and the "between days" key is used.
    final endsLater = newsOf(
      start: today.add(const Duration(days: 10)),
      end: today.add(const Duration(days: 30)),
    );
    expect(await frenchSubtitle(tester, endsLater), contains(' au '));
  });
}
