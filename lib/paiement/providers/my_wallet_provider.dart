import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/paiement/class/wallet.dart';
import 'package:titan/paiement/repositories/users_me_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class MyWalletNotifier extends SingleNotifier<Wallet> {
  UsersMeRepository get usersMeRepository =>
      ref.watch(usersMeRepositoryProvider);

  @override
  AsyncValue<Wallet> build() {
    getMyWallet();
    return const AsyncValue.loading();
  }

  Future<AsyncValue<Wallet>> getMyWallet() async {
    return await load(usersMeRepository.getMyWallet);
  }
}

final myWalletProvider = NotifierProvider<MyWalletNotifier, AsyncValue<Wallet>>(
  MyWalletNotifier.new,
);
