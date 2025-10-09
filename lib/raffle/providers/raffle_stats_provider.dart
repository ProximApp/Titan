import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titan/auth/providers/openid_provider.dart';
import 'package:titan/raffle/class/raffle.dart';
import 'package:titan/raffle/class/stats.dart';
import 'package:titan/raffle/providers/raffle_id_provider.dart';
import 'package:titan/raffle/repositories/raffle_detail_repository.dart';
import 'package:titan/tools/providers/single_notifier.dart';

class RaffleStatsNotifier extends SingleNotifier<RaffleStats> {
  final RaffleDetailRepository _raffleDetailRepository =
      RaffleDetailRepository();
  late String raffleId;

  @override
  AsyncValue<RaffleStats> build() {
    final token = ref.watch(tokenProvider);
    _raffleDetailRepository.setToken(token);
    final currentRaffleId = ref.watch(raffleIdProvider);
    if (currentRaffleId != Raffle.empty().id) {
      setRaffleId(currentRaffleId);
      loadRaffleStats();
    }
    return const AsyncValue.loading();
  }

  void setRaffleId(String raffleId) {
    this.raffleId = raffleId;
  }

  Future<AsyncValue<RaffleStats>> loadRaffleStats({
    String? customRaffleId,
  }) async {
    return await load(
      () async =>
          _raffleDetailRepository.getRaffleStats(customRaffleId ?? raffleId),
    );
  }
}

final raffleStatsProvider =
    NotifierProvider<RaffleStatsNotifier, AsyncValue<RaffleStats>>(
      RaffleStatsNotifier.new,
    );
