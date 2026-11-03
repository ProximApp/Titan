import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/store_sellers_list_provider.dart';
import 'package:titan/mypayment/providers/structure_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

import '../../shared/mock_openapi.dart';

void main() {
  late MockOpenapi repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOpenapi();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  group('StructureListNotifier', () {
    test('updateStructure success swaps the entry in the list', () async {
      when(() => repo.mypaymentStructuresGet())
          .thenAnswer((_) async => repo.okList<Structure>());
      final notifier = container.read(structureListProvider.notifier);
      await notifier.getStructures();

      final structure = Structure.empty().copyWith(id: 'st-1', name: 'Old');
      notifier.state = AsyncValue.data([structure]);
      when(
        () => repo.mypaymentStructuresStructureIdPatch(
          structureId: 'st-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.updateStructure(
        structure.copyWith(name: 'New'),
      );
      expect(ok, isTrue);
      expect(notifier.state.value!.single.name, 'New');
    });

    test('updateStructure failure keeps the previous entry', () async {
      when(() => repo.mypaymentStructuresGet())
          .thenAnswer((_) async => repo.okList<Structure>());
      final notifier = container.read(structureListProvider.notifier);
      await notifier.getStructures();

      final structure = Structure.empty().copyWith(id: 'st-1', name: 'Old');
      notifier.state = AsyncValue.data([structure]);
      when(
        () => repo.mypaymentStructuresStructureIdPatch(
          structureId: 'st-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.fail<void>(400));

      final ok = await notifier.updateStructure(structure);
      expect(ok, isFalse);
      expect(notifier.state.value!.single.name, 'Old');
    });

    test('deleteStructure success removes the entry', () async {
      when(() => repo.mypaymentStructuresGet())
          .thenAnswer((_) async => repo.okList<Structure>());
      final notifier = container.read(structureListProvider.notifier);
      await notifier.getStructures();

      final structure = Structure.empty().copyWith(id: 'st-1');
      notifier.state = AsyncValue.data([structure]);
      when(() => repo.mypaymentStructuresStructureIdDelete(structureId: 'st-1'))
          .thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deleteStructure(structure);
      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });

    test('deleteStructure failure keeps the entry', () async {
      when(() => repo.mypaymentStructuresGet())
          .thenAnswer((_) async => repo.okList<Structure>());
      final notifier = container.read(structureListProvider.notifier);
      await notifier.getStructures();

      final structure = Structure.empty().copyWith(id: 'st-1');
      notifier.state = AsyncValue.data([structure]);
      when(() => repo.mypaymentStructuresStructureIdDelete(structureId: 'st-1'))
          .thenAnswer((_) async => repo.fail<void>(404));

      final ok = await notifier.deleteStructure(structure);
      expect(ok, isFalse);
      expect(notifier.state.value, hasLength(1));
    });
  });

  group('StoreSellerListNotifier', () {
    setUp(() {
      when(() => repo.mypaymentStoresStoreIdSellersGet(storeId: 'st-1'))
          .thenAnswer((_) async => repo.okList<Seller>());
    });

    test('updateStoreSeller success swaps the seller permissions', () async {
      final notifier = container.read(sellerStoreProvider('st-1').notifier);
      await notifier.getStoreSellerList();

      final seller = Seller.empty().copyWith(
        storeId: 'st-1',
        userId: 'u-1',
        canBank: false,
      );
      notifier.state = AsyncValue.data([seller]);
      when(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdPatch(
          storeId: 'st-1',
          sellerUserId: 'u-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.updateStoreSeller(
        seller.copyWith(canBank: true),
      );
      expect(ok, isTrue);
      expect(notifier.state.value!.single.canBank, isTrue);
    });

    test('updateStoreSeller failure keeps the previous seller', () async {
      final notifier = container.read(sellerStoreProvider('st-1').notifier);
      await notifier.getStoreSellerList();

      final seller = Seller.empty().copyWith(
        storeId: 'st-1',
        userId: 'u-1',
        canBank: false,
      );
      notifier.state = AsyncValue.data([seller]);
      when(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdPatch(
          storeId: 'st-1',
          sellerUserId: 'u-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => repo.fail<void>(400));

      final ok = await notifier.updateStoreSeller(seller);
      expect(ok, isFalse);
      expect(notifier.state.value!.single.canBank, isFalse);
    });

    test('deleteStoreSeller success removes the seller', () async {
      final notifier = container.read(sellerStoreProvider('st-1').notifier);
      await notifier.getStoreSellerList();

      final seller = Seller.empty().copyWith(storeId: 'st-1', userId: 'u-1');
      notifier.state = AsyncValue.data([seller]);
      when(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdDelete(
          storeId: 'st-1',
          sellerUserId: 'u-1',
        ),
      ).thenAnswer((_) async => repo.okVoid());

      final ok = await notifier.deleteStoreSeller(seller);
      expect(ok, isTrue);
      expect(notifier.state.value, isEmpty);
    });

    test('deleteStoreSeller failure keeps the seller', () async {
      final notifier = container.read(sellerStoreProvider('st-1').notifier);
      await notifier.getStoreSellerList();

      final seller = Seller.empty().copyWith(storeId: 'st-1', userId: 'u-1');
      notifier.state = AsyncValue.data([seller]);
      when(
        () => repo.mypaymentStoresStoreIdSellersSellerUserIdDelete(
          storeId: 'st-1',
          sellerUserId: 'u-1',
        ),
      ).thenAnswer((_) async => repo.fail<void>(400));

      final ok = await notifier.deleteStoreSeller(seller);
      expect(ok, isFalse);
      expect(notifier.state.value, hasLength(1));
    });
  });
}
