import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/adapters/store_adapter.dart';
import 'package:titan/mypayment/providers/stores_list_provider.dart';
import 'package:titan/tools/repository/repository.dart';

class MockRepository extends Mock implements Openapi {}

void main() {
  group('StoreListNotifier', () {
    late MockRepository mockRepository;
    late ProviderContainer container;
    late StoreListNotifier notifier;
    final structure = Structure.empty().copyWith(id: 'structure-1');
    final store = UserStore.empty().copyWith(id: 'store-1', name: 'BDE store');

    setUp(() {
      mockRepository = MockRepository();
      when(() => mockRepository.mypaymentUsersMeStoresGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('[]', 200), <UserStore>[]),
      );
      container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(mockRepository)],
      );
      notifier = container.read(storeListProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('getStores loads the stores', () async {
      when(() => mockRepository.mypaymentUsersMeStoresGet()).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), [store]),
      );

      final result = await notifier.getStores();

      expect(result.value, [store]);
    });

    test('getStores handles error', () async {
      when(
        () => mockRepository.mypaymentUsersMeStoresGet(),
      ).thenThrow(Exception('stores failed'));

      final result = await notifier.getStores();

      expect(result, isA<AsyncError<List<UserStore>>>());
    });

    test('createStore adds the created store to the list', () async {
      final created = Store.empty().copyWith(id: 'store-2', name: 'New store');
      when(
        () => mockRepository.mypaymentStructuresStructureIdStoresPost(
          structureId: any(named: 'structureId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), created),
      );

      notifier.state = AsyncValue.data([]);
      final result = await notifier.createStore(
        structure,
        store.copyWith(id: 'store-2'),
      );

      expect(result, true);
      expect(notifier.state.value!.map((s) => s.id), contains('store-2'));
    });

    test('createStore handles error', () async {
      when(
        () => mockRepository.mypaymentStructuresStructureIdStoresPost(
          structureId: any(named: 'structureId'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('create failed'));

      notifier.state = AsyncValue.data([]);
      final result = await notifier.createStore(structure, store);

      expect(result, false);
    });

    test('updateStore replaces the store in the list', () async {
      final updated = store.copyWith(name: 'Renamed');
      when(
        () => mockRepository.mypaymentStoresStoreIdPatch(
          storeId: 'store-1',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([store]);
      final result = await notifier.updateStore(updated);

      expect(result, true);
      expect(notifier.state.value!.single.name, 'Renamed');
    });

    test('updateStore handles error', () async {
      when(
        () => mockRepository.mypaymentStoresStoreIdPatch(
          storeId: 'store-1',
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('update failed'));

      notifier.state = AsyncValue.data([store]);
      final result = await notifier.updateStore(store);

      expect(result, false);
    });

    test('deleteStore removes the store from the list', () async {
      when(
        () => mockRepository.mypaymentStoresStoreIdDelete(storeId: 'store-1'),
      ).thenAnswer(
        (_) async => chopper.Response(http.Response('body', 200), null),
      );

      notifier.state = AsyncValue.data([store]);
      final result = await notifier.deleteStore(store);

      expect(result, true);
      expect(notifier.state.value, isEmpty);
    });

    test('deleteStore handles error', () async {
      when(
        () => mockRepository.mypaymentStoresStoreIdDelete(storeId: 'store-1'),
      ).thenThrow(Exception('delete failed'));

      notifier.state = AsyncValue.data([store]);
      final result = await notifier.deleteStore(store);

      expect(result, false);
    });

    test('toUserStore maps a Store to a UserStore without seller rights', () {
      final mapped = Store.empty()
          .copyWith(id: 'store-1', name: 'Foyer', associationId: 'asso-1')
          .toUserStore();

      expect(mapped.id, 'store-1');
      expect(mapped.name, 'Foyer');
      expect(mapped.associationId, 'asso-1');
      expect(mapped.canBank, false);
      expect(mapped.canSeeHistory, false);
      expect(mapped.canCancel, false);
      expect(mapped.canManageSellers, false);
    });
  });
}
