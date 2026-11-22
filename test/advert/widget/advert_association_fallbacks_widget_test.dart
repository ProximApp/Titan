import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/advert/ui/components/association_item.dart';
import 'package:titan/advert/ui/pages/main_page/advert_card.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/constants.dart';

import '../../shared/app_scaffold.dart';

/// The two places an advert falls back when its association cannot be looked
/// up: the card still paints (without the association's name) instead of
/// taking the page down with it, and the association item still paints its
/// initials — with the selection ring — instead of the logo circle.
///
/// The `catch` in `association_bar.dart`'s avatar-initials closure is dead and
/// stays uncovered on purpose: every call inside the `try` is already guarded
/// — `substring(0, 3)` only runs when the trimmed name is longer than three
/// characters, and `s[0]` only on parts the empty-filter kept — so nothing in
/// it can throw.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
  });

  testWidgets('an advert whose association list failed still renders', (
    tester,
  ) async {
    // Riverpod 3 retries a failing provider by default, which would keep the
    // list pending forever instead of letting the card see the error.
    final container = scaffold.makeContainer(retry: (count, error) => null);
    addTearDown(container.dispose);
    when(() => scaffold.repository.associationsGet())
        .thenThrow(Exception('no associations'));

    await scaffold.pumpWidgetApp(
      tester,
      AdvertCard(
        advert: AdvertComplete.empty().copyWith(
          id: 'a-1',
          title: 'Soldes du BDE',
          content: 'Toute la semaine',
          advertiserId: 'asso-unknown',
          date: DateTime(2026, 5, 1),
        ),
      ),
      container,
      surface: const ui.Size(500, 900),
    );

    // The title lives in a RichText (the card's expandable body), and the
    // fallback is the empty association name — not a crash, not a spinner.
    final body = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .join('|');
    expect(body, contains('Soldes du BDE'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a selected association without a logo keeps its ring', (
    tester,
  ) async {
    final container = scaffold.makeContainer(retry: (count, error) => null);
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.associationsAssociationIdLogoGet(
        associationId: any(named: 'associationId'),
      ),
    ).thenThrow(Exception('no logo'));

    await scaffold.pumpWidgetApp(
      tester,
      AssociationItem(
        name: 'BDE de Lille',
        avatarName: 'BL',
        associationId: 'asso-1',
        selected: true,
        onTap: () {},
      ),
      container,
    );

    // The initials stand in for the missing logo, inside the selection ring.
    expect(find.text('BL'), findsOneWidget);
    final circle = tester.widget<Container>(
      find
          .ancestor(of: find.text('BL'), matching: find.byType(Container))
          .first,
    );
    final decoration = circle.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect((decoration.border! as Border).top.color, ColorConstants.tertiary);
    expect(tester.takeException(), isNull);
  });
}
