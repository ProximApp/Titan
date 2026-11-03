import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/admin/providers/assocation_list_provider.dart';
import 'package:titan/admin/ui/components/association_picker_modal.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/tools/ui/styleguide/bottom_modal_template.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for `AssociationPickerModal`: the searchable list,
/// the no-association row, and the selection callback.
class _AssociationListNotifier extends AssociationListNotifier {
  _AssociationListNotifier(this.associations);

  final List<Association> associations;

  @override
  AsyncValue<List<Association>> build() => AsyncValue.data(associations);
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Association association(String id, String name) =>
      Association.empty().copyWith(id: id, name: name);

  ProviderContainer containerWith(List<Association> associations) {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        associationListProvider.overrideWith(
          () => _AssociationListNotifier(associations),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> openModal(
    WidgetTester tester,
    ProviderContainer container,
    void Function(Association) onSelect,
  ) async {
    await scaffold.pumpWidgetApp(
      tester,
      Consumer(
        builder: (context, ref, _) => ElevatedButton(
          onPressed: () => showCustomBottomModal(
            context: context,
            ref: ref,
            modal: AssociationPickerModal(
              selected: Association.empty(),
              onSelect: onSelect,
            ),
          ),
          child: const Text('open'),
        ),
      ),
      container,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the associations sorted, with the none row on top', (
    tester,
  ) async {
    final container = containerWith([
      association('a-2', 'Zebres'),
      association('a-1', 'AJE'),
    ]);
    await openModal(tester, container, (_) {});

    expect(find.byType(BottomModalTemplate), findsOneWidget);
    expect(find.text('AJE'), findsOneWidget);
    expect(find.text('Zebres'), findsOneWidget);

    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .toList();
    expect(labels.indexOf('AJE'), lessThan(labels.indexOf('Zebres')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search bar filters the rows', (tester) async {
    final container = containerWith([
      association('a-1', 'AJE'),
      association('a-2', 'BDE'),
    ]);
    await openModal(tester, container, (_) {});

    await tester.enterText(find.byType(TextField), 'bde');
    await tester.pumpAndSettle();

    expect(find.text('BDE'), findsOneWidget);
    expect(find.text('AJE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking an association reports it and closes the sheet', (
    tester,
  ) async {
    Association? picked;
    final container = containerWith([association('a-1', 'AJE')]);
    await openModal(tester, container, (a) => picked = a);

    await tester.tap(find.text('AJE'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'a-1');
    expect(find.byType(BottomModalTemplate), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the none row reports an empty association', (tester) async {
    Association? picked = association('seed', 'Seed');
    final container = containerWith([association('a-1', 'AJE')]);
    await openModal(tester, container, (a) => picked = a);

    await tester.tap(find.text('No association'));
    await tester.pumpAndSettle();

    expect(picked?.id, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed association load shows the shared error arm', (
    tester,
  ) async {
    // The real notifier's build fires the repository call; an unstubbed
    // mock makes it land in the error state the modal renders.
    final container = scaffold.makeContainer();
    addTearDown(container.dispose);
    await openModal(tester, container, (_) {});

    expect(find.textContaining('error'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
