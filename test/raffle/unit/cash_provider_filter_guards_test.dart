import 'dart:async';

import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/raffle/providers/cash_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';

/// `filterCashList`'s non-data arms: while the cash list is still loading and
/// after it failed, the filter must return the state untouched instead of
/// pretending it filtered anything. The data arm is covered by
/// cash_provider_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  String describe(
    AsyncValue<List<AppModulesRaffleSchemasRaffleCashComplete>> v,
  ) => v.when(
    data: (_) => 'data',
    error: (_, __) => 'error',
    loading: () => 'loading',
  );

  test('a still-loading list is returned untouched', () async {
    // A load that never completes keeps the state in AsyncLoading, which is
    // the arm a filter typed before the first response hits.
    final pending =
        Completer<
          chopper.Response<List<AppModulesRaffleSchemasRaffleCashComplete>>
        >();
    when(() => scaffold.repository.tombolaUsersCashGet())
        .thenAnswer((_) => pending.future);

    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(scaffold.repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(cashProvider.notifier);
    expect(describe(container.read(cashProvider)), 'loading');

    final result = await notifier.filterCashList('ada');
    expect(describe(result), 'loading');
    expect(describe(container.read(cashProvider)), 'loading');
  });

  test('a failed list is returned with its error', () async {
    when(() => scaffold.repository.tombolaUsersCashGet())
        .thenThrow(Exception('cash down'));

    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(scaffold.repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(cashProvider.notifier);
    await notifier.loadCashList();
    expect(describe(container.read(cashProvider)), 'error');

    final result = await notifier.filterCashList('ada');
    expect(describe(result), 'error');
    expect(describe(container.read(cashProvider)), 'error');
  });
}
