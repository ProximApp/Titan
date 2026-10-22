import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/ui/pages/admin_module_page/account_handler.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

/// The raffle admin page's account handler (`/tombola/admin`): the cash
/// card strip (`UserCashUi` — front balance card, flip to the add-balance
/// form, PATCH round trip) and the search field's two modes (cash filter
/// vs user search → add-user card → `addCash` POST).
///
/// raffle_admin_create_integration_test covers the TombolaHandler strip
/// above; this file owns the AccountHandler strip below it.
final adminUser = CoreUser.empty().copyWith(
  id: 'user-1',
  groups: [
    CoreGroupSimple(
      name: 'admin_raffle',
      id: '0a25cb76-4b63-4fd3-b939-da6d9feabf28',
    ),
  ],
);

AppModulesRaffleSchemasRaffleCashComplete cashEntry(
  String userId,
  int balance, {
  required String firstname,
  required String name,
  String? nickname,
}) => AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
  userId: userId,
  balance: balance,
  user: CoreUserSimple.empty().copyWith(
    id: userId,
    firstname: firstname,
    name: name,
    nickname: nickname,
  ),
);

/// The two cash entries differ on purpose: one with a nickname (the
/// "$firstname $name" secondary line) and one without (plain name).
final cashAnne = cashEntry(
  'u-1',
  1500,
  firstname: 'Anne',
  name: 'Martin',
  nickname: 'Annie',
);
final cashBob = cashEntry('u-2', 250, firstname: 'Bob', name: 'Dupont');

void stubAdminAccounts(
  IntegrationScaffold scaffold,
  List<AppModulesRaffleSchemasRaffleCashComplete> cashList,
) {
  when(() => scaffold.repository.tombolaRafflesGet()).thenAnswer(
    (_) async => chopperListResponse([
      RaffleComplete.empty().copyWith(
        id: 'r-1',
        name: 'Gala',
        groupId: 'group-1',
        status: RaffleStatusType.creation,
      ),
    ]),
  );
  when(() => scaffold.repository.groupsGet())
      .thenAnswer((_) async => chopperListResponse(<CoreGroupSimple>[]));
  when(() => scaffold.repository.tombolaUsersCashGet())
      .thenAnswer((_) async => chopperListResponse(cashList));
  when(
    () => scaffold.repository.tombolaUsersUserIdCashPatch(
      userId: any(named: 'userId'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => chopperResponseVoid());
  when(
    () => scaffold.repository.tombolaUsersUserIdCashPost(
      userId: any(named: 'userId'),
      body: any(named: 'body'),
    ),
  ).thenAnswer(
    (_) async =>
        chopperResponse(AppModulesRaffleSchemasRaffleCashComplete.empty()),
  );
  when(
    () => scaffold.repository.usersSearchGet(
      query: any(named: 'query'),
      includedAccountTypes: any(named: 'includedAccountTypes'),
      excludedAccountTypes: any(named: 'excludedAccountTypes'),
      includedGroups: any(named: 'includedGroups'),
      excludedGroups: any(named: 'excludedGroups'),
    ),
  ).thenAnswer(
    (_) async => chopperListResponse([
      CoreUserSimple.empty().copyWith(
        id: 's-1',
        firstname: 'Zoe',
        name: 'Zorro',
      ),
    ]),
  );
}

/// The cards use AutoSizeText (a RichText), so assertions go through
/// widget predicates instead of find.text.
AutoSizeText autoSizeText(WidgetTester tester, String data) => tester
    .widgetList<AutoSizeText>(find.byWidgetPredicate((w) => w is AutoSizeText))
    .firstWhere(
      (t) => t.data == data,
      orElse: () => throw TestFailure('missing AutoSizeText "$data"'),
    );

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  Future<void> pumpAdmin(WidgetTester tester) async {
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: adminUser),
      initialPath: '/tombola/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);
  }

  testWidgets('the cash card flips to the form and PATCHes the balance', (
    tester,
  ) async {
    stubAdminAccounts(scaffold, [cashAnne, cashBob]);

    await pumpAdmin(tester);

    // Front side: nickname primary line + "$firstname $name" secondary
    // for the nicknamed entry, plain name for the other.
    autoSizeText(tester, '1500.00 €');
    autoSizeText(tester, 'Annie');
    autoSizeText(tester, 'Anne Martin');
    autoSizeText(tester, '250.00 €');
    autoSizeText(tester, 'Dupont');
    // No form on screen yet: each card renders exactly one side.
    expect(find.byType(TextFormField), findsNothing);

    await tester.tap(
      find.byWidgetPredicate((w) => w is AutoSizeText && w.data == '1500.00 €'),
    );
    await settle(tester, frames: 16);

    // The flipped card shows the add-balance form (only this card flipped).
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '700');
    await tester.tap(find.byIcon(Icons.add));
    await settle(tester, frames: 30);

    final captured = verify(
      () => scaffold.repository.tombolaUsersUserIdCashPatch(
        userId: captureAny(named: 'userId'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(captured[0], 'u-1');
    expect((captured[1] as CashEdit).balance, 700);

    // The card flipped back and shows the new balance.
    autoSizeText(tester, '700.00 €');
    await scaffold.drainToast(tester);
  });

  testWidgets('the search field filters cash, then searches and adds users', (
    tester,
  ) async {
    stubAdminAccounts(scaffold, [cashAnne, cashBob]);

    await pumpAdmin(tester);

    final searchField = find.byType(TextField);

    // Mode 1 (default): cash filtering — 'an' matches Anne only.
    await tester.enterText(searchField, 'an');
    await settle(tester, frames: 10);
    autoSizeText(tester, '1500.00 €');
    expect(
      find.byWidgetPredicate((w) => w is AutoSizeText && w.data == '250.00 €'),
      findsNothing,
    );
    // Clearing restores the full list through refreshCashList.
    await tester.enterText(searchField, '');
    await settle(tester, frames: 10);
    autoSizeText(tester, '250.00 €');

    // Toggle to user mode: the 50px plus (small 20px plus icons sit on
    // the cash cards themselves) flips the strip into search mode. The
    // TombolaHandler above the strip has its own 50px plus, so the tap
    // is scoped to the AccountHandler.
    await tester.tap(
      find.descendant(
        of: find.byType(AccountHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus && w.size == 50,
        ),
      ),
    );
    await settle(tester, frames: 10);
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.xMark && w.size == 50,
      ),
      findsOneWidget,
    );

    // Typing in user mode hits usersSearchGet and renders the add card.
    await tester.enterText(searchField, 'zoe');
    await settle(tester, frames: 16);
    verify(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query'),
        includedAccountTypes: any(named: 'includedAccountTypes'),
        excludedAccountTypes: any(named: 'excludedAccountTypes'),
        includedGroups: any(named: 'includedGroups'),
        excludedGroups: any(named: 'excludedGroups'),
      ),
    ).called(greaterThanOrEqualTo(1));
    autoSizeText(tester, 'Zoe');

    // Tapping the user card POSTs its cash account and flips back to
    // cash mode (the X branch's onAdd).
    await tester.tap(
      find.byWidgetPredicate((w) => w is AutoSizeText && w.data == 'Zoe'),
    );
    await settle(tester, frames: 20);
    verify(
      () => scaffold.repository.tombolaUsersUserIdCashPost(
        userId: 's-1',
        body: any(named: 'body'),
      ),
    ).called(1);
    expect(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.xMark && w.size == 50,
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(AccountHandler),
        matching: find.byWidgetPredicate(
          (w) => w is HeroIcon && w.icon == HeroIcons.plus && w.size == 50,
        ),
      ),
      findsOneWidget,
    );
    await scaffold.drainToast(tester);
  });
}
