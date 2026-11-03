import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/feed/providers/filter_state_provider.dart';
import 'package:titan/feed/ui/pages/main_page/filter_news.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for `FilterNewsModal`: the entity and module chips
/// toggle the filter state, and the apply button closes the sheet.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<ProviderContainer> openModal(WidgetTester tester) async {
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await scaffold.pumpWidgetApp(
      tester,
      Consumer(
        builder: (context, ref, _) => ElevatedButton(
          onPressed: () => showCustomBottomModal(
            context: context,
            ref: ref,
            modal: const FilterNewsModal(
              entities: ['BDE', 'AJC'],
              modules: ['event', 'news'],
            ),
          ),
          child: const Text('open'),
        ),
      ),
      container,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('the entity chips toggle the selected entities', (tester) async {
    final container = await openModal(tester);
    expect(find.byType(BottomModalTemplate), findsOneWidget);

    await tester.tap(find.text('BDE'));
    await tester.pump();
    expect(
      container.read(filterStateProvider).selectedEntities.contains('BDE'),
      isTrue,
    );

    await tester.tap(find.text('BDE'));
    await tester.pump();
    expect(
      container.read(filterStateProvider).selectedEntities.contains('BDE'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the module chips toggle the selected modules', (tester) async {
    final container = await openModal(tester);

    await tester.tap(find.text('event'));
    await tester.pump();
    expect(
      container.read(filterStateProvider).selectedModules.contains('event'),
      isTrue,
    );

    await tester.tap(find.text('event'));
    await tester.pump();
    expect(
      container.read(filterStateProvider).selectedModules.contains('event'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the apply button closes the sheet', (tester) async {
    await openModal(tester);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomModalTemplate), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
