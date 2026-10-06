import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/cash_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/app_scaffold.dart';

/// Unit coverage for the raffle cash provider (the admin accounts handler):
/// client-side filtering across user name/firstname/nickname, the
/// refresh-restore behavior after a filter, and the balance update which
/// rounds fractional amounts through `tombolaUsersUserIdCashPatch`.
AppModulesRaffleSchemasRaffleCashComplete cash(
  String userId,
  String firstname,
  String name, [
  String? nickname,
  int balance = 1000,
]) => AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
  userId: userId,
  balance: balance,
  user: CoreUserSimple.empty().copyWith(
    id: userId,
    firstname: firstname,
    name: name,
    nickname: nickname,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  /// Boots the provider with its own build() load serving [cashes]:
  /// setting `state` by hand races the load the build fires (the completed
  /// load overwrites whatever was set), so the fixture goes through the
  /// stubbed endpoint instead.
  Future<ProviderContainer> containerWith(
    List<AppModulesRaffleSchemasRaffleCashComplete> cashes,
  ) async {
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(scaffold.repository)],
    );
    addTearDown(container.dispose);
    when(
      () => scaffold.repository.tombolaUsersCashGet(),
    ).thenAnswer((_) async => chopperListResponse(cashes));
    final notifier = container.read(cashProvider.notifier);
    await notifier.loadCashList();
    return container;
  }

  test(
    'filterCashList matches name, firstname or nickname case-insensitively',
    () async {
      final container = await containerWith([
        cash('u1', 'Marie', 'Dupont'),
        cash('u2', 'Alex', 'Martin', 'bond'),
        cash('u3', 'Zoe', 'Marin'),
      ]);

      final notifier = container.read(cashProvider.notifier);

      // filterCashList REPLACES the state with the filtered list, so every
      // search starts from a refresh to filter the full list again.

      // Name match (case-insensitive, substring).
      final byName = await notifier.filterCashList('dupont');
      expect(byName.value!.map((c) => c.userId), ['u1']);

      // Nickname match.
      await notifier.refreshCashList();
      final byNickname = await notifier.filterCashList('BOND');
      expect(byNickname.value!.map((c) => c.userId), ['u2']);

      // Firstname match.
      await notifier.refreshCashList();
      final byFirstname = await notifier.filterCashList('alex');
      expect(byFirstname.value!.map((c) => c.userId), ['u2']);

      // Name substring.
      await notifier.refreshCashList();
      final bySubstring = await notifier.filterCashList('marin');
      expect(bySubstring.value!.map((c) => c.userId), ['u3']);
    },
  );

  test('refreshCashList restores the unfiltered server list', () async {
    final unfiltered = [
      cash('u1', 'Marie', 'Dupont'),
      cash('u2', 'Alex', 'Martin'),
    ];
    final container = await containerWith(unfiltered);
    final notifier = container.read(cashProvider.notifier);

    await notifier.filterCashList('dupont');
    expect(container.read(cashProvider).value, hasLength(1));

    await notifier.refreshCashList();
    expect(container.read(cashProvider).value, hasLength(2));
  });

  test('updateCash PATCHes the balance and replaces by userId', () async {
    final container = await containerWith([
      cash('u1', 'Marie', 'Dupont', null, 1000),
    ]);
    when(
      () => scaffold.repository.tombolaUsersUserIdCashPatch(
        userId: 'u1',
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async =>
          chopperResponse(AppModulesRaffleSchemasRaffleCashComplete.empty()),
    );

    final notifier = container.read(cashProvider.notifier);
    final ok = await notifier.updateCash(
      container.read(cashProvider).value!.first,
      1238,
    );

    expect(ok, isTrue);
    final body =
        verify(
              () => scaffold.repository.tombolaUsersUserIdCashPatch(
                userId: 'u1',
                body: captureAny(named: 'body'),
              ),
            ).captured.last
            as CashEdit;
    expect(body.balance, 1238);
    // The provider's list now carries the updated balance.
    expect(container.read(cashProvider).value!.first.balance, 1238);
  });
}
