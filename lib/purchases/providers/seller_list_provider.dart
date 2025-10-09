import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/purchases/class/seller.dart';
import 'package:titan/purchases/repositories/user_information_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class SellerListNotifier extends ListNotifier<Seller> {
  final UserInformationRepository sellerRepository =
      UserInformationRepository();
  AsyncValue<List<Seller>> sellerList = const AsyncValue.loading();

  @override
  AsyncValue<List<Seller>> build() {
    final token = ref.watch(tokenProvider);
    sellerRepository.setToken(token);

    tokenExpireWrapperAuth(ref, () async {
      await loadSellers();
    });

    return const AsyncValue.loading();
  }

  Future<AsyncValue<List<Seller>>> loadSellers() async {
    return await loadList(sellerRepository.getSellerList);
  }
}

final sellerListProvider =
    NotifierProvider<SellerListNotifier, AsyncValue<List<Seller>>>(
      SellerListNotifier.new,
    );
