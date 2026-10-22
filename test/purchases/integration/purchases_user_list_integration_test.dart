import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/purchases/providers/product_id_provider.dart';
import 'package:titan/purchases/providers/ticket_id_provider.dart';
import 'package:titan/tools/ui/layouts/refresher.dart';

import '../../shared/app_scaffold.dart';

CoreUserSimple scannedUser(String id, String firstname, String name) =>
    CoreUserSimple.empty().copyWith(id: id, firstname: firstname, name: name);

/// The scanned-users page reached from the scan page's list bullet: the
/// ticket/product ids are pre-seeded the way the bullet sets them, the
/// pull-to-refresh loads the tags, and a chip tap loads the tag's users.
/// One router-pushing test per file (convention 19) — the remaining tests
/// only assert on branches that need no navigation.
void main() {
  late IntegrationScaffold scaffold;

  setUp(() {
    scaffold = IntegrationScaffold();
    scaffold.shellSetUp();
  });

  void stubTags(List<String> tags) {
    when(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTagsGeneratorIdGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
          ),
    ).thenAnswer((_) async => chopperListResponse(tags));
  }

  void stubUsers(String tag, List<CoreUserSimple> users) {
    when(
      () => scaffold.repository
          .cdrSellersSellerIdProductsProductIdTicketsGeneratorIdListsTagGet(
            sellerId: any(named: 'sellerId'),
            productId: any(named: 'productId'),
            generatorId: any(named: 'generatorId'),
            tag: tag,
          ),
    ).thenAnswer((_) async => chopperListResponse(users));
  }

  testWidgets('refresh loads the tags and a chip tap lists the scanned users', (
    tester,
  ) async {
    stubTags(['VIP', 'BDE']);
    stubUsers('VIP', [scannedUser('u-1', 'Alice', 'Martin')]);
    stubUsers('BDE', <CoreUserSimple>[]);

    final container = scaffold.makeContainer();
    // The scan page's list bullet sets both ids before pushing this page.
    container.read(ticketIdProvider.notifier).setTicketId('gen-1');
    container.read(productIdProvider.notifier).setProductId('prod-1');

    // The page parks on the tag loader until a refresh arrives, and an
    // indeterminate Loader never lets pumpAndSettle finish (convention 12).
    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    // Pull to refresh: the page only loads tags from the refresh closure.
    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('BDE'), findsOneWidget);

    await tester.tap(find.text('VIP'));
    await settle(tester, frames: 8);
    expect(find.text('Alice Martin'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The other tag has no scans yet.
    await tester.tap(find.text('BDE'));
    await settle(tester, frames: 8);
    expect(find.text('Aucun utilisateur scanné'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a refresh with no tags says so', (tester) async {
    stubTags(<String>[]);

    final container = scaffold.makeContainer();
    container.read(ticketIdProvider.notifier).setTicketId('gen-1');
    container.read(productIdProvider.notifier).setProductId('prod-1');

    await scaffold.pumpApp(
      tester,
      container,
      initialPath: '/purchases/user_list',
      pumpAndSettle: false,
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    await tester.drag(find.byType(Refresher), const Offset(0, 1500));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.fling(find.byType(Refresher), const Offset(0, 300), 1000);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await settle(tester, frames: 8);

    expect(find.text('Aucun tag disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
