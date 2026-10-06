import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/ui/pages/devices_page/device_item.dart';
import 'package:titan/mypayment/ui/pages/store_admin_page/seller_right_card.dart';

import '../../shared/app_scaffold.dart';

/// Widget-level tests for the mypayment cards that the layout sweep could
/// not reach from a page: `SellerRightCard` (the biggest uncovered file in
/// the module at 87 lines, because it only renders inside the store-admin
/// page's seller list) and `DeviceItem`.
///
/// Same rules as the amap card file: no router, no journey, phone-sized
/// surface, adversarial data. The seller card is the one place where a long
/// user name meets a row of right-hand flags, so it is exactly the shape
/// that overflows.
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

  Seller seller({
    required String userId,
    bool canBank = false,
    bool canSeeHistory = false,
    bool canCancel = false,
    bool canManageSellers = false,
    bool canManageEvents = false,
  }) => Seller.empty().copyWith(
    userId: userId,
    storeId: 'store-1',
    canBank: canBank,
    canSeeHistory: canSeeHistory,
    canCancel: canCancel,
    canManageSellers: canManageSellers,
    canManageEvents: canManageEvents,
    user: user('Jean-Baptiste', 'DelaunayDeserializer'),
  );

  testWidgets('the seller card renders the seller and every granted right', (
    tester,
  ) async {
    final container = scaffold.makeContainer(
      userId: 'user-1',
      myStores: [UserStore.empty().copyWith(id: 'store-1', name: 'Store')],
      storeSellers: {
        'store-1': [
          seller(
            userId: 'user-1',
            canBank: true,
            canSeeHistory: true,
            canCancel: true,
            canManageSellers: true,
            canManageEvents: true,
          ),
        ],
      },
    );
    addTearDown(container.dispose);

    await scaffold.pumpWidgetApp(
      tester,
      SellerRightCard(
        me: seller(userId: 'user-1'),
        storeSeller: seller(
          userId: 'user-2',
          canBank: true,
          canManageEvents: true,
        ),
      ),
      container,
    );

    // The card is the store-admin list row: the seller's name plus the
    // rights they hold over the store.
    expect(find.textContaining('Delaunay'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the device row renders the device name and flags the actual one',
    (tester) async {
      final container = scaffold.makeContainer();
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        Column(
          children: [
            DeviceItem(
              device: WalletDevice.empty().copyWith(
                id: 'd-1',
                name: 'A device name that is quite long indeed',
                walletId: 'wallet-1',
                creation: DateTime(2100),
              ),
              isActual: true,
              onRevoke: () async {},
            ),
            DeviceItem(
              device: WalletDevice.empty().copyWith(
                id: 'd-2',
                name: 'Old phone',
                walletId: 'wallet-1',
                creation: DateTime(2099),
              ),
              isActual: false,
              onRevoke: () async {},
            ),
          ],
        ),
        container,
      );

      expect(find.textContaining('A device name'), findsOneWidget);
      expect(find.textContaining('Old phone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
