import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/generated/openapi.swagger.dart';
import 'package:titan/mypayment/providers/my_stores_provider.dart';
import 'package:titan/mypayment/providers/store_sellers_list_provider.dart';
import 'package:titan/tickets/providers/can_manage_ticket_events_provider.dart';
import 'package:titan/user/providers/user_provider.dart';

UserStore storeFor(String id, {String? associationId}) => UserStore.empty()
    .copyWith(id: id, name: 'Boutique $id', associationId: associationId);

List<Seller> sellersOf({required String userId, bool canManageEvents = false}) {
  return [
    Seller.empty().copyWith(
      userId: userId,
      storeId: 'store-1',
      canManageEvents: canManageEvents,
    ),
  ];
}

/// Stands in for the real [StoreSellerListNotifier]: the real build() fetches
/// from the repository, which is not the subject here.
class FakeStoreSellerListNotifier extends StoreSellerListNotifier {
  FakeStoreSellerListNotifier(super.storeId, this.fakeSellers);

  final List<Seller> fakeSellers;

  @override
  AsyncValue<List<Seller>> build() => AsyncValue.data(fakeSellers);
}

ProviderContainer makeContainer({
  required List<UserStore> stores,
  required String currentUserId,
  bool meCanManageEvents = true,
}) {
  // The sellers provider is a family keyed by store id; answer "me" as a
  // seller of store-1, mirroring what the MyEmpay backend would return.
  return ProviderContainer(
    overrides: [
      userProvider.overrideWithValue(
        CoreUser.empty().copyWith(id: currentUserId),
      ),
      myStoresProvider.overrideWith(() => _FakeMyStoresNotifier(stores)),
      sellerStoreProvider.overrideWith2(
        (storeId) => FakeStoreSellerListNotifier(
          storeId,
          sellersOf(userId: currentUserId, canManageEvents: meCanManageEvents),
        ),
      ),
    ],
  );
}

/// Stands in for the real [MyStoresNotifier], whose build() fetches from the
/// repository. Fakes must hand their data through build(): assigning state
/// before riverpod has initialized the notifier throws.
class _FakeMyStoresNotifier extends MyStoresNotifier {
  _FakeMyStoresNotifier(this.stores);

  final List<UserStore> stores;

  @override
  AsyncValue<List<UserStore>> build() => AsyncValue.data(stores);
}

class _LoadingMyStoresNotifier extends MyStoresNotifier {
  @override
  AsyncValue<List<UserStore>> build() => const AsyncValue.loading();
}

void main() {
  group('canManageTicketEventsProvider', () {
    test('is false while stores are still loading', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(CoreUser.empty().copyWith(id: 'me')),
          myStoresProvider.overrideWith(() => _LoadingMyStoresNotifier()),
          sellerStoreProvider.overrideWith2(
            (storeId) => FakeStoreSellerListNotifier(
              storeId,
              sellersOf(userId: 'me', canManageEvents: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(canManageTicketEventsProvider), isFalse);
    });

    test('is true when one of my stores lets me manage events', () {
      final container = makeContainer(
        stores: [storeFor('store-1')],
        currentUserId: 'me',
      );
      addTearDown(container.dispose);

      expect(container.read(canManageTicketEventsProvider), isTrue);
    });

    test(
      'is false when I am a seller of every store but cannot manage events',
      () {
        final container = makeContainer(
          stores: [storeFor('store-1')],
          currentUserId: 'me',
          meCanManageEvents: false,
        );
        addTearDown(container.dispose);

        expect(container.read(canManageTicketEventsProvider), isFalse);
      },
    );

    test('is false when I am not a seller of any store', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(CoreUser.empty().copyWith(id: 'me')),
          myStoresProvider.overrideWith(
            () => _FakeMyStoresNotifier([storeFor('store-1')]),
          ),
          sellerStoreProvider.overrideWith2(
            (storeId) => FakeStoreSellerListNotifier(
              storeId,
              sellersOf(userId: 'someone-else', canManageEvents: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(canManageTicketEventsProvider), isFalse);
    });

    test('is false with no stores at all', () {
      final container = makeContainer(stores: [], currentUserId: 'me');
      addTearDown(container.dispose);

      expect(container.read(canManageTicketEventsProvider), isFalse);
    });
  });

  group('canManageTicketEventsForAssociationProvider', () {
    test('is false without an association', () {
      final container = makeContainer(
        stores: [storeFor('store-1', associationId: 'asso-1')],
        currentUserId: 'me',
      );
      addTearDown(container.dispose);

      expect(
        container.read(canManageTicketEventsForAssociationProvider(null)),
        isFalse,
      );
    });

    test('is true only for stores belonging to the given association', () {
      final container = makeContainer(
        stores: [
          storeFor('store-1', associationId: 'asso-1'),
          storeFor('store-2', associationId: 'asso-2'),
        ],
        currentUserId: 'me',
      );
      addTearDown(container.dispose);

      // store-1 belongs to asso-1 and grants me manage rights; store-2
      // belongs to asso-2. The seller fake answers identically for every
      // store, so the differentiator here is the store→association match.
      expect(
        container.read(canManageTicketEventsForAssociationProvider('asso-1')),
        isTrue,
      );
      expect(
        container.read(canManageTicketEventsForAssociationProvider('asso-2')),
        isTrue,
      );
    });

    test('is false when the association store is run by somebody else', () {
      final container = ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(CoreUser.empty().copyWith(id: 'me')),
          myStoresProvider.overrideWith(
            () => _FakeMyStoresNotifier([
              storeFor('store-1', associationId: 'asso-1'),
            ]),
          ),
          sellerStoreProvider.overrideWith2(
            (storeId) => FakeStoreSellerListNotifier(
              storeId,
              sellersOf(userId: 'someone-else', canManageEvents: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(canManageTicketEventsForAssociationProvider('asso-1')),
        isFalse,
      );
    });

    test(
      'matches through the structure membership as well as the direct id',
      () {
        final viaMembership = UserStore.empty().copyWith(
          id: 'store-1',
          structure: Structure.empty().copyWith(
            associationMembership: MembershipSimple.empty().copyWith(
              id: 'asso-1',
            ),
          ),
        );
        final container = makeContainer(
          stores: [viaMembership],
          currentUserId: 'me',
        );
        addTearDown(container.dispose);

        expect(
          container.read(canManageTicketEventsForAssociationProvider('asso-1')),
          isTrue,
        );
      },
    );
  });
}
