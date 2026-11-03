import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.enums.swagger.dart' as enums;
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The accounts search bar has two modes and the toggle carries the current
/// query across them. Three arms were dark: clearing the bar while in USERS
/// mode (which empties the user results), and both branches of the toggle
/// when the field already holds text.
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
  }) => AppModulesAmapSchemasAmapCashComplete.empty().copyWith(
    balance: 0,
    userId: userId,
    // The card only joins the full name when the nickname is set.
    user: user(userId, firstname, name, nickname: nickname),
  );

  testWidgets('the mode toggle carries the query to the other side', (
    tester,
  ) async {
    stubAdminLoads(
      scaffold,
      cashes: [cashOf('u-1', 'Ada', 'Lovelace', nickname: 'Ada')],
    );
    when(() => scaffold.repository.usersSearchGet(query: any(named: 'query')))
        .thenAnswer(
          (_) async => chopperListResponse([
            user('u-9', 'Alan', 'Turing', nickname: 'Alan'),
          ]),
        );

    final container = scaffold.makeContainer(
      user: amapAdminUser,
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    scaffold.setWideSurface(tester);
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/amap/admin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 24);

    final bar = find.byType(TextField).first;
    // The cash row renders by default.
    expect(find.text('Ada Lovelace'), findsOneWidget);

    // Flip to user search with an EMPTY field: the branch that skips the
    // cash filter.
    await tester.tap(
      find
          .byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus)
          .first,
    );
    await settle(tester, frames: 6);
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
      findsOneWidget,
    );

    // User search drives the real search endpoint.
    await tester.enterText(bar, 'turing');
    await settle(tester, frames: 8);
    // The card joins firstname and name only when a nickname is set.
    expect(find.text('Alan Turing'), findsOneWidget);
    verify(
      () => scaffold.repository.usersSearchGet(
        query: any(named: 'query', that: contains('turing')),
      ),
    ).called(1);

    // Clearing the bar empties the results.
    await tester.enterText(bar, '');
    await settle(tester, frames: 6);
    expect(find.text('Alan Turing'), findsNothing);

    // Flip back with a query present: the other toggle branch, which now
    // re-runs the CASH filter on the text kept in the field.
    await tester.enterText(bar, 'ada');
    await settle(tester, frames: 6);
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.xMark),
    );
    await settle(tester, frames: 8);
    // Back in cash mode: the filtered cash row and the plus toggle.
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
