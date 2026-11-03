import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';

import '../../shared/app_scaffold.dart';
import '../mypayment_fixtures.dart';

void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('store admin page lists the sellers of the selected store', (
    tester,
  ) async {
    stubStoreAdmin(scaffold);

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/storeAdmin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    // The header shows the selected store's name.
    expect(find.textContaining('Sellers of'), findsOneWidget);
    expect(find.textContaining('Fridge'), findsOneWidget);
  });

  testWidgets('store admin page renders the seller cards', (tester) async {
    stubStoreAdmin(
      scaffold,
      sellers: [
        // The seller cards only render when the signed-in user is themselves
        // a seller of the store (otherwise the "not a seller" message shows).
        Seller.empty().copyWith(
          userId: 'user-1',
          storeId: 'store-1',
          user: CoreUserSimple.empty().copyWith(
            id: 'user-1',
            firstname: 'Max',
            name: 'Verstappen',
          ),
        ),
        Seller.empty().copyWith(
          userId: 'user-2',
          storeId: 'store-1',
          user: CoreUserSimple.empty().copyWith(
            firstname: 'Ada',
            name: 'Lovelace',
          ),
        ),
      ],
    );

    await scaffold.pumpApp(
      tester,
      scaffold.makeContainer(user: CoreUser.empty().copyWith(id: 'user-1')),
      initialPath: '/mypayment/storeAdmin',
      pumpAndSettle: false,
    );
    await settle(tester, frames: 30);

    expect(find.text('Ada Lovelace'), findsOneWidget);
  });
}
