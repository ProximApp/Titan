import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The admin product card's pencil: it seeds the product provider with the
/// tapped card and opens the deferred add/edit product form, prefilled.
///
/// Own file because the tap navigates mid-test: qlevar 1.12.4 only honours
/// the first such QR.to() in an isolate, so this is the file's first (and
/// only) test.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  testWidgets('the product pencil opens the prefilled edit form', (
    tester,
  ) async {
    stubAdminLoads(
      scaffold,
      products: [
        AppModulesAmapSchemasAmapProductComplete.empty().copyWith(
          id: 'p-1',
          name: 'Honey jar',
          price: 350,
          category: 'Grocery',
        ),
      ],
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

    expect(find.text('Honey jar'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is HeroIcon && w.icon == HeroIcons.pencil,
      ),
    );
    for (var i = 0; i < 20 && find.text('Price').evaluate().isEmpty; i++) {
      await settle(tester, frames: 4);
    }

    // The form opens on the tapped product: its name is prefilled and the
    // three fields render (the page title stays the add product title).
    expect(find.text('Honey jar'), findsWidgets);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.textContaining('product'), findsWidgets);

    await scaffold.unmountApp(tester);
  });
}
