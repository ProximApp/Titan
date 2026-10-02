import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/raffle/ui/pages/creation_edit_page/user_cash_ui.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level test for the raffle cash card — the twin of amap's
/// `UserCashUi`, and the other half of the layout sweep's `AutoSizeText`-in-
/// a-`Row` fix (ledger #4).
///
/// The card is a fixed 100x150 flip card: the front face stacks a nickname,
/// a full name and a balance row. Mounted here at a 360px phone width with a
/// five-figure balance and a nickname nobody would type, because the widths
/// that overflow are exactly the ones a demo never reaches. No router, no
/// providers: the card takes its `cash` as a constructor argument.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  CoreUserSimple user(String firstname, String name, {String? nickname}) =>
      CoreUserSimple.empty().copyWith(
        id: 'user-1',
        firstname: firstname,
        name: name,
        nickname: nickname,
      );

  testWidgets(
    'the raffle cash card fits a five-figure balance and a long name',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        UserCashUi(
          cash: AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
            balance: 1250000,
            userId: 'user-1',
            user: user(
              'Jean-Baptiste',
              'DelaunayDeserializer',
              nickname: 'A nickname that will not fit',
            ),
          ),
        ),
        container,
      );

      // Raw amounts, no division (raffle ledger #13's family).
      expect(find.textContaining('1250000.00'), findsOneWidget);
      expect(find.textContaining('A nickname'), findsOneWidget);
      // The flip card's front face fits its 100px box: no overflow escaped.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the raffle cash card renders the full name when there is no nickname',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        UserCashUi(
          cash: AppModulesRaffleSchemasRaffleCashComplete.empty().copyWith(
            balance: 250,
            userId: 'user-1',
            user: user('Jean-Baptiste', 'Delaunay'),
          ),
        ),
        container,
      );

      expect(find.textContaining('250.00'), findsOneWidget);
      expect(find.textContaining('Jean-Baptiste'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
