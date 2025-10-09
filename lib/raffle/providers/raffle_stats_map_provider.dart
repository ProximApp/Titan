import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/class/stats.dart';
import 'package:titan/tools/providers/map_provider.dart';

class RaffleStatsMapNotifier extends MapNotifier<String, RaffleStats> {}

final raffleStatsMapProvider =
    NotifierProvider<
      RaffleStatsMapNotifier,
      Map<String, AsyncValue<List<RaffleStats>>?>
    >(() => RaffleStatsMapNotifier());
