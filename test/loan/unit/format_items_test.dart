import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/tools/functions.dart';
import 'package:titan/l10n/app_localizations.dart';

/// `formatItems` summarises a loan's borrowed items for the cards. Only the
/// 0/1-item arm was ever exercised, so the 2-, 3- and many-item shapes — the
/// ones with the joining word and the "N others" tail — never ran.
///
/// The strings come from AppLocalizations, so the helper needs a real context;
/// the assertions stay on the item names and the two counts rather than on the
/// translated glue, which would just re-state the ARB file.
void main() {
  ItemQuantity qty(String id, String name, int quantity) => ItemQuantity(
    quantity: quantity,
    itemSimple: ItemSimple.empty().copyWith(id: id, name: name),
  );

  Future<String> format(WidgetTester tester, List<ItemQuantity> items) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        // The first frame resolves the delegate asynchronously and hands out
        // no AppLocalizations yet; only the second one can format.
        home: Builder(
          builder: (context) => AppLocalizations.of(context) == null
              ? const SizedBox.shrink()
              : Text(formatItems(items, context)),
        ),
      ),
    );
    // The delegate resolves on a later frame; until then `of` is null.
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsOneWidget);
    return tester.widget<Text>(find.byType(Text)).data!;
  }

  testWidgets('two items are joined by the localised conjunction', (
    tester,
  ) async {
    final text = await format(tester, [
      qty('i-1', 'Tente', 2),
      qty('i-2', 'Perceuse', 1),
    ]);

    expect(text, contains('Tente'));
    expect(text, contains('Perceuse'));
    expect(text, startsWith('2 '));
  });

  testWidgets('three items list every item', (tester) async {
    final text = await format(tester, [
      qty('i-1', 'Tente', 1),
      qty('i-2', 'Perceuse', 1),
      qty('i-3', 'Casque', 1),
    ]);

    expect(text, contains('Tente'));
    expect(text, contains('Perceuse'));
    expect(text, contains('Casque'));
  });

  testWidgets('more than three items collapse the tail into a count', (
    tester,
  ) async {
    final text = await format(tester, [
      qty('i-1', 'Tente', 1),
      qty('i-2', 'Perceuse', 1),
      qty('i-3', 'Casque', 1),
      qty('i-4', 'Corde', 1),
    ]);

    expect(text, contains('Tente'));
    expect(text, contains('Perceuse'));
    // The tail is a count of the remaining items (4 - 2 = 2), not their names.
    expect(text, contains('2'));
    expect(text, isNot(contains('Casque')));
    expect(text, isNot(contains('Corde')));
  });
}
