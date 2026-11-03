import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tickets/ui/components/tarif_card.dart';

import '../../shared/app_scaffold.dart';

/// `TarifCard` (the ticket form's tariff rows) sat at 50/64 lines: nothing had
/// ever pressed "add a tariff", pressed a remove button, or handed the price
/// validator a value it rejects — the three branches the card exists for.
///
/// The card is also where the euro→cent conversion happens (the backend stores
/// `price` in cents), so the arithmetic is pinned here rather than trusted: a
/// `12,50` typed by a French user must leave as `1250`, and an unparseable
/// field must leave as `0` instead of throwing inside the parent form.
void main() {
  late IntegrationScaffold scaffold;
  late List<List<CategoryCreate>> emissions;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
    emissions = <List<CategoryCreate>>[];
  });

  Future<void> pumpCard(WidgetTester tester) async {
    final container = scaffold.makeContainer(userId: 'user-1');
    addTearDown(container.dispose);
    await pumpWidgetAt(
      tester,
      TarifCard(onChanged: emissions.add),
      container: container,
      surface: const ui.Size(600, 1200),
      appFonts: true,
    );
  }

  // Two fields per tariff: the label, then the price. The card has no quota
  // field of its own (the backend's `quota` stays null from this surface).
  Finder labelField([int i = 0]) => find.byType(TextFormField).at(i * 2);
  Finder priceField([int i = 0]) => find.byType(TextFormField).at(i * 2 + 1);

  testWidgets('adding a tariff appends a row and a remove button', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.byType(IconButton),
      findsNothing,
      reason: 'a single tariff has nothing to remove yet',
    );

    await tester.tap(find.byType(TextButton));
    await settle(tester, frames: 6);

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byType(IconButton), findsNWidgets(2));
    expect(
      emissions.last,
      hasLength(2),
      reason: 'the form must be told about the new row immediately',
    );

    await tester.tap(find.byType(IconButton).first);
    await settle(tester, frames: 6);

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(IconButton), findsNothing);
    expect(emissions.last, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tariff leaves the card priced in cents', (tester) async {
    await pumpCard(tester);

    await tester.enterText(labelField(), 'Famille');
    await tester.enterText(priceField(), '12,50');
    await settle(tester, frames: 4);

    final tariff = emissions.last.single;
    expect(tariff.name, 'Famille');
    expect(
      tariff.price,
      1250,
      reason: 'the UI collects euros; the backend stores cents',
    );
    expect(tariff.quota, isNull);
    expect(tariff.requiredMembership, isNull);

    // A dot decimal is the same amount, not a second reading of it.
    await tester.enterText(priceField(), '12.5');
    await settle(tester, frames: 4);
    expect(emissions.last.single.price, 1250);

    // Free text that never parses must degrade to 0 rather than throw inside
    // the parent form's onChanged.
    await tester.enterText(priceField(), 'offert');
    await settle(tester, frames: 4);
    expect(emissions.last.single.price, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the price validator rejects sub-euro prices only', (
    tester,
  ) async {
    await pumpCard(tester);

    final validator = tester.widget<TextFormField>(priceField()).validator!;

    expect(
      validator(''),
      isNotNull,
      reason: 'the field is required, so a blank price never reaches the rule',
    );
    expect(validator('0'), isNull, reason: 'a free tariff is a real tariff');
    expect(validator('2'), isNull);
    expect(validator('0,5'), isNotNull);
    expect(validator('0.5'), isNotNull);
    expect(
      validator('offert'),
      isNotNull,
      reason: 'TextEntry\'s isDouble check rejects the non-numeric field',
    );
    expect(tester.takeException(), isNull);
  });
}
