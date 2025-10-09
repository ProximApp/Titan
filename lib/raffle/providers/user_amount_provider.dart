import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/cash.dart';
import 'package:titan/raffle/repositories/cash_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class UserCashNotifier extends SingleNotifier<Cash> {
  CashRepository get cashRepository => ref.watch(rafflesCashRepositoryProvider);

  @override
  AsyncValue<Cash> build() {
    return const AsyncValue.loading();
  }

  Future<AsyncValue<Cash>> loadCashByUser(String userId) async {
    return await load(() async => cashRepository.getCash(userId));
  }

  Future updateCash(double amount) async {
    state.when(
      data: (cash) {
        final newCash = cash.copyWith(balance: cash.balance + amount);
        state = AsyncValue.data(newCash);
      },
      error: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
      loading: () {
        state = const AsyncValue.error(
          "Cannot update cash while loading",
          StackTrace.empty,
        );
      },
    );
  }
}

final userAmountProvider = NotifierProvider<UserCashNotifier, AsyncValue<Cash>>(
  UserCashNotifier.new,
);
