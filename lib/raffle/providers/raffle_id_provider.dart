import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan/raffle/providers/raffle_list_provider.dart';

final raffleIdProvider = NotifierProvider<RaffleIdProvider, String>(
  RaffleIdProvider.new,
);

class RaffleIdProvider extends Notifier<String> {
  @override
  String build() {
    final raffles = ref.watch(raffleListProvider);
    // An empty list has no first raffle: `data.first` threw `Bad state: No
    // element` on a fresh account, before the first raffle ever loaded.
    return raffles.maybeWhen(
      data: (data) => data.isEmpty ? "" : data.first.id,
      orElse: () => "",
    );
  }

  void setId(String i) {
    state = i;
  }
}
