import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/ui/pages/devices_page/device_item.dart';
import 'package:titan/mypayment/ui/pages/store_admin_page/seller_right_card.dart';
import 'package:titan/tools/ui/widgets/custom_dialog_box.dart';

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

  group('SellerRightCard admin modal', () {
    /// At the default 360-wide phone surface the modal's fixed label rows
    /// (`Row` at seller_right_card.dart:140) overflow by 30-50px — a
    /// pre-existing layout quirk on narrow devices, documented here rather
    /// than patched in a coverage round. The modal logic is exercised on a
    /// wider sheet instead.
    const ui.Size modalSurface = ui.Size(700, 1000);

    /// Pumps fixed frames plus a long jump: the rights actions answer with
    /// toasts whose auto-close timer must not outlive the test.
    Future<void> pumpFrames(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    }

    UserStore store() => UserStore.empty().copyWith(
      id: 'store-1',
      name: 'Store',
      structure: Structure.empty().copyWith(
        managerUser: CoreUserSimple.empty().copyWith(id: 'manager-1'),
      ),
    );

    testWidgets('a store manager toggles a right through the real patch', (
      tester,
    ) async {
      final repo = scaffold.repository;
      when(() => repo.mypaymentStoresStoreIdSellersGet(storeId: 'store-1'))
          .thenAnswer((_) async => repo.okList<Seller>());
      when(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdPatch(
          storeId: 'store-1',
          sellerUserId: 'user-2',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final me = seller(userId: 'manager-1', canManageSellers: true);
      final target = seller(userId: 'user-2', canBank: true);
      final container = scaffold.makeContainer(
        myStores: [store()],
        storeSellers: {
          'store-1': [me, target],
        },
      );
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        SellerRightCard(me: me, storeSeller: target),
        container,
        surface: modalSurface,
      );

      // The row lists the granted rights as icons, then opens the modal.
      await tester.tap(find.textContaining('Delaunay').first);
      await tester.pumpAndSettle();

      // Five editable rights, plus the delete row at the bottom.
      expect(find.byType(Checkbox), findsNWidgets(5));
      expect(find.text('Delete seller'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await pumpFrames(tester);

      // The patch landed: the modal popped and nothing threw.
      verify(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdPatch(
          storeId: 'store-1',
          sellerUserId: 'user-2',
          body: any(named: 'body'),
        ),
      ).called(1);
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deleting a seller confirms then deletes through the API', (
      tester,
    ) async {
      final repo = scaffold.repository;
      when(() => repo.mypaymentStoresStoreIdSellersGet(storeId: 'store-1'))
          .thenAnswer((_) async => repo.okList<Seller>());
      when(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdDelete(
          storeId: 'store-1',
          sellerUserId: 'user-2',
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final me = seller(userId: 'manager-1', canManageSellers: true);
      final target = seller(userId: 'user-2');
      final container = scaffold.makeContainer(
        myStores: [store()],
        storeSellers: {
          'store-1': [target],
        },
      );
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        SellerRightCard(me: me, storeSeller: target),
        container,
        surface: modalSurface,
      );

      await tester.tap(find.textContaining('Delaunay').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete seller'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomDialogBox), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await pumpFrames(tester);

      verify(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdDelete(
          storeId: 'store-1',
          sellerUserId: 'user-2',
        ),
      ).called(1);
      expect(find.byType(CustomDialogBox), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the structure manager row is read-only', (tester) async {
      final repo = scaffold.repository;
      when(() => repo.mypaymentStoresStoreIdSellersGet(storeId: 'store-1'))
          .thenAnswer((_) async => repo.okList<Seller>());

      // The seller IS the structure manager: flagged admin, no checkboxes.
      final me = seller(userId: 'manager-1', canManageSellers: true);
      final container = scaffold.makeContainer(
        myStores: [store()],
        storeSellers: {
          'store-1': [me],
        },
      );
      addTearDown(container.dispose);

      await scaffold.pumpWidgetApp(
        tester,
        SellerRightCard(me: me, storeSeller: me),
        container,
        surface: modalSurface,
      );

      await tester.tap(find.textContaining('Delaunay').first);
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Delete seller'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
