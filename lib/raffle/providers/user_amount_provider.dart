import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/cash.dart';
import 'package:titan/raffle/repositories/cash_repository.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class UserCashNotifier extends SingleNotifier<Cash> {
  final CashRepository _cashRepository = CashRepository();

  @override
  AsyncValue<Cash> build() {
    final token = ref.watch(tokenProvider);
    _cashRepository.setToken(token);
    return const AsyncValue.loading();
  }

  Future<AsyncValue<Cash>> loadCashByUser(String userId) async {
    return await load(() async => _cashRepository.getCash(userId));
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
