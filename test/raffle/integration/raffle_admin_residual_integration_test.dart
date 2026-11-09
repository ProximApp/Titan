import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/providers/searching_raffle_user_provider.dart';
import 'package:titan/raffle/providers/tombola_logos_provider.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/account_handler.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/confirm_creation.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/tombola_handler.dart';
import 'package:titan/tools/ui/heroicons.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';
import '../../shared/repository_test_support.dart' show chopperError;
import '../raffle_fixtures.dart';

/// The raffle admin page's un-exercised edges (`/tombola/admin`):
/// * the page's pull-to-refresh (it drops every cached raffle logo),
/// * the cash card's x, which flips the strip to the user-search mode,
/// * the raffle strip's ERROR and LOADING arms,
/// * the plus when the group list is in error / still loading (it builds the
///   arm's widget and drops it — nothing opens, nothing throws),
/// * the creation dialog's cancel, which must not create anything.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubRaffleList(List<RaffleComplete> raffles) {
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperListResponse(raffles),
    );
  }

  void stubGroups(List<CoreGroupSimple> groups) {
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperResponse(groups),
    );
  }

  void stubCash() {
    when(() => scaffold.repository.tombolaUsersCashGet()).thenAnswer(
      (_) async => chopperListResponse(<AppModulesRaffleSchemasRaffleCashComplete>[]),
    );
  }

  Future<ProviderContainerWithTeardown> pumpAdmin(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    final container = scaffold.makeContainer(user: adminUser);
    addTearDown(container.dispose);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/tombola/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
    return ProviderContainerWithTeardown(container);
  }

  testWidgets('pull to refresh drops the cached raffle logos', (tester) async {
    stubRaffleList([raffleFixture('r-1', 'Gala', RaffleStatusType.open)]);
    stubGroups([CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE')]);
    stubCash();
    final handle = await pumpAdmin(tester);
    final container = handle.container;

    container
        .read(tombolaLogosProvider.notifier)
        .setTData(
          'r-1',
          AsyncData([Image.memory(Uint8List.fromList(const [1, 2, 3]))]),
        );
    await settle(tester, frames: 2);
    expect(container.read(tombolaLogosProvider)['r-1'], isNotNull);

    await tester.drag(find.byType(Refresher), const Offset(0, 400));
    await settle(tester, frames: 24);

    expect(
      container.read(tombolaLogosProvider)['r-1'],
      isNull,
      reason: 'the refresher did not reset the logo cache',
    );
  });

  testWidgets('the cash card x flips the strip to user search', (tester) async {
    stubRaffleList([raffleFixture('r-1', 'Gala', RaffleStatusType.open)]);
    stubGroups([CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE')]);
    stubCash();
    final handle = await pumpAdmin(tester);

    // The strip starts in user-search mode; its plus flips it to the cash
    // card, whose x flips it back.
    expect(handle.container.read(searchingAmapUserProvider), isTrue);

    await tester.tap(
      find.descendant(
        of: find.byType(AccountHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    await settle(tester, frames: 12);
    expect(handle.container.read(searchingAmapUserProvider), isFalse);

    await tester.tap(
      find.descendant(
        of: find.byType(AccountHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.xMark,
        ),
      ),
    );
    await settle(tester, frames: 12);

    expect(handle.container.read(searchingAmapUserProvider), isTrue);
  });

  testWidgets('the raffle strip reports a failed list', (tester) async {
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) async => chopperError<List<RaffleComplete>>(500),
    );
    stubGroups([CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE')]);
    stubCash();
    await pumpAdmin(tester);

    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('Error:'),
      ),
      findsWidgets,
    );
  });

  testWidgets('the raffle strip spins while the list is loading', (
    tester,
  ) async {
    when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
      (_) => Completer<List<RaffleComplete>>().future.then(
        (value) => chopperListResponse(value),
      ),
    );
    stubGroups([CoreGroupSimple.empty().copyWith(id: 'g-1', name: 'BDE')]);
    stubCash();
    await pumpAdmin(tester);

    expect(
      find.descendant(
        of: find.byType(TombolaHandler),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsWidgets,
    );
  });

  testWidgets('the plus opens nothing when the group list failed', (
    tester,
  ) async {
    stubRaffleList([raffleFixture('r-1', 'Gala', RaffleStatusType.open)]);
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) async => chopperError<List<CoreGroupSimple>>(500),
    );
    stubCash();
    await pumpAdmin(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(TombolaHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    await settle(tester, frames: 16);

    expect(find.text('Pour quel groupe ?'), findsNothing);
    expect(find.byType(ConfirmCreationDialog), findsNothing);
  });

  testWidgets('the plus opens nothing while the group list loads', (
    tester,
  ) async {
    stubRaffleList([raffleFixture('r-1', 'Gala', RaffleStatusType.open)]);
    when(() => scaffold.repository.groupsGet()).thenAnswer(
      (_) => Completer<List<CoreGroupSimple>>().future.then(
        (value) => chopperResponse(value),
      ),
    );
    stubCash();
    await pumpAdmin(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(TombolaHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    await settle(tester, frames: 16);

    expect(find.text('Pour quel groupe ?'), findsNothing);
    expect(find.byType(ConfirmCreationDialog), findsNothing);
  });

  testWidgets('cancelling the creation dialog creates nothing', (tester) async {
    stubRaffleList([raffleFixture('r-0', 'Tombola : BDE', RaffleStatusType.creation)]);
    stubGroups([CoreGroupSimple.empty().copyWith(id: 'g-2', name: 'BDE Info')]);
    stubCash();
    await pumpAdmin(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(TombolaHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus,
        ),
      ),
    );
    await settle(tester, frames: 20);
    await tester.tap(find.text('BDE Info').last);
    await settle(tester, frames: 20);
    expect(
      find.text('Voulez vous vraiment créer la tombola : BDE Info'),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ConfirmCreationDialog),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.xMark,
        ),
      ),
    );
    await settle(tester, frames: 20);

    expect(find.byType(ConfirmCreationDialog), findsNothing);
    verifyNever(
      () => scaffold.repository.tombolaRafflesPost(body: any(named: 'body')),
    );
  });
}

/// Bundles the container so a helper can hand it back without a second
/// teardown (the caller already registered one).
class ProviderContainerWithTeardown {
  ProviderContainerWithTeardown(this.container);
  final ProviderContainer container;
}
