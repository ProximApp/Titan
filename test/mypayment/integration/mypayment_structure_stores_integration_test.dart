import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qlevar_router/qlevar_router.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';

void stubMyPayment(IntegrationScaffold scaffold, {List<UserStore>? stores}) {
  when(
    () => scaffold.repository.mypaymentUsersMeStoresGet(),
  ).thenAnswer((_) async => chopperListResponse(stores ?? <UserStore>[]));
  // The add-edit store page loads the association picker list.
  when(
    () => scaffold.repository.associationsGet(),
  ).thenAnswer((_) async => chopperListResponse(<Association>[]));
}

final bdeStructure = structure('structure-1', 'BDE', 'user-1');

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('add store card navigates to the add-edit store form', (
    tester,
  ) async {
    // NOTE on ordering: qlevar_router 1.12.4 silently drops the first
    // mid-test QR.to() to a route that is not yet mounted when an earlier
    // test already ran in the same isolate. The navigation test is kept
    // first.
    stubMyPayment(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        // Pre-seeded so the async AdminMiddleware gate (the user manages the
        // structure) resolves before the redirect is evaluated.
        myStructures: [bdeStructure],
        selectedStructure: bdeStructure,
      ),
      initialPath: '/mypayment/structureStores',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
    );
    await settle(tester, frames: 20);

    expect(QR.currentPath, '/mypayment/structureStores/addEditStore');
    // The form renders the store name entry.
    expect(find.text('Store name'), findsOneWidget);
  });

  testWidgets('structure stores page lists the stores of the structure', (
    tester,
  ) async {
    stubMyPayment(
      scaffold,
      stores: [
        UserStore.empty().copyWith(
          id: 'store-1',
          name: 'Fridge',
          structure: bdeStructure,
        ),
      ],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(
        user: CoreUser.empty().copyWith(id: 'user-1'),
        myStructures: [bdeStructure],
        selectedStructure: bdeStructure,
      ),
      initialPath: '/mypayment/structureStores',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.textContaining('BDE management'), findsOneWidget);
    expect(find.text('Fridge'), findsOneWidget);
  });
}
