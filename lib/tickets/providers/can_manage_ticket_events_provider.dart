import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/generated/openapi.models.swagger.dart';
import 'package:titan/mypayment/providers/my_stores_provider.dart';
import 'package:titan/mypayment/providers/store_sellers_list_provider.dart';
import 'package:titan/user/providers/user_provider.dart';

bool _storeBelongsToAssociation(UserStore store, String associationId) {
  return store.associationId == associationId ||
      store.structure.associationMembership?.id == associationId;
}

bool _userCanManageEventsOnStore(
  Ref ref,
  UserStore store,
  String currentUserId,
) {
  final sellersAsync = ref.watch(sellerStoreProvider(store.id));
  return sellersAsync.maybeWhen(
    data: (sellers) {
      final meAsSeller = sellers.firstWhereOrNull(
        (seller) => seller.userId == currentUserId,
      );
      return meAsSeller?.canManageEvents ?? false;
    },
    orElse: () => false,
  );
}

/// Provider that checks if the current user can manage ticket events
/// (create/edit ticket events) for their stores.
final canManageTicketEventsProvider = Provider<bool>((ref) {
  final myStores = ref.watch(myStoresProvider);
  final currentUser = ref.watch(userProvider);

  return myStores.maybeWhen(
    data: (stores) {
      if (stores.isEmpty) return false;

      for (final store in stores) {
        if (_userCanManageEventsOnStore(ref, store, currentUser.id)) {
          return true;
        }
      }

      return false;
    },
    orElse: () => false,
  );
});

/// Whether the current user can link a feed event to an existing ticketing
/// for the given association (requires manage-events on its MyEmpay store).
final canManageTicketEventsForAssociationProvider =
    Provider.family<bool, String?>((ref, associationId) {
      if (associationId == null) return false;

      final myStores = ref.watch(myStoresProvider);
      final currentUser = ref.watch(userProvider);

      return myStores.maybeWhen(
        data: (stores) {
          for (final store in stores) {
            if (!_storeBelongsToAssociation(store, associationId)) {
              continue;
            }
            if (_userCanManageEventsOnStore(ref, store, currentUser.id)) {
              return true;
            }
          }
          return false;
        },
        orElse: () => false,
      );
    });
