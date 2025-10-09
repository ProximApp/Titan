import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/seller.dart';
import 'package:titan/paiement/repositories/store_sellers_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class StoreSellerListNotifier extends ListNotifier<Seller> {
  SellerStoreRepository get sellerStoreRepository =>
      ref.watch(sellerStoreRepositoryProvider);

  @override
  AsyncValue<List<Seller>> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Seller>>> getStoreSellerList(String storeId) async {
    return await loadList(() => sellerStoreRepository.getSellers(storeId));
  }

  Future<bool> createStoreSeller(Seller seller) async {
    return await add(
      (seller) => sellerStoreRepository.createSeller(seller.storeId, seller),
      seller,
    );
  }

  Future<bool> deleteStoreSeller(Seller seller) async {
    return await delete(
      (_) => sellerStoreRepository.deleteSeller(seller.storeId, seller.userId),
      (sellers, seller) =>
          sellers.where((s) => s.userId != seller.userId).toList(),
      seller.userId,
      seller,
    );
  }

  Future<bool> updateStoreSeller(Seller seller) async {
    return await update(
      (seller) => sellerStoreRepository.updateSeller(
        seller.storeId,
        seller.userId,
        seller,
      ),
      (sellers, seller) =>
          sellers.map((s) => s.userId == seller.userId ? seller : s).toList(),
      seller,
    );
  }
}

final sellerStoreProvider =
    NotifierProvider.family<
      StoreSellerListNotifier,
      AsyncValue<List<Seller>>,
      String
    >((storeId) => StoreSellerListNotifier());
