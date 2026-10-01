import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import 'amap_integration_test.dart';
import '../../shared/app_scaffold.dart';

/// The admin page's top handler (AccountHandler): the Accounts search bar
/// toggles between cash cards (default) and a user-search picker, the flip
/// card edits a balance, and picking a user creates their cash account.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  CoreUserSimple user(
    String id,
    String firstname,
    String name, {
    String? nickname,
  }) => CoreUserSimple.empty().copyWith(
    id: id,
    firstname: firstname,
    name: name,
    nickname: nickname,
    accountType: enums.AccountType.student,
    schoolId: '',
  );

  AppModulesAmapSchemasAmapCashComplete cashOf(
    String userId,
    String firstname,
    String name, {
    String? nickname,
    int balance = 0,
  }) => AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
    balance: balance,
    userId: userId,
    user: user(userId, firstname, name, nickname: nickname),
  );

  /// Stubs everything the admin page loads on mount (its Refresher and the
  /// main page's routes both read cash/deliveries/products).
  ///
  /// Nullable params with fresh list bodies: default values must be const
  /// (immutable), but DeliveryHandler sorts the provider's list in place,
  /// so the stub must hand out a growable list — as the real deserializer
  /// would.
  void stubAdminLoads({
    List<AppModulesAmapSchemasAmapCashComplete>? cashes,
    List<DeliveryReturn>? deliveries,
  }) {
    when(
      () => scaffold.repository.amapUsersCashGet(),
    ).thenAnswer((_) async => chopperListResponse(cashes ?? []));
    when(
      () => scaffold.repository.amapDeliveriesGet(),
    ).thenAnswer((_) async => chopperListResponse(deliveries ?? []));
    when(() => scaffold.repository.amapProductsGet()).thenAnswer(
      (_) async =>
          chopperListResponse(<AppModulesAmapSchemasAmapProductComplete>[]),
    );
  }

  Future<void> pumpAdmin(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    ignoreAmapKnownQuirks();
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  testWidgets('renders cash cards with nickname, full name and balance', (
    tester,
  ) async {
    stubAdminLoads(
      cashes: [
        cashOf('u-1', 'Ada', 'Lovelace', nickname: 'Ada', balance: 1250),
        cashOf('u-2', 'Grace', 'Hopper', balance: -250),
      ],
    );

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // Front of the flip card: nickname (or firstname), "firstname name"
    // and the raw balance (no cents division — 1250 shows as 1250.00).
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('1250.00 €'), findsOneWidget);
    // A user without a nickname falls back to the firstname as title.
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('Hopper'), findsOneWidget);
    expect(find.text('-250.00 €'), findsOneWidget);
  });

  testWidgets('the Accounts search bar filters cash cards by name', (
    tester,
  ) async {
    stubAdminLoads(
      cashes: [
        cashOf('u-1', 'Ada', 'Lovelace', nickname: 'Ada'),
        cashOf('u-2', 'Grace', 'Hopper'),
      ],
    );

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // Cash mode is the default: typing filters the loaded list client-side.
    await tester.enterText(find.byType(TextField).first, 'grace');
    await settle(tester, frames: 4);

    expect(find.text('Hopper'), findsOneWidget);
    expect(find.text('Ada'), findsNothing);

    // Clearing the query restores the full list without a backend call
    // (the single initial load from build is still the only call).
    await tester.enterText(find.byType(TextField).first, '');
    await settle(tester, frames: 4);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Hopper'), findsOneWidget);
    verify(() => scaffold.repository.amapUsersCashGet()).called(1);
  });

  testWidgets('the + card switches to user search and adds a cash account', (
    tester,
  ) async {
    stubAdminLoads();
    // The user-search endpoint backs the users mode of the search bar.
    when(
      () => scaffold.repository.usersSearchGet(query: any(named: 'query')),
    ).thenAnswer(
      (_) async => chopperListResponse([
        user('u-9', 'Alan', 'Turing', nickname: 'Alan'),
      ]),
    );

    AppModulesAmapSchemasAmapCashComplete? createdCash;
    String? createdUserId;
    when(
      () => scaffold.repository.amapUsersUserIdCashPost(
        userId: any(named: 'userId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      createdUserId = inv.namedArguments[#userId] as String;
      final body = inv.namedArguments[#body] as CashEdit;
      createdCash = AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
        balance: body.balance,
        userId: createdUserId,
        user: user('u-9', 'Alan', 'Turing', nickname: 'Alan'),
      );
      return chopperResponse(createdCash!);
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    // Cash mode renders the plus toggle; tapping it flips to users mode.
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
      findsWidgets,
    );
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .first,
    );
    await settle(tester, frames: 4);

    // Users mode: the toggle becomes an xMark and the search bar now drives
    // the real user-search endpoint.
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, 'turing');
    await settle(tester, frames: 8);

    verify(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query', that: contains('turing')),
      ),
    );
    // The result card shows the nickname and full name.
    expect(find.text('Alan'), findsOneWidget);
    expect(find.text('Alan Turing'), findsOneWidget);

    // Picking the card creates the cash account through the real POST and
    // returns to cash mode.
    await tester.tap(find.text('Alan Turing'));
    await settle(tester, frames: 8);

    expect(createdUserId, 'u-9');
    expect(createdCash!.balance, 0);
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
      findsWidgets,
    );
    // The new account joins the cash row.
    expect(find.text('0.00 €'), findsOneWidget);
  });

  testWidgets('flipping a cash card edits the balance through the real PATCH', (
    tester,
  ) async {
    stubAdminLoads(
      cashes: [cashOf('u-1', 'Ada', 'Lovelace', nickname: 'Ada', balance: 0)],
    );

    CashEdit? capturedEdit;
    String? patchedUserId;
    when(
      () => scaffold.repository.amapUsersUserIdCashPatch(
        userId: any(named: 'userId'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((inv) async {
      patchedUserId = inv.namedArguments[#userId] as String;
      capturedEdit = inv.namedArguments[#body] as CashEdit;
      return chopperResponseVoid();
    });

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await pumpAdmin(tester, container);

    expect(find.text('0.00 €'), findsOneWidget);

    // Tap the card to flip it: the back side carries the amount field.
    await tester.tap(find.text('Ada Lovelace'));
    // The flip is a 500ms AnimationController — pump through it.
    await settle(tester, frames: 30);

    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '7,50');
    await settle(tester, frames: 4);

    // The + button submits: 7,50 parses to 7.5 and .round() rounds half
    // away from zero → 8 (the balance is a raw int, not cents).
    await tester.tap(find.byIcon(Icons.add));
    await settle(tester, frames: 20);

    expect(patchedUserId, 'u-1');
    expect(capturedEdit!.balance, 8);
    // Success toast, then the card flips back to its front.
    expect(find.text('Balance updated'), findsOneWidget);
    expect(find.text('8.00 €'), findsOneWidget);
    // Drain the toast timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });
}
