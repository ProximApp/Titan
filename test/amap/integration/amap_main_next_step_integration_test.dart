import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/tools/ui/heroicons.dart';

import '../../shared/app_scaffold.dart';
import '../amap_fixtures.dart';

/// The order panel's \"Next step\" button: with no delivery selected on the
/// order being built, it refuses with an error toast instead of navigating
/// to the product list. The panel is opened from the \"+\" order card, so the
/// page's `displayToastWithoutContext` helper and the guard's error arm are
/// both reached.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();

    when(
      () => scaffold.repository.amapUsersUserIdCashGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperResponse(cash(2510)));
    when(() => scaffold.repository.amapDeliveriesGet()).thenAnswer(
      (_) async => chopperListResponse([orderableDelivery('d-1', 2)]),
    );
    when(
      () => scaffold.repository.amapUsersUserIdOrdersGet(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => chopperListResponse([order('o-1', 'd-1', 500)]));
  });

  testWidgets('Next step refuses when no delivery is selected', (tester) async {
    final container = scaffold.makeContainer(
      user: CoreUser.empty().copyWith(id: 'user-1'),
      userId: 'user-1',
    );
    addTearDown(container.dispose);
    await scaffold.pumpApp(tester, container, initialPath: '/amap');
    await settle(tester, frames: 16);

    // The "+" order card seeds an EMPTY order (no delivery id) and slides
    // the panel up.
    await tester.tap(
      find.byWidgetPredicate((w) => w is HeroIcon && w.icon == HeroIcons.plus),
    );
    await settle(tester, frames: 12);

    await tester.ensureVisible(find.text('Next step'));
    await tester.tap(find.text('Next step'));
    await settle(tester, frames: 8);

    expect(find.text('No delivery selected'), findsOneWidget);
    // The guard kept the page in place instead of opening the product list.
    expect(find.text('Next step'), findsOneWidget);

    await scaffold.unmountApp(tester);
    await scaffold.drainToast(tester);
  });
}
