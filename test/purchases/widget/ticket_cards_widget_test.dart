import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/purchases/ui/pages/main_page/custom_button.dart';
import 'package:titan/purchases/ui/pages/scan_page/ticket_card.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for the purchases scan-page cards: `CustomButton`
/// (plain stateless) and `TicketCard` (renders one or many scans and fires
/// the outer callback).
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  group('CustomButton', () {
    testWidgets('renders its label and fires onTap', (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      var taps = 0;

      await scaffold.pumpWidgetApp(
        tester,
        CustomButton(
          text: 'Admin tools',
          icon: HeroIcons.listBullet,
          onTap: () => taps++,
        ),
        container,
      );

      expect(find.text('Admin tools'), findsOneWidget);
      await tester.tap(find.text('Admin tools'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shrinks an overlong label and accepts a gradient', (
      tester,
    ) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        CustomButton(
          text: 'A very long label that cannot possibly fit on one line',
          icon: HeroIcons.xMark,
          textColor: Colors.black,
          colors: const [Colors.blue, Colors.green],
          onTap: () {},
        ),
        container,
      );

      expect(find.textContaining('A very long label'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TicketCard', () {
    GenerateTicketComplete ticket({required int maxUse}) =>
        GenerateTicketComplete.empty().copyWith(
          id: 't-1',
          name: 'Entrée soirée',
          maxUse: maxUse,
          expiration: DateTime(2026, 12, 31),
        );

    testWidgets('renders a single-scan ticket and fires the callback', (
      tester,
    ) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);
      var taps = 0;

      await scaffold.pumpWidgetApp(
        tester,
        TicketCard(
          ticket: ticket(maxUse: 1),
          product: AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
            id: 'p-1',
          ),
          onClicked: () => taps++,
        ),
        container,
      );

      expect(find.text('Entrée soirée'), findsOneWidget);
      expect(find.textContaining('1 scan'), findsOneWidget);
      await tester.tap(find.text('Entrée soirée'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the plural scans line for a multi-use ticket', (
      tester,
    ) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        TicketCard(
          ticket: ticket(maxUse: 3),
          product: AppModulesCdrSchemasCdrProductComplete.empty().copyWith(
            id: 'p-1',
          ),
          onClicked: () {},
        ),
        container,
      );

      expect(find.textContaining('3 scans'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
