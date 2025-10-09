import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/prize.dart';
import 'package:titan/raffle/class/raffle.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/repositories/prize_repository.dart';
import 'package:titan/tools/providers/list_notifier.dart';
import 'package:titan/tools/token_expire_wrapper.dart';

class LotListNotifier extends ListNotifier<Prize> {
  LotRepository get lotRepository => ref.watch(lotRepositoryProvider);
  late String raffleId;

  @override
  AsyncValue<List<Prize>> build() {
    tokenExpireWrapperAuth(ref, () async {
      final raffleIdValue = ref.watch(raffleIdProvider);
      if (raffleIdValue != Raffle.empty().id) {
        setRaffleId(raffleIdValue);
        loadPrizeList();
      }
    });

    return const AsyncValue.loading();
  }

  void setRaffleId(String id) {
    raffleId = id;
  }

  Future<AsyncValue<List<Prize>>> loadPrizeList() async {
    return await loadList(() async => lotRepository.getLotList(raffleId));
  }

  Future<bool> addPrize(Prize lot) async {
    return await add(lotRepository.createLot, lot);
  }

  Future<bool> deletePrize(Prize lot) async {
    return await delete(
      lotRepository.deleteLot,
      (lot, t) => lot..removeWhere((e) => e.id == t.id),
      lot.id,
      lot,
    );
  }

  Future<bool> updatePrize(Prize lot) async {
    return await update(
      lotRepository.updateLot,
      (lot, t) => lot..[lot.indexWhere((e) => e.id == t.id)] = t,
      lot,
    );
  }

  Future<bool> setPrizeQuantityToZero(Prize lot) async {
    return await update(
      (_) async => true,
      (lot, t) => lot..[lot.indexWhere((e) => e.id == t.id)] = t,
      lot,
    );
  }
}

final prizeListProvider =
    NotifierProvider<LotListNotifier, AsyncValue<List<Prize>>>(
      LotListNotifier.new,
    );
