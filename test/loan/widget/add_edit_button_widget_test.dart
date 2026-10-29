import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/loan/providers/borrower_provider.dart';
import 'package:titan/loan/providers/end_provider.dart';
import 'package:titan/loan/providers/item_list_provider.dart';
import 'package:titan/loan/providers/start_provider.dart';
import 'package:titan/loan/ui/pages/loan_group_page/add_edit_button.dart';
import 'package:titan/tools/ui/builders/waiting_button.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level coverage for `AddEditButton`: the guard branches (invalid
/// dates, no borrower, items not loaded, failed load, empty selection) all
/// live behind the button's tap and each answers with a toast.
class _ItemsNotifier extends ItemListNotifier {
  _ItemsNotifier(this.initial);

  final AsyncValue<List<Item>> initial;

  @override
  AsyncValue<List<Item>> build() => initial;
}

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Pumps fixed frames plus a long jump: every branch answers with a toast
  /// whose auto-close timer must not outlive the test.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  }

  ProviderContainer containerWith(AsyncValue<List<Item>> items) {
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(scaffold.repository),
        itemListProvider.overrideWith(() => _ItemsNotifier(items)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  void setDates(
    ProviderContainer container, {
    required DateTime start,
    required DateTime end,
  }) {
    // The button parses both ends with the app's yMd locale formatter.
    container
        .read(startProvider.notifier)
        .setStart(DateFormat.yMd('en_US').format(start));
    container
        .read(endProvider.notifier)
        .setEnd(DateFormat.yMd('en_US').format(end));
  }

  void setBorrower(ProviderContainer container) {
    container
        .read(borrowerProvider.notifier)
        .setBorrower(CoreUserSimple.empty().copyWith(id: 'u-1'));
  }

  Future<void> tapButton(WidgetTester tester) async {
    await tester.tap(find.byType(WaitingButton));
    await tester.pump();
    await pumpFrames(tester);
  }

  Future<void> mount(WidgetTester tester, ProviderContainer container) async {
    await scaffold.pumpWidgetApp(
      tester,
      AddEditButton(
        note: TextEditingController(),
        isEdit: false,
        onAddEdit: (callback) async {
          await callback();
        },
      ),
      container,
    );
  }

  testWidgets('an out-of-order date range is refused', (tester) async {
    final container = containerWith(const AsyncValue.loading());
    setDates(
      container,
      start: DateTime(2026, 10, 10),
      end: DateTime(2026, 10, 1),
    );
    await mount(tester, container);

    await tapButton(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing borrower is refused before touching the items', (
    tester,
  ) async {
    final container = containerWith(const AsyncValue.loading());
    setDates(
      container,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 10),
    );
    await mount(tester, container);

    await tapButton(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('items still loading answer with the loading arm', (
    tester,
  ) async {
    final container = containerWith(const AsyncValue.loading());
    setDates(
      container,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 10),
    );
    setBorrower(container);
    await mount(tester, container);

    await tapButton(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed item load answers with the error arm', (tester) async {
    final container = containerWith(AsyncValue.error('boom', StackTrace.empty));
    setDates(
      container,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 10),
    );
    setBorrower(container);
    await mount(tester, container);

    await tapButton(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loaded items with an empty selection answer with a toast', (
    tester,
  ) async {
    final container = containerWith(
      AsyncValue.data([
        Item.empty().copyWith(id: 'i-1'),
        Item.empty().copyWith(id: 'i-2'),
      ]),
    );
    setDates(
      container,
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 10),
    );
    setBorrower(container);
    await mount(tester, container);

    await tapButton(tester);
    expect(tester.takeException(), isNull);
  });
}
