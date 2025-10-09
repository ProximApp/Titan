import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/cash.dart';
import 'package:titan/raffle/repositories/cash_repository.dart';
import 'package:titan/tools/exception.dart';
import 'package:titan/tools/providers/list_notifier.dart';

class CashProvider extends ListNotifier<Cash> {
  CashRepository get cashRepository => ref.watch(rafflesCashRepositoryProvider);
  AsyncValue<List<Cash>> _cashList = const AsyncLoading();

  @override
  AsyncValue<List<Cash>> build() {
    return const AsyncLoading();
  }

  Future<AsyncValue<List<Cash>>> loadCashList() async {
    return _cashList = await loadList(cashRepository.getCashList);
  }

  Future<bool> addCash(Cash cash) async {
    return await add(cashRepository.createCash, cash);
  }

  Future<bool> updateCash(Cash cash, int amount) async {
    return await update(
      cashRepository.updateCash,
      (cashList, c) => cashList
        ..[cashList.indexWhere((c) => c.user.id == cash.user.id)] = cash
            .copyWith(balance: cash.balance + amount),
      cash.copyWith(balance: amount.toDouble()),
    );
  }

  Future<AsyncValue<List<Cash>>> filterCashList(String filter) async {
    return state.when(
      data: (cashList) async {
        final lowerQuery = filter.toLowerCase();
        return state = AsyncData(
          cashList
              .where(
                (cash) =>
                    cash.user.name.toLowerCase().contains(lowerQuery) ||
                    cash.user.firstname.toLowerCase().contains(lowerQuery) ||
                    (cash.user.nickname != null &&
                        cash.user.nickname!.toLowerCase().contains(lowerQuery)),
              )
              .toList(),
        );
      },
      error: (error, stackTrace) {
        if (error is AppException && error.type == ErrorType.tokenExpire) {
          throw error;
        } else {
          return state;
        }
      },
      loading: () {
        return state;
      },
    );
  }

  Future<void> refreshCashList() async {
    state = _cashList;
  }
}

final cashProvider = NotifierProvider<CashProvider, AsyncValue<List<Cash>>>(
  () => CashProvider(),
);
